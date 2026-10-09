([.[].number] | unique) as $letti
| [ $letti[], (.[].stack.entries.nodes[]? | .pullRequest | select(.state == "OPEN") | .number) ] | unique
| select(. != $letti) | join(" ")
