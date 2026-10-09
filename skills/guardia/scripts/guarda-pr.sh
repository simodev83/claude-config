#!/usr/bin/env bash
# guarda-pr.sh — l'unico lettore di GitHub della skill guardia. Sorveglia ogni
# strato aperto della pila a cui appartiene una pull request (una PR fuori da
# una pila è una pila di uno). La prima lettura e il monitor usano lo stesso
# filtro, quindi non possono dare risposte diverse.
#
# Adattato da skills/shepherd/scripts/watch-pr.sh di palazzem/claude-config
# (https://github.com/palazzem/claude-config, licenza Apache 2.0, copia in
# LICENSE-apache-2.0.txt). Lo stesso vale per jq/ e domanda.graphql. Modifiche:
# nomi e messaggi in italiano; INDIETRO solo quando GitHub blocca il merge, non
# a ogni spostamento della base; la CI ricorda il commit in cima, così un nuovo
# commit che fallisce sveglia anche se la CI era già fallita; l'attesa si ferma
# da sola dopo GUARDIA_DURATA secondi, perché un monitor dura al massimo 30
# minuti.
#
# Uso:
#   guarda-pr.sh inizio <numero>        una volta per sorveglianza: stampa tutto ciò che
#                                       è in sospeso su ogni strato aperto (ogni commento,
#                                       revisione e risposta non marcati, conflitti, CI,
#                                       o la fine), poi il segnalibro
#   guarda-pr.sh attesa '<segnalibro>'  il monitor: legge GitHub ogni GUARDIA_INTERVALLO
#                                       secondi (30) finché trova eventi oltre il
#                                       segnalibro, li stampa con il nuovo segnalibro ed
#                                       esce; dopo GUARDIA_DURATA secondi (1500) senza
#                                       eventi stampa solo il segnalibro aggiornato ed esce
# <numero> è una qualsiasi PR della pila; il repo è quello della cartella
# corrente (o GH_REPO). Il segnalibro è tutto lo stato della sorveglianza:
# attesa non vuole altro.
#
# Ogni riga su stdout è un oggetto JSON; l'ultima è sempre il segnalibro, le
# altre sono eventi che svegliano la sessione. Ogni evento ha pr, il numero
# della PR su cui è avvenuto:
#   {"evento":"COMMENTO","pr":…,"url":…,"login":…,"ruolo":…,"quando":…}            commento non marcato nella conversazione
#   {"evento":"REVISIONE","pr":…,"url":…,"login":…,"ruolo":…,"quando":…,"esito":…}  revisione inviata non marcata, approvazioni senza testo comprese
#   {"evento":"RISPOSTA","pr":…,"url":…,"login":…,"ruolo":…,"quando":…}            commento non marcato in un thread sul codice
#   {"evento":"UNITA","pr":…} | {"evento":"CHIUSA","pr":…}                          la PR è unita o chiusa; per lei nessun altro evento
#   {"evento":"INDIETRO","pr":…}                                                   GitHub blocca il merge finché il ramo non si aggiorna
#   {"evento":"CONFLITTO","pr":…}                                                  il ramo è in conflitto con la sua base
#   {"evento":"CI_FALLITA","pr":…}                                                 un controllo sul commit in cima è fallito o annullato
#   {"<numero>":{"commento":…,"revisione":…,"risposta":…,"merge":…,"ci":…,"testa":…},…}
#                                       il segnalibro: una voce per PR aperta, con il suo
#                                       numero — l'updatedAt più recente per tipo di
#                                       attività, lo stato del merge, lo stato della CI e il
#                                       commit in cima
# ruolo è l'authorAssociation di GitHub (OWNER, MEMBER, COLLABORATOR, CONTRIBUTOR…).
#
# Gli strati sono le PR nominate dal segnalibro più ogni PR aperta della loro
# pila, come la riporta l'API di GitHub (l'estensione gh-stack non viene mai
# chiamata). Ogni strato si confronta con la sua voce; uno strato senza voce,
# entrato nella pila durante l'attesa, si legge dall'inizio. Uno strato unito o
# chiuso stampa quell'evento una volta ed esce dal segnalibro; gli eventi degli
# altri strati si stampano nella stessa passata. Gli eventi escono raggruppati
# per strato, dal basso della pila; dentro uno strato: la fine da sola, oppure
# conflitto o INDIETRO, poi CI_FALLITA, poi COMMENTO, REVISIONE e RISPOSTA.
# {} è il segnalibro di una sorveglianza finita, e attesa lo rifiuta.
#
# Non svegliano mai: i testi marcati (prima riga <!-- claude -->, spazi iniziali
# ignorati); le revisioni COMMENTED senza testo, perché GitHub avvolge in una di
# queste ogni risposta in un thread data via API; le revisioni in sospeso e i
# loro commenti; lo stato del merge UNKNOWN; i controlli in corso o passati.
# L'attività si confronta sull'updatedAt, quindi un commento modificato sveglia
# di nuovo. inizio legge l'attività dall'inizio e conflitti e CI dallo stato
# attuale; attesa sveglia per l'attività più recente del segnalibro e per
# conflitti e CI diversi da lui, così uno stato già gestito resta zitto finché
# non cambia.
# I messaggi di servizio vanno su stderr.
#
# Una sola richiesta GraphQL per passata legge tutto di tutti gli strati:
# domanda.graphql è la selezione su una PR, come frammento, e lo script le
# costruisce intorno la domanda, con un alias pullRequest per strato. Se la
# pila nomina una PR aperta non letta, la passata rilegge una volta con tutte:
# inizio su una pila fa due richieste, una passata normale una. Segnalibro ed
# eventi vengono dalla stessa risposta, e non si stampa nulla se un alias è null
# o la risposta non si legge, quindi una passata non è mai parziale. Si leggono
# gli ultimi 50 commenti, revisioni e thread (20 commenti ciascuno), 100
# controlli per strato e 100 voci di pila. jq/passata.jq è la passata, sulle
# definizioni di jq/lib.jq; jq/strati.jq dà gli strati nominati dalla risposta,
# quando sono più di quelli letti.
#
# Codici di uscita: 0 stampato (inizio: lettura completa; attesa: eventi o
# scadenza); 1 lettura fallita (inizio) o GUARDIA_MAX_ERRORI (20) letture
# fallite di fila (attesa); 2 errore di chiamata.

