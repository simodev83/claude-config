# Definizioni comuni della passata: stato della CI, commit in cima, attività
# più recente, revisioni inviate, testi non marcati. Usano $epoca e $marcatore.
#
# Adattato da skills/shepherd/scripts/jq/lib.jq di palazzem/claude-config
# (licenza Apache 2.0, copia in LICENSES/Apache-2.0.txt); modificato.

# Un controllo annullato sul commit in cima è un annullamento a mano, non un
# push più recente (quelli riguardano il commit vecchio), e blocca il merge.
def stato_ci:
  [ .commits.nodes[0].commit.statusCheckRollup.contexts.nodes[]?
    | if .__typename == "CheckRun" then
        if .status != "COMPLETED" then "IN_CORSO"
        elif .conclusion == "STALE" then "IN_CORSO"
        elif (.conclusion | IN("FAILURE", "TIMED_OUT", "ACTION_REQUIRED", "STARTUP_FAILURE", "CANCELLED")) then "FALLITA"
        else "OK" end
      else
        if (.state | IN("ERROR", "FAILURE")) then "FALLITA"
        elif (.state | IN("PENDING", "EXPECTED")) then "IN_CORSO"
        else "OK" end
      end ]
  | if index("FALLITA") then "FALLITA"
    elif index("IN_CORSO") then "IN_CORSO"
    elif length == 0 then "NESSUNA"
    else "OK" end;

def testa: .commits.nodes[0].commit.oid // "";

def piu_recente(s): [s | .updatedAt] | max // $epoca;

def inviato: .pullRequestReview.state != "PENDING";

def non_marcato:
  ((.body // "") | ltrimstr("﻿") | gsub("^\\s+"; "") | startswith($marcatore)) | not;
