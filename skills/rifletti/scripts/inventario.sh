#!/usr/bin/env bash
# inventario.sh — l'unico lettore delle memorie della skill rifletti. Elenca
# ogni memoria di ogni progetto come JSON, un oggetto per file, così la
# classificazione legge un solo flusso invece di decine di file.
#
# Adattato da .claude/skills/reflect/scripts/inventory.sh di palazzem/claude-config
# (https://github.com/palazzem/claude-config, licenza Apache 2.0, copia in
# LICENSES/Apache-2.0.txt). Modifiche: nomi dei campi e messaggi in italiano;
# il campo nome_progetto, per il controllo delle fughe; un'intestazione mai
# chiusa lascia tutto il file come corpo invece di un corpo vuoto.
#
# Uso:
#   inventario.sh          radice: $RIFLETTI_RADICE, se no $HOME/.claude/projects
#
# Uscita — un oggetto JSON per memoria su stdout, per progetto e poi per file:
#   {"progetto":…,"cartella_progetto":…,"nome_progetto":…,"file":…,"nome":…,"descrizione":…,"tipo":…,"modificato":…,"corpo":…}
#   progetto           nome della cartella del progetto sotto la radice (il
#                      percorso del progetto con / e . scritti come -)
#   cartella_progetto  percorso assoluto di quella cartella
#   nome_progetto      ultima parte del percorso vero del progetto, dal campo
#                      cwd del primo trascritto (*.jsonl) che lo riporta nelle
#                      sue prime 50 righe; vuoto se nessuno lo riporta
#   file               percorso assoluto della memoria
#   nome, descrizione, tipo, modificato   campi dell'intestazione (tipo e
#                      modificato stanno sotto metadata: come type e modified);
#                      le virgolette intorno al valore sono tolte
#   corpo              tutto ciò che segue l'intestazione
# MEMORY.md è un indice e non compare mai. Un file senza intestazione (o con
# un'intestazione mai chiusa) ha tipo "sconosciuto", nome = file senza .md e
# tutto il file come corpo, con un avviso su stderr; il giro continua. Gli
# avvisi vanno su stderr.
#
# Codici di uscita: 0 fatto; 1 radice mancante; 2 chiamata sbagliata.

set -euo pipefail

if [ "$#" -ne 0 ]; then
  echo "uso: inventario.sh   (radice da RIFLETTI_RADICE, se no \$HOME/.claude/projects)" >&2
  exit 2
fi

RADICE="${RIFLETTI_RADICE:-$HOME/.claude/projects}"
if [ ! -d "$RADICE" ]; then
  echo "inventario: radice delle memorie non trovata: $RADICE" >&2
  exit 1
fi
RADICE="$(cd "$RADICE" && pwd -P)"

ha_intestazione() {
  awk 'NR == 1 { if ($0 != "---") exit; next }
       $0 == "---" { trovata = 1; exit }
       END { print (trovata ? "si" : "no") }' "$1"
}

# La chiave deve aprire la riga senza spazi iniziali, così "type" non prende
# mai "node_type".
campo() {
  awk -v chiave="$2" '
    NR == 1 { next }
    $0 == "---" { exit }
    {
      riga = $0
      sub(/^[ \t]+/, "", riga)
      if (index(riga, chiave ":") != 1) next
      val = substr(riga, length(chiave) + 2)
      sub(/^[ \t]+/, "", val)
      sub(/[ \t\r]+$/, "", val)
      if (val ~ /^".*"$/) { val = substr(val, 2, length(val) - 2); gsub(/\\"/, "\"", val) }
      else if (val ~ /^\x27.*\x27$/) { val = substr(val, 2, length(val) - 2); gsub(/\x27\x27/, "\x27", val) }
      print val
      exit
    }' "$1"
}

corpo() {
  awk 'NR == 1 && $0 == "---" { dentro = 1; next }
       dentro && $0 == "---" { dentro = 0; next }
       !dentro { print }' "$1"
}

# head può ricevere SIGPIPE quando jq si ferma al primo cwd: con pipefail
# l'uscita non è 0 anche se il valore è stato letto.
nome_progetto() {
  local f c
  for f in "$1"/*.jsonl; do
    c="$(head -n 50 -- "$f" | jq -nRr 'first(inputs | fromjson? | objects | .cwd // empty | strings | select(. != ""))' 2>/dev/null)" || true
    if [ -n "$c" ]; then
      printf '%s\n' "${c##*/}"
      return
    fi
  done
}

shopt -s nullglob
for cartella in "$RADICE"/*/; do
  cartella="${cartella%/}"
  progetto="${cartella##*/}"
  nome_vero="$(nome_progetto "$cartella")"
  for file in "$cartella"/memory/*.md; do
    base="${file##*/}"
    [ "$base" = "MEMORY.md" ] && continue

    if [ "$(ha_intestazione "$file")" = "si" ]; then
      nome="$(campo "$file" name)"
      descrizione="$(campo "$file" description)"
      tipo="$(campo "$file" type)"
      modificato="$(campo "$file" modified)"
      testo="$(corpo "$file")"
      testo="${testo#$'\n'}"
    else
      echo "inventario: senza intestazione: $file" >&2
      nome="" descrizione="" tipo="" modificato=""
      testo="$(cat -- "$file")"
    fi
    [ -n "$nome" ] || nome="${base%.md}"
    [ -n "$tipo" ] || tipo="sconosciuto"

    jq -nc \
      --arg progetto "$progetto" --arg cartella "$cartella" --arg nome_vero "$nome_vero" --arg file "$file" \
      --arg nome "$nome" --arg descrizione "$descrizione" --arg tipo "$tipo" \
      --arg modificato "$modificato" --arg corpo "$testo" \
      '{progetto: $progetto, cartella_progetto: $cartella, nome_progetto: $nome_vero, file: $file, nome: $nome,
        descrizione: $descrizione, tipo: $tipo, modificato: $modificato, corpo: $corpo}'
  done
done
