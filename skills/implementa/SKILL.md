---
name: implementa
description: Il regista della costruzione - a partire da spec e piano apre il worktree, fa costruire ogni passo a un agente costruttore e rilancia i test, poi per ogni strato fa semplificare e rivedere il codice da agenti separati, fa il collaudo finale criterio per criterio e apre una pull request per strato, che l'utente unirà. Usala solo quando l'utente scrive /implementa o quando la skill workflow la richiama.
argument-hint: "<funzione>"
---

# Implementa: il regista della costruzione

Funzione: $ARGUMENTS (se è vuoto, chiedi quale funzione costruire).

Il lavoro è finito solo quando **ogni criterio di accettazione della spec è verificato** e il lavoro è consegnato (pull request aperte, o ramo pronto). Non prima.

**Tu sei il regista: non scrivi codice del progetto**, nemmeno una piccola correzione. Il codice lo scrivono gli agenti: `costruttore` (un passo, sempre in TDD), `semplificatore` (riordino di uno strato), mentre il `revisore` lo esamina in sola lettura. Tu prepari il worktree, gestisci rami e pila, lanci gli agenti uno alla volta, rilanci i test dopo ognuno, tieni aggiornati archivio e stato, e consegni.

Dopo l'approvazione del piano si procede **in autonomia**, senza chiedere conferme, fermandosi solo nei casi della sezione "Quando fermarsi".

## Passo 0: archivio, spec e piano

1. Carica la skill `archivio` ed esegui il suo controllo iniziale, compreso il passo 7 (strumenti per la consegna). Annota: tipo di archivio, consegna (GitHub, git locale, senza git), ramo principale.
2. Leggi la spec e prendi il suo **nome breve**. Se non c'è, fermati e proponi `/spec <funzione>`.
3. Leggi il piano: con Issues, l'ultimo commento della spec che inizia con `## Piano` e le sotto-issue `wf:passo`; con File o Locale, `<cartella>/piani/<nome-breve>.md` (`<cartella>` come nella sezione 4 della skill `archivio`). Annota gli strati con i loro passi, rami e basi, e la sezione `Preparazione del worktree` (dipendenze, file locali, comando di test).
   - Se non c'è e la funzione è piccola, scrivi un mini-piano nello stesso formato della skill `piano` (passi con verifica, un solo strato, preparazione del worktree), mostralo in parole semplici e aspetta l'ok. Poi salvalo come al passo 6 della skill `piano`.
   - Se non c'è e la funzione è grande, proponi prima `/piano <funzione>`.

## Passo 1: worktree e stato

**Con git**, apri il worktree come nella sezione 8 della skill `archivio`, con il ramo del primo strato e la preparazione del piano. Se il worktree esiste già, il lavoro era iniziato: vai a "Ripresa" qui sotto.

Poi annota la **base del primo strato**: `git rev-parse HEAD`, subito dopo l'apertura (in modalità File, dopo il commit dei documenti).

**Il file di stato.** Il punto a cui sei arrivata si scrive in `<cartella comune>/wf/<nome-breve>/stato.md` (`<cartella comune>` come nella sezione 10 della skill `archivio`): serve a riprendere il lavoro in un'altra sessione. Scrivilo con lo strumento Write e aggiornalo dopo ogni passo e ogni fase:

```markdown
Funzione: <nome-breve>
Consegna: <GitHub | git locale>

## Strato N – <titolo>
- Ramo: <ramo>
- Base: <ramo dello strato sotto | hash>
- Passi fatti: <numeri>
- Semplificazione: da fare | fatta
- Revisione: da fare | fatta
- Correzioni: da fare | fatte | nessuna

## Collaudo finale: da fare | fatto
## Divisioni: <strati divisi durante il lavoro, o nessuna>
## Consegna: da fare | fatta (<collegamenti>)
```

**Ripresa.** Il worktree esiste già e ci sei entrata (sezione 8 della skill `archivio`, passo 1).

1. `git status --porcelain` nel worktree: se mostra qualcosa, un agente si è fermato a metà. Mostra all'utente l'elenco in parole semplici e chiedi come procedere; non annullare e non fare il commit da sola.
2. Leggi il file di stato. Se manca, ricostruiscilo: `gh stack view --json` (con più strati) e `git log --oneline` di ogni strato mostrano i commit `Passo N – …` già fatti.
3. Riparti dalla prima voce "da fare".

