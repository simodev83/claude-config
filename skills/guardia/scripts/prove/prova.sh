#!/usr/bin/env bash
# prova.sh — prove di guarda-pr.sh. Lancia lo script con il gh finto di bin/,
# che risponde con le PR scritte da ogni prova, e confronta le righe stampate e
# il codice di uscita con quelli attesi.
#
# Uso: prova.sh — stampa "ok" o "NO" per ogni prova, con le differenze;
# esce con 1 se almeno una prova fallisce. Servono bash, jq e timeout.
set -uo pipefail

QUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARDA="$QUI/../guarda-pr.sh"
CARTELLA=$(mktemp -d)
trap 'rm -rf "$CARTELLA"' EXIT
export PATH="$QUI/bin:$PATH" PROVA_PR="$CARTELLA" GUARDIA_INTERVALLO=0 GUARDIA_DURATA=0
fallite=0

E='1970-01-01T00:00:00Z'

NODI='
def commento($u; $t; $b; $r): { url: $u, updatedAt: $t, body: $b, authorAssociation: $r, author: { login: "revisore" } };
def revisione($u; $t; $b; $s): commento($u; $t; $b; "OWNER") + { state: $s };
def nel_thread($u; $t; $b; $s): commento($u; $t; $b; "OWNER") + { pullRequestReview: { state: $s } };
def controllo($c): { __typename: "CheckRun", status: "COMPLETED", conclusion: $c };
def ci($nodi): .commits.nodes[0].commit.statusCheckRollup = { contexts: { nodes: $nodi } };
def pila($voci): .stack = { entries: { nodes: [ $voci[] | { position: .[0], pullRequest: { number: .[1], state: .[2] } } ] } };
'

pr() {
  jq -n -c --argjson n "$1" --arg m '<!-- claude -->' "$NODI"'
    { number: $n, state: "OPEN", mergeStateStatus: "CLEAN", stack: null,
      comments: { nodes: [] }, reviews: { nodes: [] }, reviewThreads: { nodes: [] },
      commits: { nodes: [ { commit: { oid: "aaa", statusCheckRollup: null } } ] } }
    | '"${2:-.}" >"$CARTELLA/$1.json"
}

