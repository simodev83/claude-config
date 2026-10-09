#!/usr/bin/env bash
# SessionStart: mostra quale account GitHub è in uso per la sessione
cwd=$(jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd=$PWD

attivo=$(gh api user --jq .login 2>/dev/null || echo "nessuno")
msg="Account GitHub attivo (gh): $attivo"

if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  remote=$(git -C "$cwd" remote get-url origin 2>/dev/null || echo "nessun remote")
  helper=$(git -C "$cwd" config --local --get-all credential.https://github.com.helper 2>/dev/null | grep -o 'username=[^;]*' | head -1 | cut -d= -f2)
  repo_account=${helper:-$attivo}
  msg="$msg | Repo: $remote -> push/pull con: $repo_account"
fi

jq -n --arg m "$msg" '{systemMessage: $m, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: ("Comunica all utente, in italiano, all inizio della risposta: " + $m)}}'
