#!/usr/bin/env bash
# prova.sh — prove di inventario.sh, pota.sh e fughe.sh. Ogni prova prepara
# una cartella di memorie finta (e, per fughe.sh, un repo git finto), con nomi
# inventati, lancia lo script e confronta le righe stampate e il codice di uscita con quelli attesi.
#
# Uso: prova.sh — stampa "ok" o "NO" per ogni prova, con le differenze;
# esce con 1 se almeno una prova fallisce. Servono bash, jq e git.
set -uo pipefail

QUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTARIO="$QUI/../inventario.sh"
POTA="$QUI/../pota.sh"
FUGHE="$QUI/../fughe.sh"
CARTELLA=$(mktemp -d)
trap 'rm -rf "$CARTELLA"' EXIT
RADICE="$CARTELLA/projects"
export RIFLETTI_RADICE="$RADICE"
fallite=0

prova() {
  local nome=$1 codice_atteso=$2 atteso=$3 ottenuto codice
  shift 3
  ottenuto=$("$@" 2>/dev/null)
  codice=$?
  if [[ "$codice" == "$codice_atteso" && "$ottenuto" == "$atteso" ]]; then
    echo "ok   $nome"
  else
    echo "NO   $nome"
    echo "     codice di uscita atteso $codice_atteso, ottenuto $codice"
    diff <(printf '%s\n' "$atteso") <(printf '%s\n' "$ottenuto") | sed 's/^/     /'
    fallite=$((fallite + 1))
  fi
}

ripulisci() {
  rm -rf "$RADICE" "$CARTELLA/repo"
  mkdir -p "$RADICE"
}

# memoria <slug> <file> <tipo> [corpo]: una memoria nel formato di Claude Code,
# con type e modified sotto metadata: e una riga node_type che non è il tipo.
memoria() {
  mkdir -p "$RADICE/$1/memory"
  cat >"$RADICE/$1/memory/$2" <<EOF
---
name: ${2%.md}
description: "Descrizione di ${2%.md}: con \"virgolette\""
metadata:
  node_type: memory
  type: $3
  modified: 2026-10-09T10:00:00.000Z
---

${4:-Corpo di ${2%.md}.}
EOF
}

# indice <slug> <riga>...: il MEMORY.md del progetto, una riga per argomento.
indice() {
  local slug=$1
  shift
  printf '%s\n' "$@" >"$RADICE/$slug/memory/MEMORY.md"
}

# sessione <slug> <riga>...: un trascritto finto del progetto, una riga per argomento.
sessione() {
  local slug=$1
  shift
  printf '%s\n' "$@" >"$RADICE/$slug/sessione.jsonl"
}

campi() {
  "$INVENTARIO" | jq -c '[.progetto, (.cartella_progetto | sub(".*/"; "")), .nome_progetto, (.file | sub(".*/"; "")), .nome, .descrizione, .tipo, .modificato, .corpo]'
}

# rifiutata <riga> <motivo>: pota.sh rifiuta il manifesto di quella sola riga,
# con codice 2, niente su stdout e "pota: <motivo>: <riga>" su stderr.
rifiutata() {
  local riga=$1 motivo=$2 uscita errori codice
  errori=$("$POTA" --prova <<<"$riga" 2>&1 >/dev/null)
  codice=$?
  uscita=$("$POTA" --prova <<<"$riga" 2>/dev/null)
  if [[ "$codice" == 2 && -z "$uscita" && "$errori" == *"pota: $motivo: $riga"* ]]; then
    echo "ok   pota rifiuta [$riga]: $motivo"
  else
    echo "NO   pota rifiuta [$riga]: $motivo"
    echo "     codice $codice, uscita [$uscita], errori [$errori]"
    fallite=$((fallite + 1))
  fi
}

# --- inventario.sh