segno() {
  printf '{"commento":"%s","revisione":"%s","risposta":"%s","merge":"%s","ci":"%s","testa":"%s"}' "$@"
}

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
  rm -f "$CARTELLA"/*.json "$CARTELLA/.chiamate"
}

S_VUOTA=$(segno "$E" "$E" "$E" CLEAN NESSUNA aaa)

pr 5
prova "inizio: una PR senza attività stampa solo il segnalibro" 0 \
  "{\"5\":$S_VUOTA}" \
  "$GUARDA" inizio 5

ATTIVITA='.mergeStateStatus = "DIRTY"
  | ci([controllo("SUCCESS"), controllo("FAILURE")])
  | .comments.nodes = [
      commento("u/c1"; "2026-01-01T10:00:00Z"; "Cambia il nome"; "OWNER"),
      commento("u/c2"; "2026-01-01T11:00:00Z"; ($m + "\nFatto\n— Claude"); "OWNER"),
      commento("u/c3"; "2026-01-01T12:00:00Z"; ("﻿  \n" + $m + "\nok"); "OWNER") ]
  | .reviews.nodes = [
      revisione("u/r1"; "2026-01-01T10:30:00Z"; ""; "COMMENTED"),
      revisione("u/r2"; "2026-01-01T10:40:00Z"; ""; "APPROVED"),
      revisione("u/r3"; "2026-01-01T10:45:00Z"; ($m + "\nRevisione automatica"); "COMMENTED"),
      revisione("u/r4"; "2026-01-01T10:50:00Z"; "Manca un test"; "CHANGES_REQUESTED") ]
  | .reviewThreads.nodes = [ { comments: { nodes: [
      nel_thread("u/t1"; "2026-01-01T09:00:00Z"; "Bozza"; "PENDING"),
      nel_thread("u/t2"; "2026-01-01T09:10:00Z"; "Perché qui?"; "COMMENTED"),
      nel_thread("u/t3"; "2026-01-01T09:20:00Z"; ($m + "\nPerché serve"); "COMMENTED") ] } } ]'
S_ATTIVITA=$(segno 2026-01-01T12:00:00Z 2026-01-01T10:50:00Z 2026-01-01T09:20:00Z DIRTY FALLITA aaa)

pr 5 "$ATTIVITA"
prova "inizio: stampa conflitto, CI e attività non marcate, nell'ordine" 0 \
  '{"evento":"CONFLITTO","pr":5}
{"evento":"CI_FALLITA","pr":5}
{"evento":"COMMENTO","pr":5,"url":"u/c1","login":"revisore","ruolo":"OWNER","quando":"2026-01-01T10:00:00Z"}
{"evento":"REVISIONE","pr":5,"url":"u/r2","login":"revisore","ruolo":"OWNER","quando":"2026-01-01T10:40:00Z","esito":"APPROVED"}
{"evento":"REVISIONE","pr":5,"url":"u/r4","login":"revisore","ruolo":"OWNER","quando":"2026-01-01T10:50:00Z","esito":"CHANGES_REQUESTED"}
{"evento":"RISPOSTA","pr":5,"url":"u/t2","login":"revisore","ruolo":"OWNER","quando":"2026-01-01T09:10:00Z"}'"
{\"5\":$S_ATTIVITA}" \
  "$GUARDA" inizio 5

pr 5 "$ATTIVITA"
prova "attesa: niente di nuovo, alla scadenza stampa solo il segnalibro" 0 \
  "{\"5\":$S_ATTIVITA}" \
  "$GUARDA" attesa "{\"5\":$S_ATTIVITA}"

pr 5 "$ATTIVITA"
prova "attesa: senza eventi non stampa nulla prima della scadenza" 124 \
  "" \
  timeout 2 env GUARDIA_DURATA=100 GUARDIA_INTERVALLO=1 "$GUARDA" attesa "{\"5\":$S_ATTIVITA}"

pr 5 "$ATTIVITA"' | .commits.nodes[0].commit.oid = "bbb"'
prova "attesa: la CI fallita su un nuovo commit in cima sveglia di nuovo" 0 \
  '{"evento":"CI_FALLITA","pr":5}'"
{\"5\":$(segno 2026-01-01T12:00:00Z 2026-01-01T10:50:00Z 2026-01-01T09:20:00Z DIRTY FALLITA bbb)}" \
  "$GUARDA" attesa "{\"5\":$S_ATTIVITA}"

pr 5 "$ATTIVITA"' | .comments.nodes[0].updatedAt = "2026-01-02T08:00:00Z"'
prova "attesa: un commento modificato sveglia di nuovo" 0 \
  '{"evento":"COMMENTO","pr":5,"url":"u/c1","login":"revisore","ruolo":"OWNER","quando":"2026-01-02T08:00:00Z"}'"
{\"5\":$(segno 2026-01-02T08:00:00Z 2026-01-01T10:50:00Z 2026-01-01T09:20:00Z DIRTY FALLITA aaa)}" \
  "$GUARDA" attesa "{\"5\":$S_ATTIVITA}"

pr 5 '.state = "MERGED"'
prova "attesa: una PR unita stampa UNITA e il segnalibro vuoto" 0 \
  '{"evento":"UNITA","pr":5}
{}' \
  "$GUARDA" attesa "{\"5\":$S_VUOTA}"

pr 5 '.state = "CLOSED" | .mergeStateStatus = "DIRTY"'
prova "attesa: una PR chiusa stampa solo CHIUSA" 0 \
  '{"evento":"CHIUSA","pr":5}
{}' \
  "$GUARDA" attesa "{\"5\":$S_VUOTA}"

PILA='pila([[1, 4, "MERGED"], [2, 5, "OPEN"], [3, 6, "OPEN"]])'
pr 5 "$PILA"' | .mergeStateStatus = "DIRTY"'
pr 6 "$PILA"' | .comments.nodes = [commento("u/c6"; "2026-01-01T10:00:00Z"; "Nome?"; "MEMBER")]'
prova "inizio: in una pila trova gli altri strati aperti e li ordina dal basso" 0 \
  '{"evento":"CONFLITTO","pr":5}
{"evento":"COMMENTO","pr":6,"url":"u/c6","login":"revisore","ruolo":"MEMBER","quando":"2026-01-01T10:00:00Z"}'"
{\"5\":$(segno "$E" "$E" "$E" DIRTY NESSUNA aaa),\"6\":$(segno 2026-01-01T10:00:00Z "$E" "$E" CLEAN NESSUNA aaa)}" \
  "$GUARDA" inizio 6

pr 5 "$PILA"' | .mergeStateStatus = "DIRTY"'
pr 6 "$PILA"' | .comments.nodes = [commento("u/c6"; "2026-01-01T10:00:00Z"; "Nome?"; "MEMBER")]'
prova "attesa: uno strato entrato nella pila durante l'attesa si legge dall'inizio" 0 \
  '{"evento":"COMMENTO","pr":6,"url":"u/c6","login":"revisore","ruolo":"MEMBER","quando":"2026-01-01T10:00:00Z"}'"
{\"5\":$(segno "$E" "$E" "$E" DIRTY NESSUNA aaa),\"6\":$(segno 2026-01-01T10:00:00Z "$E" "$E" CLEAN NESSUNA aaa)}" \
  "$GUARDA" attesa "{\"5\":$(segno "$E" "$E" "$E" DIRTY NESSUNA aaa)}"

pr 5
pr 6
prova "inizio: più PR fuori da una pila di GitHub si sorvegliano insieme" 0 \
  "{\"5\":$S_VUOTA,\"6\":$S_VUOTA}" \
  "$GUARDA" inizio 5 6

pr 5 "$PILA"' | .state = "MERGED"'
pr 6 "$PILA"
prova "attesa: lo strato basso unito esce dal segnalibro, quello sopra resta" 0 \
  '{"evento":"UNITA","pr":5}'"
{\"6\":$S_VUOTA}" \
  "$GUARDA" attesa "{\"5\":$S_VUOTA,\"6\":$S_VUOTA}"

S_INDIETRO=$(segno "$E" "$E" "$E" BEHIND NESSUNA aaa)
pr 5 '.mergeStateStatus = "BEHIND"'
prova "attesa: INDIETRO quando GitHub blocca il merge del ramo non aggiornato" 0 \
  '{"evento":"INDIETRO","pr":5}'"
{\"5\":$S_INDIETRO}" \
  "$GUARDA" attesa "{\"5\":$S_VUOTA}"

pr 5 '.mergeStateStatus = "BEHIND"'
prova "attesa: INDIETRO già visto non sveglia di nuovo" 0 \
  "{\"5\":$S_INDIETRO}" \
  "$GUARDA" attesa "{\"5\":$S_INDIETRO}"

pr 5 'ci([controllo("SUCCESS"), { __typename: "StatusContext", state: "PENDING" }])'
prova "inizio: la CI in corso non sveglia" 0 \
  "{\"5\":$(segno "$E" "$E" "$E" CLEAN IN_CORSO aaa)}" \
  "$GUARDA" inizio 5

pr 5 'ci([controllo("SUCCESS"), { __typename: "StatusContext", state: "ERROR" }, controllo("CANCELLED")])'
prova "inizio: un controllo in errore o annullato è CI fallita" 0 \
  '{"evento":"CI_FALLITA","pr":5}'"
{\"5\":$(segno "$E" "$E" "$E" CLEAN FALLITA aaa)}" \
  "$GUARDA" inizio 5

pr 5 '.mergeStateStatus = "UNKNOWN"'
prova "attesa: lo stato del merge UNKNOWN non sveglia" 0 \
  "{\"5\":$(segno "$E" "$E" "$E" UNKNOWN NESSUNA aaa)}" \
  "$GUARDA" attesa "{\"5\":$S_VUOTA}"

pr 5 '.mergeStateStatus = "BLOCKED" | ci([controllo("SUCCESS")])'
prova "attesa: alla scadenza il segnalibro riporta i cambi che non svegliano" 0 \
  "{\"5\":$(segno "$E" "$E" "$E" BLOCKED OK aaa)}" \
  "$GUARDA" attesa "{\"5\":$S_VUOTA}"

pr 5 'ci([controllo("FAILURE")])'
prova "attesa: la CI che fallisce dopo essere stata in corso sveglia" 0 \
  '{"evento":"CI_FALLITA","pr":5}'"
{\"5\":$(segno "$E" "$E" "$E" CLEAN FALLITA aaa)}" \
  "$GUARDA" attesa "{\"5\":$(segno "$E" "$E" "$E" CLEAN IN_CORSO aaa)}"

pr 5
prova "attesa: una lettura riuscita azzera il conto degli errori" 124 \
  "" \
  timeout 3 env GUARDIA_DURATA=100 GUARDIA_MAX_ERRORI=2 PROVA_FALLISCE="1 3 5" "$GUARDA" attesa "{\"5\":$S_VUOTA}"

prova "uso: il numero della PR deve essere un numero" 2 "" "$GUARDA" inizio abc
prova "uso: ogni numero di PR deve essere un numero" 2 "" "$GUARDA" inizio 5 abc
prova "uso: attesa vuole un solo segnalibro" 2 "" "$GUARDA" attesa "{\"5\":$S_VUOTA}" altro
prova "uso: servono due argomenti" 2 "" "$GUARDA" inizio
prova "uso: comando sconosciuto" 2 "" "$GUARDA" guarda 5
prova "uso: il segnalibro vuoto non si arma" 2 "" "$GUARDA" attesa '{}'
prova "uso: segnalibro che non è JSON" 2 "" "$GUARDA" attesa 'segnalibro'
prova "uso: segnalibro senza tutti i campi" 2 "" "$GUARDA" attesa '{"5":{"commento":"x"}}'
prova "uso: le impostazioni devono essere numeri interi" 2 "" env GUARDIA_INTERVALLO=mezzo "$GUARDA" inizio 5

prova "inizio: una lettura fallita esce con 1" 1 "" env PROVA_ERRORE=1 "$GUARDA" inizio 5
prova "inizio: una PR che GitHub non trova esce con 1" 1 "" "$GUARDA" inizio 7
prova "attesa: troppe letture fallite di fila esce con 1" 1 "" \
  env PROVA_ERRORE=1 GUARDIA_MAX_ERRORI=2 GUARDIA_DURATA=100 "$GUARDA" attesa "{\"5\":$S_VUOTA}"
prova "attesa: letture fallite fino alla scadenza escono con 1" 1 "" \
  timeout 5 env PROVA_ERRORE=1 GUARDIA_MAX_ERRORI=1000000 "$GUARDA" attesa "{\"5\":$S_VUOTA}"

if (( fallite > 0 )); then
  echo "$fallite prove fallite"
  exit 1
fi
echo "tutte le prove passano"
