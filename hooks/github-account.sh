#!/usr/bin/env bash
# SessionStart: fa lavorare la sessione con l'account GitHub del repo e lo annuncia.
#
# Riceve su stdin il JSON dell'hook (usa il campo `cwd`; se manca vale la cartella corrente).
# Se il repo dichiara un account nella propria configurazione di git (riga `username=<login>`
# dentro `credential.https://github.com.helper`, vedi LEGGIMI), scrive il suo token in
# `$CLAUDE_ENV_FILE` come `GH_TOKEN`: da lì in poi `gh` e `git` della sessione usano
# quell'account, senza cambiare l'account attivo di `gh` per gli altri progetti.
# Senza dichiarazione non scrive nulla e vale l'account attivo di `gh`.
#
# Stampa su stdout il JSON con il messaggio per l'utente. L'account annunciato è quello
# che GitHub riconosce con il token appena impostato, non quello dichiarato: se il token
# dell'account dichiarato non si ottiene, il messaggio lo dice.
cwd=$(jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd=$PWD

remote=""
dichiarato=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  remote=$(git -C "$cwd" remote get-url origin 2>/dev/null || echo "nessun remote")
  dichiarato=$(git -C "$cwd" config --local --get-all credential.https://github.com.helper 2>/dev/null | grep -o 'username=[^;]*' | head -1 | cut -d= -f2)
fi

avviso=""
if [ -n "$dichiarato" ]; then
  if token=$(gh auth token --hostname github.com --user "$dichiarato" 2>/dev/null) && [ -n "$token" ]; then
    if [ -n "$CLAUDE_ENV_FILE" ]; then
      export GH_TOKEN=$token
      printf 'export GH_TOKEN=%q\n' "$token" >> "$CLAUDE_ENV_FILE"
    else
      avviso=" | ATTENZIONE: non posso impostare l'account per i comandi della sessione (CLAUDE_ENV_FILE mancante): gh userà l'account attivo"
    fi
  else
    avviso=" | ATTENZIONE: il repo dichiara l'account $dichiarato ma gh non ha il suo accesso: lancia gh auth login per quell'account"
  fi
fi

attivo=$(gh api user --jq .login 2>/dev/null || echo "nessuno")
msg="Account GitHub della sessione (gh e git): $attivo"
if [ -n "$remote" ]; then
  if [ -n "$dichiarato" ]; then
    msg="$msg | Repo: $remote | account dichiarato dal repo: $dichiarato"
  else
    msg="$msg | Repo: $remote | nessun account dichiarato dal repo: vale quello attivo di gh"
  fi
fi
msg="$msg$avviso"

jq -n --arg m "$msg" '{systemMessage: $m, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: ("Comunica all utente, in italiano, all inizio della risposta: " + $m)}}'
