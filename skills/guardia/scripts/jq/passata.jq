include "lib";

def evento($nome; $soglia):
  select(.updatedAt > $soglia and non_marcato)
  | { evento: $nome, url: .url, login: .author.login, ruolo: .authorAssociation, quando: .updatedAt };

def attivita($commento; $revisione; $risposta):
  (.comments.nodes[] | evento("COMMENTO"; $commento)),
  (.reviews.nodes[]
    | select((.body // "") != "" or .state != "COMMENTED")
    | . as $r | evento("REVISIONE"; $revisione) | .esito = $r.state),
  (.reviewThreads.nodes[].comments.nodes[] | select(inviato) | evento("RISPOSTA"; $risposta));

def segno:
  { commento:  piu_recente(.comments.nodes[]),
    revisione: piu_recente(.reviews.nodes[]),
    risposta:  piu_recente(.reviewThreads.nodes[].comments.nodes[] | select(inviato)),
    merge:     .mergeStateStatus,
    ci:        stato_ci,
    testa:     testa };

def finita: .state | IN("MERGED", "CLOSED");

def eventi($armato; $ultimo):
  .number as $pr
  | if finita then { evento: (if .state == "MERGED" then "UNITA" else "CHIUSA" end) }
    else
      (.mergeStateStatus
        | select(IN("BEHIND", "DIRTY") and . != $ultimo.merge)
        | { evento: (if . == "BEHIND" then "INDIETRO" else "CONFLITTO" end) }),
      (select(stato_ci == "FALLITA" and (stato_ci != $ultimo.ci or testa != $ultimo.testa))
        | { evento: "CI_FALLITA" }),
      attivita($armato.commento; $armato.revisione; $armato.risposta)
    end
  | { evento, pr: $pr } + .;

def mai_visto: { commento: $epoca, revisione: $epoca, risposta: $epoca, merge: "", ci: "", testa: "" };

def voce($segnalibro): mai_visto + ($segnalibro[.number | tostring] // {});

def posizione:
  .number as $pr
  | first(.stack.entries.nodes[]? | select(.pullRequest.number == $pr) | .position) // 0;

[.[]] | sort_by(posizione, .number)
| (.[] | eventi(voce($armato); voce($ultimo))),
  (map(select(finita | not) | { key: (.number | tostring), value: segno }) | from_entries)
