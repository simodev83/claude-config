#!/usr/bin/env bash
# fughe.sh — il controllo delle fughe della skill rifletti: nessuna parola
# dell'elenco (nomi dei progetti, nomi e file delle memorie) deve finire nei
# commit del ramo né nei testi da pubblicare (il corpo della pull request, le
# risposte della guardia). Lo lancia rifletti prima di aprire la pull request,
# e la guardia come comando di test a ogni correzione.
#
# Uso, dentro il repo e sul ramo da controllare:
#   fughe.sh <parole> <base> [file...]
# <parole> ha una parola o frase per riga; le righe vuote non contano. Nei
# commit di <base>..HEAD si controllano i messaggi e solo le righe aggiunte
# (non quelle di contesto, che c'erano già); ogni [file] si controlla per
# intero. Una parola si trova senza badare alle maiuscole e solo intera: dentro
# un'altra parola non conta.
#
# Uscita: una riga "fuga: <parola> nei commit" o "fuga: <parola> in <file>" per
# ogni parola trovata, nell'ordine dell'elenco; niente se è tutto pulito.
#
# Codici di uscita: 0 nessuna fuga; 1 almeno una fuga; 2 chiamata sbagliata,
# elenco mancante o vuoto, base o file inesistenti.

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "uso: fughe.sh <parole> <base> [file...]" >&2
  exit 2
fi
PAROLE=$1
BASE=$2
shift 2

if [ ! -f "$PAROLE" ]; then
  echo "fughe: elenco di parole non trovato: $PAROLE" >&2
  exit 2
fi
if ! git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null; then
  echo "fughe: base non trovata: $BASE" >&2
  exit 2
fi
for f in "$@"; do
  if [ ! -f "$f" ]; then
    echo "fughe: file non trovato: $f" >&2
    exit 2
  fi
done

parole=()
while IFS= read -r riga || [ -n "$riga" ]; do
  riga="${riga%$'\r'}"
  case "$riga" in
    *[![:space:]]*) parole+=("$riga") ;;
  esac
done <"$PAROLE"
if [ "${#parole[@]}" -eq 0 ]; then
  echo "fughe: elenco di parole vuoto: $PAROLE" >&2
  exit 2
fi

COMMIT="$(
  git log --format='%B' "$BASE..HEAD"
  git diff --unified=0 "$BASE" HEAD | grep -e '^+' | grep -v -e '^+++' || true
)"
trovate=0
for p in "${parole[@]}"; do
  if grep -qiwF -e "$p" <<<"$COMMIT"; then
    echo "fuga: $p nei commit"
    trovate=1
  fi
done
for f in "$@"; do
  for p in "${parole[@]}"; do
    if grep -qiwF -e "$p" -- "$f"; then
      echo "fuga: $p in $f"
      trovate=1
    fi
  done
done
exit "$trovate"
