#!/usr/bin/env bash
# pota.sh — cancella le memorie che una pull request di rifletti, ormai unita,
# ha reso inutili, e toglie le loro righe dal MEMORY.md accanto.
#
# Adattato da .claude/skills/reflect/scripts/prune.sh di palazzem/claude-config
# (https://github.com/palazzem/claude-config, licenza Apache 2.0, copia in
# LICENSES/Apache-2.0.txt). Modifiche: nomi dei campi e messaggi in italiano;
# rifiuta anche le righe con barra finale o spazi all'inizio o alla fine, che
# altrimenti risulterebbero "già assenti".
#
# Uso:
#   pota.sh [--prova] < manifesto
# Il manifesto ha un percorso per riga, <progetto>/memory/<file>.md relativo
# alla radice oppure assoluto dentro di essa; le righe vuote non contano.
# Radice: RIFLETTI_RADICE, se no $HOME/.claude/projects.
#
# Ogni riga si controlla prima di toccare qualsiasi cosa: dentro la radice,
# esattamente <progetto>/memory/<file>.md, mai MEMORY.md, nessuna parte vuota,
# "." o "..", niente barra finale né spazi all'inizio o alla fine. Una riga
# sbagliata ferma tutto: ogni riga rifiutata va su stderr e non si cancella
# nulla. --prova fa lo stesso giro senza scrivere.
#
# Uscita — un oggetto JSON su stdout:
#   {"cancellati":[…],"saltati":[…],"righe_indice_tolte":n,"prova":bool}
#   cancellati  percorsi relativi alla radice tolti (con --prova: da togliere)
#   saltati     percorsi già assenti; le loro righe dell'indice si tolgono comunque
# Gli avvisi vanno su stderr.
#
# Codici di uscita: 0 fatto; 1 radice mancante; 2 manifesto o chiamata
# sbagliati, niente cancellato.

set -euo pipefail

uso() { echo "uso: pota.sh [--prova] < manifesto" >&2; }

PROVA=false
case "$#" in
  0) ;;
  1) if [ "$1" = "--prova" ]; then PROVA=true; else uso; exit 2; fi ;;
  *) uso; exit 2 ;;
esac

RADICE="${RIFLETTI_RADICE:-$HOME/.claude/projects}"
if [ ! -d "$RADICE" ]; then
  echo "pota: radice delle memorie non trovata: $RADICE" >&2
  exit 1
fi
RADICE="$(cd "$RADICE" && pwd -P)"

TEMP=""
trap '[ -n "$TEMP" ] && rm -f -- "$TEMP"' EXIT

voci=()
errori=0
rifiuta() { echo "pota: $1: $2" >&2; errori=1; }
while IFS= read -r riga || [ -n "$riga" ]; do
  riga="${riga%$'\r'}"
  case "$riga" in
    *[![:space:]]*) ;;
    *) continue ;;
  esac

  case "$riga" in
    [[:space:]]*|*[[:space:]]) rifiuta "spazi all'inizio o alla fine" "$riga"; continue ;;
    */) rifiuta "barra finale" "$riga"; continue ;;
  esac

  rel="$riga"
  case "$rel" in
    "$RADICE"/*) rel="${rel#"$RADICE"/}" ;;
    /*) rifiuta "fuori dalla radice" "$riga"; continue ;;
  esac

  IFS=/ read -r progetto mezzo file resto <<EOF
$rel
EOF
  if [ -z "$progetto" ] || [ -z "$file" ] || [ -n "${resto:-}" ] || [ "$mezzo" != "memory" ]; then
    rifiuta "non è <progetto>/memory/<file>.md" "$riga"; continue
  fi
  case "$progetto" in .|..) rifiuta "parte non valida" "$riga"; continue ;; esac
  case "$file" in .|..) rifiuta "parte non valida" "$riga"; continue ;; esac
  case "$file" in *.md) ;; *) rifiuta "non è un file .md" "$riga"; continue ;; esac
  if [ "$file" = "MEMORY.md" ]; then
    rifiuta "l'indice non si cancella mai" "$riga"; continue
  fi
  voci+=("$rel")
done

if [ "$errori" -ne 0 ]; then
  echo "pota: manifesto non valido — niente cancellato" >&2
  exit 2
fi
if [ "${#voci[@]}" -eq 0 ]; then
  echo "pota: manifesto vuoto — niente da fare" >&2
  exit 2
fi

cancellati='[]'
saltati='[]'
tolte=0
for rel in "${voci[@]}"; do
  ass="$RADICE/$rel"
  base="${rel##*/}"
  indice="${ass%/*}/MEMORY.md"

  if [ -f "$ass" ]; then
    if [ "$PROVA" = false ]; then rm -- "$ass"; fi
    cancellati="$(jq -c --arg p "$rel" '. + [$p]' <<<"$cancellati")"
  else
    saltati="$(jq -c --arg p "$rel" '. + [$p]' <<<"$saltati")"
  fi

  if [ -f "$indice" ]; then
    n="$(awk -v cerca="](${base})" 'index($0, cerca) { c++ } END { print c + 0 }' "$indice")"
    if [ "$n" -gt 0 ] && [ "$PROVA" = false ]; then
      TEMP="$(mktemp "${indice}.XXXXXX")"
      awk -v cerca="](${base})" 'index($0, cerca) == 0' "$indice" >"$TEMP"
      mv -- "$TEMP" "$indice"
      TEMP=""
    fi
    tolte=$((tolte + n))
  fi
done

jq -nc --argjson cancellati "$cancellati" --argjson saltati "$saltati" \
  --argjson n "$tolte" --argjson prova "$PROVA" \
  '{cancellati: $cancellati, saltati: $saltati, righe_indice_tolte: $n, prova: $prova}'
