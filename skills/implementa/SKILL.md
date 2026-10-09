---
name: implementa
description: Implementa una funzione a partire da spec e piano, un passo alla volta su un ramo dedicato, con test anti-regressione, verifica finale criterio per criterio, revisione del codice da parte di un agente separato e apertura di una pull request che l'utente unirà. Usala solo quando l'utente scrive /implementa o quando la skill workflow la richiama.
argument-hint: "<funzione> [tdd|classica]"
---

# Implementa: costruire e collaudare

Argomenti: $ARGUMENTS. Se l'**ultima parola** è `tdd` o `classica`, è la modalità forzata per **tutti** i passi; il resto è la funzione. Altrimenti è tutto il nome della funzione e ogni passo usa la modalità scritta nel piano.

Il lavoro è finito solo quando **ogni criterio di accettazione della spec è verificato** e il lavoro è consegnato (pull request aperta, o ramo pronto). Non prima.

## Passo 0: archivio, spec e piano

1. Carica la skill `archivio` ed esegui il suo controllo iniziale. Annota: tipo di archivio, se c'è git, il ramo principale.
2. Leggi la spec e prendi il suo **nome breve**. Se non c'è, fermati e proponi `/spec <funzione>`.
3. Leggi il piano (sotto-issue `wf:passo` della spec, o `docs/workflow/piani/<nome-breve>.md`), compresi strumento e comando di test.
   - Se non c'è e la funzione è piccola, scrivi un mini-piano (passi con modalità, strumento e comando di test, come nella skill `piano`), mostralo e aspetta l'ok. Da quel momento si procede in autonomia.
   - Se non c'è e la funzione è grande, proponi prima `/piano <funzione>`.

## Passo 1: preparazione

**Con git:**

1. `git status`. Se ci sono modifiche non salvate diverse dai documenti in `docs/workflow/` di questa funzione, **fermati** e chiedi all'utente cosa farne. Non sovrascriverle e non metterle da parte senza chiedere.
2. Porta aggiornato il ramo principale: `git switch <principale>`, poi, se c'è un remote, `git pull --ff-only`. Se il pull fallisce, fermati e riporta l'errore.
3. Crea il ramo di lavoro: `git switch -c feature/<nome-breve>` (per una correzione di bug: `fix/<nome-breve>`). Se il ramo esiste già, **fermati** e chiedi se riprenderlo o crearne uno nuovo.
4. **Modalità File**: il primo commit del ramo contiene spec e piano della funzione, indicati per percorso esatto: `git add docs/workflow/spec/<nome-breve>.md docs/workflow/piani/<nome-breve>.md`, poi `git commit -m "Documenti: <nome-breve>"`. Requisiti e mappa restano sul ramo principale (sezione 4 della skill `archivio`).

**Senza git** (l'utente ha rifiutato `git init`): niente ramo né commit. Tieni tu l'elenco dei file che crei o modifichi: servirà alla revisione e al rapporto finale.

Poi verifica che il comando di test del piano funzioni. Se lo strumento di test non è ancora installato, non installarlo qui: la sua installazione è il primo passo del piano e verrà eseguita nel passo 2, come gli altri.

## Passo 2: i passi del piano, uno alla volta

Se almeno un passo è in modalità TDD, carica la skill `tdd` **una sola volta**, senza argomenti, prima del primo passo: le sue regole valgono per tutti i passi TDD.

Per ogni passo, in ordine:

1. **Modalità TDD** → segui il ciclo della skill `tdd` per questo passo.
   **Modalità classica** → scrivi il codice, poi i test sui punti di test della spec.
2. Fai girare i test dell'area toccata. Se qualcosa si rompe, correggi prima di andare avanti.
3. Registra il passo:
   - **Modalità File**: spunta il passo nella checklist del piano.
   - **Con git**: `git add` dei soli file del passo (in modalità File anche il file del piano), poi `git commit -m "Passo N – <titolo>"`.
   - **Issues**: commenta l'issue del passo con "Fatto nel commit <hash breve> sul ramo <ramo>". Non chiuderla: si chiuderà da sola quando l'utente unirà la pull request.

Se un passo si rivela sbagliato o impossibile, **fermati** e spiega all'utente cosa hai scoperto e cosa proponi. Non riscrivere il piano da solo.

## Passo 3: controllo anti-regressione

Fai girare **tutti** i test del progetto, più linter e controllo dei tipi se esistono. Tutto deve passare. Se un test che prima passava ora fallisce, è una **regressione**: correggila prima di proseguire.

## Passo 4: loop di chiusura

Riprendi la spec e verifica **ogni** criterio di accettazione, uno per uno. Per ciascuno scrivi la prova concreta:

| Criterio | Esito | Prova |
|---|---|---|
| 1. <testo> | ✅ / ❌ | <nome del test che lo verifica, oppure il controllo eseguito e il suo risultato> |

- "Dovrebbe funzionare" non è una prova. Una prova è un test che passa o un controllo eseguito davvero.
- Se un criterio è ❌, torna al passo 2 per coprirlo, poi ripeti il passo 3 e questo passo.
- Dopo 3 giri senza chiudere tutti i criteri, **fermati** e spiega all'utente cosa blocca.

## Passo 5: revisione con occhi freschi

Affida la revisione a un **sotto-agente separato** che non ha scritto il codice. Nel suo incarico scrivi:

- di leggere le istruzioni nel file `${CLAUDE_SKILL_DIR}/revisione.md`;
- dove trovare la spec (numero dell'issue o percorso del file);
- **con git**: di esaminare le modifiche lui stesso con `git log <principale>..HEAD` e `git diff <principale>...HEAD`;
- **senza git**: l'elenco dei file creati o modificati.

Quando torna il rapporto:

- correggi i problemi **concreti** (bloccanti e importanti) e rifai girare tutti i test; con git, commit `Correzioni dalla revisione`;
- per i suggerimenti minori o discutibili non cambiare nulla: riportali nella consegna.

## Passo 6: consegna

Segui la sezione 7 ("Consegna del lavoro") della skill `archivio`.

In modalità Issues, il corpo della pull request è:

```markdown
## Cosa fa
<due o tre righe>

## Criteri di accettazione
<la tabella del passo 4>

## Revisione automatica
- Corretto: <elenco>
- Segnalato ma non cambiato: <elenco, con il motivo>

## Come provarlo
<passi per verificarlo a mano, se utile>

Closes #<spec>
Closes #<passo 1>
...
```

Titolo della pull request: `<Funzione>: <sintesi in poche parole>`.

In modalità File, aggiorna la prima riga della spec e del piano in `Stato: implementato sul ramo <ramo>` (senza git: `Stato: implementato`); con git, includi questa modifica in un ultimo commit.

## Passo 7: rapporto finale

Se sei stata richiamata da `workflow`, restituisci solo il collegamento alla pull request (o il nome del ramo) e la tabella dei criteri: il riepilogo finale lo fa il workflow.

Altrimenti dai all'utente, in breve:

- il collegamento alla pull request (o il nome del ramo, o l'elenco dei file senza git);
- la tabella dei criteri;
- cosa ha trovato la revisione e cosa è stato corretto;
- cosa controllare prima di premere "Merge".