set -euo pipefail

QUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARCATORE='<!-- claude -->'
EPOCA='1970-01-01T00:00:00Z'
INTERVALLO="${GUARDIA_INTERVALLO:-30}"
MAX_ERRORI="${GUARDIA_MAX_ERRORI:-20}"
DURATA="${GUARDIA_DURATA:-1500}"

uso() {
  echo "uso: guarda-pr.sh inizio <numero> | attesa '<segnalibro>'" >&2
  exit 2
}

[[ $# -eq 2 ]] || uso
for valore in "$INTERVALLO" "$MAX_ERRORI" "$DURATA"; do
  [[ "$valore" =~ ^[0-9]+$ ]] || {
    echo "guarda-pr: GUARDIA_INTERVALLO, GUARDIA_MAX_ERRORI e GUARDIA_DURATA devono essere numeri interi" >&2
    exit 2
  }
done

domanda() {
  local n letture=""
  for n in "$@"; do
    [[ "$n" =~ ^[0-9]+$ ]] || return 1
    letture+="pr$n: pullRequest(number: $n) { ...pr } "
  done
  printf 'query($owner: String!, $name: String!) { repository(owner: $owner, name: $name) { %s} }\n%s\n' \
    "$letture" "$(cat "$QUI/domanda.graphql")"
}

leggi() {
  local testo
  testo=$(domanda "$@") || return 1
  gh api graphql -F owner='{owner}' -F name='{repo}' -f query="$testo" \
    | jq -e '.data.repository | select(. != null and all(.[]; . != null))'
}

passata() {
  local numeri piu_larga risposta
  read -r -a numeri <<<"$(jq -r 'keys_unsorted | join(" ")' <<<"$ultimo")"
  risposta=$(leggi "${numeri[@]}") || return 1
  piu_larga=$(jq -r -f "$QUI/jq/strati.jq" <<<"$risposta") || return 1
  if [[ -n "$piu_larga" ]]; then
    read -r -a numeri <<<"$piu_larga"
    risposta=$(leggi "${numeri[@]}") || return 1
  fi
  uscita=$(jq -c -L "$QUI/jq" --arg epoca "$EPOCA" --arg marcatore "$MARCATORE" \
    --argjson armato "$armato" --argjson ultimo "$ultimo" -f "$QUI/jq/passata.jq" <<<"$risposta") || return 1
}

case "$1" in
  inizio)
    [[ "$2" =~ ^[1-9][0-9]*$ ]] || { echo "guarda-pr: <numero> deve essere il numero della PR" >&2; exit 2; }
    armato='{}'
    ultimo="{\"$2\":{}}"
    if ! passata; then
      echo "guarda-pr: lettura fallita; rilancialo" >&2
      exit 1
    fi
    printf '%s\n' "$uscita"
    exit 0
    ;;
  attesa)
    jq -es 'length == 1 and (.[0] | type == "object" and length > 0 and all(to_entries[];
      (.key | test("\\A[1-9][0-9]*\\z")) and (.value | type == "object"
        and ([.commento, .revisione, .risposta, .merge, .ci, .testa] | all(type == "string")))))' \
      <<<"$2" >/dev/null 2>&1 || {
      echo "guarda-pr: segnalibro non valido: $2" >&2
      exit 2
    }
    armato=$2
    ultimo=$2
    echo "guarda-pr: segnalibro=$2" >&2
    ;;
  *)
    echo "guarda-pr: comando sconosciuto: $1" >&2
    exit 2
    ;;
esac

errori=0
while :; do
  if passata; then
    errori=0
  else
    errori=$((errori + 1))
    if (( errori >= MAX_ERRORI )); then
      echo "guarda-pr: $errori letture fallite di fila; mi fermo" >&2
      exit 1
    fi
    echo "guarda-pr: lettura incompleta ($errori/$MAX_ERRORI); riprovo" >&2
    sleep "$INTERVALLO"
    continue
  fi
  if [[ "$uscita" == *$'\n'* ]] || (( SECONDS >= DURATA )); then
    printf '%s\n' "$uscita"
    exit 0
  fi
  ultimo=$uscita
  sleep "$INTERVALLO"
done