ripulisci
memoria -home-b lingua.md feedback
memoria -home-a progetto.md project "Riga uno.
Riga due."
indice -home-a '- [Progetto](progetto.md) — gancio'
sessione -home-a '{"type":"inizio"}' 'non è json' '{"type":"user","cwd":"/home/x/Progetto-Uno"}'
prova "inventario: una riga per memoria, in ordine di progetto, senza MEMORY.md" 0 \
'["-home-a","-home-a","Progetto-Uno","progetto.md","progetto","Descrizione di progetto: con \"virgolette\"","project","2026-10-09T10:00:00.000Z","Riga uno.\nRiga due."]
["-home-b","-home-b","","lingua.md","lingua","Descrizione di lingua: con \"virgolette\"","feedback","2026-10-09T10:00:00.000Z","Corpo di lingua."]' \
  campi

ripulisci
mkdir -p "$RADICE/-home-a/memory"
printf 'Solo testo, niente intestazione.\n' >"$RADICE/-home-a/memory/nuda.md"
prova "inventario: senza intestazione il tipo è sconosciuto e il nome è il file" 0 \
  '["-home-a","-home-a","","nuda.md","nuda","","sconosciuto","","Solo testo, niente intestazione."]' \
  campi

ripulisci
mkdir -p "$RADICE/-home-a/memory"
printf -- '---\nname: aperta\nTesto senza chiusura.\n' >"$RADICE/-home-a/memory/aperta.md"
prova "inventario: intestazione senza chiusura, tutto il file è il corpo" 0 \
  '["-home-a","-home-a","","aperta.md","aperta","","sconosciuto","","---\nname: aperta\nTesto senza chiusura."]' \
  campi

ripulisci
mkdir -p "$RADICE/-home-vuoto/memory" "$RADICE/-home-senza"
prova "inventario: progetti senza memorie non stampano nulla" 0 "" campi

prova "inventario: un argomento è un errore di chiamata" 2 "" "$INVENTARIO" qualcosa
prova "inventario: radice mancante" 1 "" env RIFLETTI_RADICE="$CARTELLA/manca" "$INVENTARIO"

# --- pota.sh

ripulisci
memoria -home-a uno.md feedback
memoria -home-a due.md project
indice -home-a '- [Uno](uno.md) — primo' '- [Due](due.md) — secondo'
prova "pota --prova: dice cosa cancellerebbe e non tocca nulla" 0 \
  '{"cancellati":["-home-a/memory/uno.md"],"saltati":[],"righe_indice_tolte":1,"prova":true}' \
  "$POTA" --prova <<<"-home-a/memory/uno.md"
prova "pota --prova: il file e l'indice sono ancora lì" 0 "2 2" \
  bash -c "echo \$(ls '$RADICE/-home-a/memory' | grep -vc MEMORY) \$(wc -l <'$RADICE/-home-a/memory/MEMORY.md')"

prova "pota: cancella il file e la sua riga dell'indice, percorso assoluto accettato" 0 \
  '{"cancellati":["-home-a/memory/uno.md"],"saltati":[],"righe_indice_tolte":1,"prova":false}' \
  "$POTA" <<<"$RADICE/-home-a/memory/uno.md"
prova "pota: resta solo l'altra memoria, con la sua riga" 0 "due.md
- [Due](due.md) — secondo" \
  bash -c "ls '$RADICE/-home-a/memory' | grep -v MEMORY; cat '$RADICE/-home-a/memory/MEMORY.md'"
prova "pota: di nuovo sullo stesso manifesto, il file è saltato" 0 \
  '{"cancellati":[],"saltati":["-home-a/memory/uno.md"],"righe_indice_tolte":0,"prova":false}' \
  "$POTA" <<<"-home-a/memory/uno.md"

