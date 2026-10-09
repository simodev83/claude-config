---
name: piano
description: Scompone la spec di una funzione in passi piccoli, ordinati e verificabili, li raggruppa in strati (una pull request ciascuno), sceglie lo stack se non è deciso e annota come preparare il worktree (dipendenze da installare, file locali da copiare); il piano va approvato prima di scrivere codice. Usala solo quando l'utente scrive /piano o quando la skill workflow la richiama.
argument-hint: "<funzione>"
---

<!-- Adattata in parte da skills/deliver/SKILL.md di palazzem/claude-config (licenza Apache 2.0, copia in LICENSES/Apache-2.0.txt); riscritta in italiano e modificata. -->

# Piano: la sequenza di lavoro

Funzione: $ARGUMENTS (se è vuoto, chiedi per quale spec fare il piano).

Il piano dice **come** si arriva a soddisfare la spec: in quali passi, in che ordine, raggruppati in quali strati, con quali strumenti. Nessuna riga di codice viene scritta prima che l'utente lo approvi.

Ogni passo verrà costruito in **TDD** (prima un test che fallisce, poi il codice): il piano non sceglie un metodo diverso per passo, dice solo cosa provare con i test.

## Passo 0: archivio e contesto

1. Carica la skill `archivio` ed esegui il suo controllo iniziale. Annota il tipo di archivio, la consegna (GitHub, git locale, senza git) e il ramo principale.
2. Trova e leggi la spec (etichetta `wf:spec`, o `<cartella>/spec/<nome-breve>.md`; `<cartella>` è `docs/workflow/` per File, `.claude/specs/` per Locale, come nella sezione 4 della skill `archivio`) e prendi il suo **nome breve** e i suoi **punti di test**. Se non esiste, fermati e proponi `/spec <funzione>`.
3. Esplora il codice: struttura, librerie in uso, come si lanciano i test, convenzioni. Per un'esplorazione ampia usa un sotto-agente.

## Passo 1: lo stack

Se il progetto ha già uno stack (linguaggio, framework, database, strumento di test), usa quello e dillo in una riga.

Lo **strumento di test** fa parte dello stack e si decide qui, con il comando per lanciare i test (per esempio `npm test`, `pytest`). Se il progetto non ha test, proponi lo strumento più comune per il suo stack e mettine l'installazione come primo passo del piano. Così `implementa` non dovrà fermarsi a chiedere.

Se va scelto, o se la funzione richiede un componente nuovo (una libreria, un servizio esterno):

- proponi **2 o 3 opzioni** con pro e contro concreti, ordinate secondo le regole del `CLAUDE.md` sulle decisioni: per qualità del risultato, con costi e fatica scritti come avvertenze, più l'opzione "da zero";
- verifica le informazioni con l'agente `ricercatore`: una domanda per agente, con libreria e versione; le domande indipendenti lanciale insieme. Riporta i link che restituisce e, se una risposta è `NON VERIFICATO`, dillo all'utente così com'è;
- indica la tua raccomandazione;
- **aspetta la scelta dell'utente** prima di proseguire.

## Passo 2: i passi

Scomponi il lavoro in **fette verticali**: ogni passo aggiunge un pezzo di comportamento che funziona dall'inizio alla fine e si può verificare, invece di costruire un livello del programma alla volta (prima tutto il database, poi tutta la logica, poi tutta la grafica).

Per ogni passo scrivi:

```markdown
### Passo N – <titolo>
- Strato: <numero e titolo dello strato, passo 3>
- Cosa: <il comportamento che aggiunge, in una o due righe>
- Criteri coperti: <numeri dei criteri di accettazione della spec>
- Verifica: <i comportamenti da provare con i test e da quale punto di test della spec>
- Dipende da: <passi precedenti, se ci sono>
```

Regole per la verifica:

- Per una **correzione di bug**, il primo passo è un test che riproduce il bug.
- I test passano solo dai punti di test della spec. Se un comportamento non si può osservare da lì, la spec ha un buco: fermati e dillo all'utente.
- Se un passo non ha un comportamento da osservare con un test (installare una libreria, creare un file di configurazione), la verifica è il **comando** che prova che è fatto, con il risultato atteso.

Tieni i passi piccoli: un passo che richiede più di un'ora di lavoro umano va spezzato.

## Passo 3: gli strati

Uno **strato** è un gruppo di passi consecutivi con un **solo scopo**, che arriva all'utente come una pull request a sé, da rileggere e unire (sezione 9 della skill `archivio`). Gli strati sono impilati: ognuno parte da quello sotto.

Regole:

- Un solo scopo per strato, descrivibile in una riga senza "e" (per esempio "Modello dati delle prenotazioni", "Pagina di esportazione").
- Circa **300 righe** di modifiche per strato, test compresi: stimale per ogni passo. Se un solo passo supera da solo questa misura, spezza il passo.
- Una funzione piccola è **un solo strato**: non dividere per forza.
- Ogni strato, unito da solo sopra quelli sotto, lascia il progetto funzionante e i test verdi.
- Un passo dipende solo da passi del suo strato o di strati sotto.

