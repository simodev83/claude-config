# Modalità mappa: lavori più grandi di una sessione

Usala quando il lavoro non sta in una conversazione. Invece di un unico interrogatorio si disegna una **mappa**: un indice delle decisioni da prendere, risolte **una per sessione**.

## La regola più importante: si pianifica, non si esegue

Ogni elemento della mappa è una **domanda la cui risposta è una decisione**, mai un pezzo di lavoro da costruire. "Scegliere il database" è una decisione; "creare le tabelle" è lavoro, e non va sulla mappa. Quando senti la spinta a "fare" invece che a "decidere", sei arrivato al bordo della mappa: è il momento di passare a `/spec`.

## La mappa

Una sola issue (etichetta `wf:mappa`, titolo `Mappa – <tema>`) oppure il file `<cartella>/mappa-<tema>.md` (`<cartella>` è `docs/workflow/` per File, `.claude/specs/` per Locale: sezione 4 della skill `archivio`). Il corpo ha cinque sezioni:

```markdown
## Destinazione
<come appare l'arrivo: una spec pronta, una decisione presa, una migrazione fatta. Una o due righe.>

## Note
<contesto, preferenze stabili dell'utente, skill da consultare>

## Decisioni finora
- <titolo della decisione (#N, o il percorso del file)>: <l'esito in una riga>

## Nebbia
- <decisioni che si intravedono ma non si sanno ancora formulare bene>

## Fuori perimetro
- <cosa è stato escluso dalla destinazione>
```

La mappa è un **indice**: ogni decisione vive per esteso nella sua issue (o nel suo file), e la mappa ne riporta solo l'esito in una riga con il collegamento.

## Le decisioni

Ogni decisione è una sotto-issue della mappa (`--parent <mappa>`, etichetta `wf:decisione`), oppure un file in `<cartella>/decisioni/<tema>/`. Il titolo inizia con il tipo:

| Tipo | Come si risolve | Serve l'utente? |
|---|---|---|
| `[Interrogatorio]` | Round di domande come nella skill `requisiti`, limitati a questa decisione | Sì |
| `[Prototipo]` | Si costruisce qualcosa **da buttare** per vedere come si comporta, a parte (sezione "Prototipi" qui sotto), e si scrive l'esito nella decisione. Il prototipo non si unisce mai al progetto | Sì, per valutarlo |
| `[Ricerca]` | Si chiede all'agente `ricercatore` cosa dicono documentazione e fonti ufficiali, una domanda per agente (quelle indipendenti insieme), e si riporta la risposta con citazioni e link; una risposta `NON VERIFICATO` resta tale | No |
| `[Compito]` | Un lavoro manuale che **sblocca** una decisione (per esempio chiedere un accesso, un preventivo) | Di solito sì |

Se una decisione dipende da un'altra, collegala con `--blocked-by`, oppure con la riga `Bloccato da: <file>` in modalità File o Locale.

## Prototipi

Con git il prototipo si costruisce in un worktree a parte, così la cartella principale del progetto resta com'era:

1. Apri il worktree con i passi da 1 a 6 dell'apertura (sezione 8 della skill `archivio`), con `proto-<tema>` come nome breve e `proto/<tema>` come ramo (`<tema>` scritto con le regole del nome breve). Piano e strati non ci sono: chiedi all'utente quali dipendenze e file locali servono e prepara il worktree come al passo 8; la verifica di partenza non serve.
2. Costruisci il minimo che risponde alla domanda della decisione, con commit sul ramo del prototipo. Anche il prototipo si scrive in TDD: carica la skill `tdd` e segui il suo ciclo e le sue regole, ma non la sezione "Se usi questa skill da sola", perché worktree, ramo e commit sono quelli di qui. Niente push né pull request.
3. Mostra il risultato all'utente e raccogli la sua valutazione. L'esito non si scrive ancora: lo scrivi dopo la chiusura, dalla cartella principale, al punto 4 delle "Sessioni successive".
4. Con l'ok dell'utente, chiudi: commit di quello che resta, `ExitWorktree` con `action: "keep"`, `git worktree remove "<percorso>"` e `git branch -D proto/<tema>`.

Senza git lavora in una cartella temporanea fuori dal progetto e, con l'ok dell'utente, cancellala alla fine.

## Sessione 1: tracciare la mappa

1. Con l'utente, definisci la **destinazione** in una o due righe.
2. Crea subito la mappa con la sola destinazione: con Issues serve il suo numero per agganciare le decisioni.
3. Individua le prime decisioni già formulabili e crea le loro sotto-issue della mappa (o i loro file); il resto va in **Nebbia**.
4. Completa il corpo della mappa (Note, Nebbia, Fuori perimetro) con `gh issue edit`, oppure aggiornando il file in modalità File o Locale. Mostrala all'utente e fermati.

## Sessioni successive: una decisione alla volta

1. Leggi la mappa (una volta sola) e le decisioni aperte: le sotto-issue aperte, o i file con `Stato: aperto`.
2. La **frontiera** è l'insieme delle decisioni aperte non bloccate da altre decisioni aperte. Proponi all'utente quale risolvere, con il tuo consiglio.
3. Risolvi **solo quella**, nel modo del suo tipo.
4. Scrivi l'esito come commento nell'issue e chiudila (in modalità File o Locale: in fondo al file, e la prima riga diventa `Stato: chiuso`), poi aggiungi una riga in **Decisioni finora**.
5. Guarda la **Nebbia**: se una voce ora si può formulare, trasformala in una nuova decisione.
6. **Fermati.** Una decisione per sessione tiene il contesto pulito.

## Fine della mappa

La mappa è completa quando non ci sono decisioni aperte e la Nebbia è vuota. Allora:

1. Scrivi i requisiti finali come nel passo 3 della skill `requisiti`, raccogliendo le decisioni della mappa.
2. Chiudi la mappa con un commento che rimanda ai requisiti (in modalità File o Locale: il rimando in fondo al file, e la prima riga diventa `Stato: chiuso`).
3. Chiudi come nel passo 4 della skill `requisiti`: se sei stata richiamata da `workflow` restituisci il riferimento e termini, altrimenti proponi `/spec` per la prima funzione.
