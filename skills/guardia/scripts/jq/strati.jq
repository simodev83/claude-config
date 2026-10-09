# Dalla risposta di GitHub stampa i numeri delle PR da leggere, separati da
# spazi, solo se la pila ne nomina di aperte non ancora lette; altrimenti niente.
#
# Adattato da skills/shepherd/scripts/jq/layers.jq di palazzem/claude-config
# (licenza Apache 2.0, copia in LICENSES/Apache-2.0.txt); modificato.

([.[].number] | unique) as $letti
| [ $letti[], (.[].stack.entries.nodes[]? | .pullRequest | select(.state == "OPEN") | .number) ] | unique
| select(. != $letti) | join(" ")