**Senza git** (l'utente ha rifiutato `git init`): niente worktree, rami, commit né file di stato. Tieni tu l'elenco dei file creati o modificati da ogni agente: servirà a semplificazione, revisione e rapporto finale. Gli strati restano gruppi di passi da rivedere insieme.

## Passo 2: gli strati, uno alla volta

Per ogni strato, dal basso verso l'alto:

### a. Apertura dello strato

- **Primo strato**: è il ramo del worktree. Base: quella annotata al passo 1.
- **Strato successivo, consegna GitHub**: con lo strato sotto chiuso, apri il nuovo ramo con `gh stack` come nella sezione 9 della skill `archivio` (la prima volta anche la "Preparazione, una volta per repo"). Base: il ramo dello strato sotto.
- **Strato successivo, consegna git locale**: stesso ramo. Base: `git rev-parse HEAD` prima del primo passo dello strato.

### b. I passi

Per ogni passo dello strato, in ordine:

1. **Lancia un `costruttore`** (strumento Agent, `subagent_type: "costruttore"`), uno alla volta, e aspetta il suo rapporto. Nell'incarico scrivi:

   ```text
   Spec: <numero dell'issue o percorso assoluto>
   Piano: <issue del passo, o percorso assoluto del piano>
   Passo: N – <titolo>
   Criteri coperti: <numeri>
   Punti di test: <dalla riga Verifica del passo>
   Cartella di lavoro: <percorso del worktree>
   Ramo: <ramo dello strato>
   Base: <base dello strato>
   Comando di test: <comando>
   ```

   Con archivio Locale i percorsi dei documenti sono quelli assoluti nella `<radice>` (sezione 4 della skill `archivio`). Senza git, al posto di ramo e base scrivi "Senza git: niente commit".

2. **Se risponde `BLOCCATO`:**
   - se la risposta è già nella spec, nel piano o nel codice e non cambia nulla di ciò che l'utente vedrà, rispondi tu, riprendendo lo stesso agente con SendMessage;
   - altrimenti è una decisione dell'utente: fermati, fagli la domanda in parole semplici con le opzioni e la tua raccomandazione, poi riprendi lo stesso agente con la risposta.

3. **Se risponde `FATTO`, controlla tu**, senza fidarti del rapporto:
   - `git status --porcelain` non stampa nulla;
   - `git log --oneline <base>..HEAD` mostra il nuovo commit `Passo N – …`;
   - rilancia il comando di test: tutto verde.

   Senza git, rilancia solo il comando di test. Se qualcosa non torna, riprendi lo stesso agente con SendMessage e l'uscita del comando. Dopo due riprese senza risultato, fermati.

4. **Registra il passo:**
   - **Issues**: commenta l'issue del passo con "Fatto nel commit <hash breve> sul ramo <ramo>". Non chiuderla: si chiuderà da sola con il merge.
   - **Locale**, o **File senza git**: spunta il passo nella checklist del piano.
   - **File con git**: la checklist si aggiorna alla chiusura dello strato (punto e).
   - Aggiorna il file di stato e annota gli scostamenti del rapporto: serviranno alla consegna.

5. **Misura lo strato** (solo con git): `git diff --shortstat <base>...HEAD`; le righe sono inserimenti più cancellazioni. Se superano **300** e restano passi in questo strato, **dividilo**: lo strato si chiude qui (punti c, d, e) e i passi rimasti formano un nuovo strato subito sopra, con titolo "<titolo> (seguito)" e il ramo con il numero successivo; gli strati del piano non ancora aperti scalano di un numero, e così i loro rami. Annota la divisione nel file di stato: la dirai nel rapporto finale. Non riscrivere il piano.

### c. Semplificazione

Con tutti i passi dello strato fatti, lancia un `semplificatore` (`subagent_type: "semplificatore"`) con cartella, ramo, base dello strato, spec e comando di test (senza git, l'elenco dei file dello strato). Al rapporto, ripeti i controlli del punto b.3, ma senza cercare un commit `Passo`: se ha semplificato, c'è un commit `Semplificazione dello strato`.

### d. Revisione dello strato

Lancia un `revisore` (`subagent_type: "revisore"`) in modalità **consegna**, con la spec, la cartella, l'intervallo `<base>..HEAD` (senza git, l'elenco dei file dello strato) e il comando di test.

- I problemi **bloccanti e importanti** si correggono: riprendi con SendMessage l'ultimo `costruttore` dello strato con l'elenco dei problemi, come giro di correzioni. Se non è più raggiungibile (per esempio dopo una ripresa), lancia un nuovo `costruttore` con l'incarico del punto b.1, scrivendo al posto del passo "Giro di correzioni" e l'elenco. Al rapporto, ripeti i controlli del punto b.3, cercando i commit `Correzione: …`.
- I **minori**, e i problemi che il costruttore ha motivato di non correggere, non si toccano: vanno nella consegna.
- La revisione si fa **una volta sola**: non rilanciare il revisore dopo le correzioni.

### e. Chiusura dello strato

- **File con git**: spunta i passi dello strato nella checklist del piano, nel worktree, e fai il commit del solo file del piano: `Piano: strato N fatto`.
- Aggiorna il file di stato.

## Passo 3: collaudo finale

Con tutti gli strati chiusi, e con più strati dalla cima della pila (`gh stack top`), lancia un `revisore` in modalità **collaudo finale**, con la spec, la cartella, l'intervallo `<base del primo strato>..HEAD` (senza git, l'elenco di tutti i file) e il comando di test.

