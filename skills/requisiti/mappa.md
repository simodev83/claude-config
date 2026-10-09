# Modalità mappa: lavori più grandi di una sessione

Usala quando il lavoro non sta in una conversazione. Invece di un unico interrogatorio si disegna una **mappa**: un indice delle decisioni da prendere, risolte **una per sessione**.

## La regola più importante: si pianifica, non si esegue

Ogni elemento della mappa è una **domanda la cui risposta è una decisione**, mai un pezzo di lavoro da costruire. "Scegliere il database" è una decisione; "creare le tabelle" è lavoro, e non va sulla mappa. Quando senti la spinta a "fare" invece che a "decidere", sei arrivato al bordo della mappa: è il momento di passare a `/spec`.

## La mappa

Una sola issue (etichetta `wf:mappa`, titolo `Mappa – <tema>`) oppure il file `<cartella>/mappa-<tema>.md` (`<cartella>` è `docs/workflow/` per File, `.claude/specs/` per Locale: sezione 4 della skill `archivio`). Il corpo ha quattro sezioni:

```markdown
## Destinazione
<come appare l'arrivo: una spec pronta, una decisione presa, una migrazione fatta. Una o due righe.>

## Note
<contesto, preferenze stabili dell'utente, skill da consultare>

## Decisioni finora
- <titolo della decisione (#N)>: <l'esito in una riga>

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
| `[Prototipo]` | Si costruisce qualcosa **da buttare** per vedere come si comporta, su un ramo `proto/<tema>` (o in una cartella temporanea fuori dal progetto se non c'è git), mai sul ramo principale. L'esito si scrive nell'issue; poi si torna sul ramo principale e, con l'ok dell'utente, il ramo del prototipo si cancella senza unirlo | Sì, per valutarlo |
| `[Ricerca]` | Si studiano documentazione e fonti ufficiali e si riporta cosa dicono, con i link | No, può farla un sotto-agente |
| `[Compito]` | Un lavoro manuale che **sblocca** una decisione (per esempio chiedere un accesso, un preventivo) | Di solito sì |

Se una decisione dipende da un'altra, collegala con `--blocked-by`.

## Sessione 1: tracciare la mappa

1. Con l'utente, definisci la **destinazione** in una o due righe.
2. Crea subito la mappa con la sola destinazione: serve il suo numero per agganciare le decisioni.
3. Individua le prime decisioni già formulabili e crea le loro issue come sotto-issue della mappa; il resto va in **Nebbia**.
4. Completa il corpo della mappa (Note, Nebbia, Fuori perimetro) con `gh issue edit`, oppure aggiornando il file in modalità File o Locale. Mostrala all'utente e fermati.

## Sessioni successive: una decisione alla volta

1. Leggi la mappa (una volta sola) e le sotto-issue aperte.
2. La **frontiera** è l'insieme delle decisioni aperte non bloccate da altre decisioni aperte. Proponi all'utente quale risolvere, con il tuo consiglio.
3. Risolvi **solo quella**, nel modo del suo tipo.
4. Scrivi l'esito come commento nell'issue, chiudila, aggiungi una riga in **Decisioni finora**.
5. Guarda la **Nebbia**: se una voce ora si può formulare, trasformala in una nuova decisione.
6. **Fermati.** Una decisione per sessione tiene il contesto pulito.

## Fine della mappa

La mappa è completa quando non ci sono decisioni aperte e la Nebbia è vuota. Allora:

1. Scrivi i requisiti finali come nel passo 3 della skill `requisiti`, raccogliendo le decisioni della mappa.
2. Chiudi l'issue della mappa con un commento che rimanda ai requisiti.
3. Chiudi come nel passo 4 della skill `requisiti`: se sei stata richiamata da `workflow` restituisci il riferimento e termini, altrimenti proponi `/spec` per la prima funzione.