Per ogni strato scrivi:

```markdown
## Strato N – <titolo>
- Scopo: <uno solo, in una riga>
- Ramo: <ramo>
- Base: <ramo principale per il primo strato, altrimenti il ramo dello strato N-1>
- Dimensione stimata: circa <righe> righe
- Passi: <numeri>
```

I rami, con la regola della sezione 9 della skill `archivio`:

- **Consegna GitHub**: il primo strato `feature/<nome-breve>` (per un bug `fix/<nome-breve>`), i successivi con lo stesso prefisso e `-<n>` in fondo, con `<n>` da 2 in su, dal basso verso l'alto.
- **Consegna git locale**: tutti gli strati sullo stesso ramo `feature/<nome-breve>` (o `fix/<nome-breve>`), uno dopo l'altro; gli strati servono comunque a rileggere il lavoro un pezzo alla volta.
- **Senza git**: niente ramo né base; gli strati restano come gruppi da rileggere.

La dimensione è una stima: se durante l'implementazione uno strato cresce troppo, `implementa` lo divide e lo dice.

## Passo 4: preparazione del worktree

Il codice si scriverà in un **worktree**, una seconda cartella del progetto che parte dall'ultima versione salvata (sezione 8 della skill `archivio`). Lì mancano le dipendenze installate e i file che non sono nel repo: il piano dice come prepararla. Senza git questa sezione non serve.

1. **Installazione delle dipendenze.** Deducila dal file che blocca le versioni (per esempio `package-lock.json`, `pnpm-lock.yaml`, `uv.lock`, `poetry.lock`) e dal README. Preferisci il comando che installa esattamente le versioni bloccate (`npm ci`, `pnpm install --frozen-lockfile`, `uv sync`). Se il progetto non ha dipendenze, scrivi "nessuna".
2. **File locali da copiare.** Nella cartella principale lancia `git ls-files --others --ignored --exclude-standard --directory`: elenca ciò che esiste ma non è nel repo. Scegli solo i file di configurazione che servono per far girare il programma o i test (per esempio `.env`, `config.local.json`); scarta dipendenze, build e cache. Leggi solo i **nomi**: non aprire i file con segreti e non riportarne il contenuto. Se non sei sicuro che un file serva, chiedilo all'utente nell'approvazione.
3. **Comando di test**, dal passo 1.

```markdown
## Preparazione del worktree
- Dipendenze: `<comando>` | nessuna
- File locali da copiare: `<file>`, … | nessuno
- Comando di test: `<comando>`
```

## Passo 5: revisione del piano

Prima di mostrarlo, ricontrolla il piano come farebbe un revisore esigente:

- [ ] **Ogni** criterio di accettazione è coperto da almeno un passo.
- [ ] L'ordine rispetta le dipendenze; nessun passo usa qualcosa che non esiste ancora, né qualcosa di uno strato sopra il suo.
- [ ] Ogni passo ha una verifica concreta: comportamenti da provare dai punti di test, oppure un comando con il risultato atteso.
- [ ] Ogni strato ha un solo scopo, circa 300 righe stimate, e lascia i test verdi da solo.
- [ ] La preparazione del worktree è completa: dipendenze, file locali, comando di test.
- [ ] I rischi sono scritti: dati esistenti da migrare, parti delicate del codice, servizi esterni, sicurezza.
- [ ] Niente passi fuori dal perimetro della spec.

Correggi quello che non va. Per piani con più di 8 passi, fai fare questa revisione a un sotto-agente che non ha scritto il piano.

## Passo 6: approvazione e salvataggio

1. Mostra all'utente: lo stack, gli strati con i loro passi, la preparazione del worktree, i rischi. Spiega in parole semplici cosa vedrà: ogni strato arriverà come una pull request a sé, da rileggere e unire partendo dalla prima. Chiedi l'approvazione e applica le correzioni.
2. Dopo l'approvazione salva:
   - **Issues**: per ogni passo crea una sotto-issue della spec (`--parent <spec>`, etichetta `wf:passo`, titolo `Passo N – <titolo>`), con `--blocked-by` sui passi da cui dipende. Il corpo dell'issue è il blocco `### Passo N` completo. Poi aggiungi alla spec un commento che inizia con la riga `## Piano` e contiene lo stack, la sezione `## Preparazione del worktree`, i rischi e i blocchi `## Strato N`, dove i passi sono indicati per titolo e numero di issue. Se il piano viene rifatto, scrivi un nuovo commento: vale l'ultimo che inizia con `## Piano`.
   - **File o Locale**: `<cartella>/piani/<nome-breve>.md`, con prima riga `Stato: aperto`, poi lo stack, la sezione `## Preparazione del worktree`, i rischi e, per ogni strato, il blocco `## Strato N` seguito dai suoi passi come checklist `- [ ] Passo N – <titolo>`, ciascuno con i suoi dettagli.
3. Chiudi:
   - **Se sei stata richiamata da `workflow`**: restituisci il riferimento al piano e termina senza proporre comandi.
   - **Altrimenti**: proponi il passo successivo, `/implementa <nome-breve>`.