- **Si può consegnare** → passo 4.
- **Non ancora** → correggi i criteri ❌ e i problemi bloccanti e importanti, in un giro solo:
  1. Trova lo strato a cui appartiene ogni correzione: quello del passo che copre il criterio, o quello che ha introdotto il codice da correggere.
  2. Con più strati e consegna GitHub, spostati su quello strato con `gh stack checkout <ramo>`. Altrimenti resta in cima.
  3. Lancia un nuovo `costruttore` con l'incarico del punto b.1 per quello strato, scrivendo al posto del passo "Giro di correzioni" e l'elenco. Al rapporto, ripeti i controlli del punto b.3, cercando i commit `Correzione: …`.
  4. Con più strati, dopo una correzione su uno strato sotto: `gh stack rebase --upstack --no-trunk`, test su ogni strato sopra, poi `gh stack top` (sezione 9 della skill `archivio`).
  5. Il collaudo non si ripete: per ogni criterio che era ❌ cerca tu la prova, lanciando il test che ora lo verifica, e aggiorna la tabella. Se un criterio resta senza prova, fermati e spiega all'utente cosa blocca.

Aggiorna il file di stato.

## Passo 4: consegna

Segui la sezione 10 ("Consegna del lavoro") della skill `archivio`.

**Con consegna GitHub**, un corpo per strato, con questa struttura:

```markdown
## Cosa fa
<due o tre righe sullo scopo dello strato>

## Strato <N> di <M>
<solo con più strati: si rilegge e si unisce dal basso; sotto c'è <ramo>, sopra <ramo>>

## Passi
- Passo N – <titolo>

## Criteri di accettazione
<le righe della tabella del collaudo per i criteri coperti da questo strato; nell'ultimo strato la tabella intera>

## Revisione automatica
- Semplificato: <elenco, o "niente da fare">
- Corretto: <elenco>
- Segnalato ma non cambiato: <elenco, con il motivo>

## Pezzi senza test
<i controlli concreti dichiarati dai costruttori, o "nessuno">

## Come provarlo
<passi per verificarlo a mano, se utile>

Closes #<passo>
Closes #<spec>
```

Le righe `Closes` ci sono solo con archivio Issues: una per ogni passo dello strato, e quella della spec solo nell'ultimo strato.

Titolo: `<Funzione>: <sintesi in poche parole>`; con più strati `<Funzione> (<N>/<M>): <scopo dello strato>`.

**Stato dei documenti:**

- **File**: aggiorna la prima riga della spec e del piano in `Stato: implementato sul ramo <ramo>` e fai il commit dei due file prima di consegnare (senza git: `Stato: implementato`, senza commit).
- **Locale**: `Stato: implementato sul ramo <ramo in cima>`, senza commit.

Aggiorna il file di stato con la consegna fatta e i collegamenti.

## Passo 5: rapporto finale

Se sei stata richiamata da `workflow`, restituisci solo i collegamenti alle pull request (o il nome del ramo), la tabella dei criteri e le divisioni di strati: il riepilogo finale lo fa il workflow.

Altrimenti dai all'utente, in breve e in parole semplici:

- i collegamenti alle pull request, nell'ordine in cui rileggerle e unirle (dal basso), oppure il nome del ramo, oppure l'elenco dei file senza git;
- la tabella dei criteri;
- cosa hanno fatto semplificazione e revisione, cosa è stato corretto e cosa è stato segnalato senza cambiarlo;
- gli strati divisi durante il lavoro perché erano cresciuti troppo, se ce ne sono;
- i pezzi senza test e come sono stati controllati;
- cosa controllare prima di premere "Merge";
- con git, che il worktree resta aperto: quando il lavoro è unito può chiedere a Claude di chiuderlo (sezione 8 della skill `archivio`, "Chiusura").

## Quando fermarsi

Dopo l'approvazione del piano ti fermi a chiedere **solo** in questi casi:

- modifiche non salvate nella cartella principale, o lasciate a metà nel worktree;
- ramo del primo strato già esistente;
- preparazione del worktree fallita: file locale mancante o non escluso, installazione delle dipendenze fallita, test rossi prima di iniziare;
- un `costruttore` bloccato su una decisione che spetta all'utente;
- un passo che si rivela sbagliato o impossibile: spiega cosa è emerso e cosa proponi, senza riscrivere il piano da sola;
- test ancora rossi dopo due riprese dello stesso agente;
- un conflitto di `gh stack rebase` che non sai risolvere con certezza;
- un criterio ancora senza prova dopo il giro di correzioni del collaudo;
- un push rifiutato o un errore di permessi di `gh`.