ripulisci
memoria -home-a uno.md feedback
rifiutata "-home-a/memory/MEMORY.md" "l'indice non si cancella mai"
rifiutata "/etc/passwd" "fuori dalla radice"
rifiutata "-home-a/altro/uno.md" "non è <progetto>/memory/<file>.md"
rifiutata "-home-a/memory/sotto/uno.md" "non è <progetto>/memory/<file>.md"
rifiutata "../memory/uno.md" "parte non valida"
rifiutata "-home-a/memory/.." "parte non valida"
rifiutata "-home-a/memory/uno.txt" "non è un file .md"
rifiutata "-home-a/memory/uno.md/" "barra finale"
rifiutata " -home-a/memory/uno.md" "spazi all'inizio o alla fine"
rifiutata "-home-a/memory/uno.md " "spazi all'inizio o alla fine"
prova "pota: una riga non valida blocca anche le righe buone" 2 "" \
  "$POTA" <<<"-home-a/memory/uno.md
-home-a/memory/uno.txt"
prova "pota: dopo il rifiuto la memoria c'è ancora" 0 "uno.md" ls "$RADICE/-home-a/memory"
prova "pota: manifesto vuoto" 2 "" "$POTA" <<<"

"
prova "pota: opzione sconosciuta" 2 "" "$POTA" --forza </dev/null

# --- fughe.sh

ripulisci
REPO="$CARTELLA/repo"
git init -q -b main "$REPO"
printf 'Contesto memoria-esempio.\n' >"$REPO/CLAUDE.md"
git -C "$REPO" add CLAUDE.md
git -C "$REPO" -c user.name=p -c user.email=p@p commit -q -m "Inizio"
printf '%s\n' "Progetto-Uno" "" "memoria-esempio" >"$CARTELLA/parole"
printf 'Regola: rispondi in italiano.\n' >>"$REPO/CLAUDE.md"
git -C "$REPO" add CLAUDE.md
git -C "$REPO" -c user.name=p -c user.email=p@p commit -q -m "Regola sulla lingua"
printf '## Regole aggiunte\n\nNessun nome, ma sottomemoria-esempio.\n' >"$CARTELLA/corpo.md"
prova "fughe: pulito; righe di contesto e parole dentro altre parole non contano" 0 "" \
  bash -c "cd '$REPO' && '$FUGHE' '$CARTELLA/parole' main~1 '$CARTELLA/corpo.md'"

git -C "$REPO" -c user.name=p -c user.email=p@p commit -q --allow-empty -m "Da progetto-uno"
printf 'Vedi MEMORIA-ESEMPIO.\n' >>"$CARTELLA/corpo.md"
prova "fughe: un progetto in un messaggio e una memoria nel corpo, senza badare alle maiuscole" 1 \
  "fuga: Progetto-Uno nei commit
fuga: memoria-esempio in $CARTELLA/corpo.md" \
  bash -c "cd '$REPO' && '$FUGHE' '$CARTELLA/parole' main~2 '$CARTELLA/corpo.md'"

printf 'Sempre in Progetto-Uno.\n' >>"$REPO/CLAUDE.md"
git -C "$REPO" add CLAUDE.md
git -C "$REPO" -c user.name=p -c user.email=p@p commit -q -m "Altra regola"
prova "fughe: un progetto in una riga aggiunta" 1 "fuga: Progetto-Uno nei commit" \
  bash -c "cd '$REPO' && '$FUGHE' '$CARTELLA/parole' main~1"

prova "fughe: elenco di parole mancante" 2 "" \
  bash -c "cd '$REPO' && '$FUGHE' '$CARTELLA/manca' main~1"
printf '\n \n' >"$CARTELLA/vuote"
prova "fughe: elenco di parole vuoto" 2 "" \
  bash -c "cd '$REPO' && '$FUGHE' '$CARTELLA/vuote' main~1"
prova "fughe: base inesistente" 2 "" \
  bash -c "cd '$REPO' && '$FUGHE' '$CARTELLA/parole' nessuna"

echo
if [ "$fallite" -gt 0 ]; then
  echo "$fallite prove fallite"
  exit 1
fi
echo "tutte le prove passano"
