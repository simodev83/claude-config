---
name: archivio
description: Regole condivise su dove salvare requisiti, mappe, spec e piani del workflow (GitHub Issues o file in docs/workflow), su come usare gh e git in modo sicuro e su come consegnare il lavoro con una pull request. Caricala quando una delle skill requisiti, spec, piano, implementa, tdd o workflow te lo chiede; non serve in nessun altro caso.
user-invocable: false
---

# Archivio del workflow

Le skill del workflow (`requisiti`, `spec`, `piano`, `implementa`, `tdd`, `workflow`) salvano quello che producono in un **archivio**. L'archivio è di due tipi:

- **Issues**: GitHub Issues del repo del progetto.
- **File**: file Markdown nella cartella `docs/workflow/` del progetto.

Il tipo si sceglie **una volta all'inizio di ogni skill**, con il controllo qui sotto, e non cambia durante la skill.

## 1. Controllo iniziale (esegui i comandi uno alla volta)

Esegui ogni comando in una chiamata separata: non concatenarli con `&&`, perché su Windows PowerShell 5.1 non funziona. Leggi sempre il testo degli errori: dice quale caso si è verificato.

1. **Scelte fissate nel progetto.** Cerca queste righe nei file `CLAUDE.md`, `.claude/CLAUDE.md` e `CLAUDE.local.md` alla radice del progetto:
   - `Archivio workflow: file` oppure `Archivio workflow: issues`;
   - `Git workflow: no` (l'utente ha già rifiutato di usare git in questo progetto: non chiederlo di nuovo).
2. **C'è git?** `git rev-parse --is-inside-work-tree`
   - Errore → archivio **File**, progetto **senza git** (vedi sezione 5). Se il `CLAUDE.md` chiedeva `issues`, **fermati** e spiega che il progetto non è un repo git.
   - Se il `CLAUDE.md` dice `Archivio workflow: file` → archivio **File**, progetto **con git**; salta i passi da 3 a 6.
3. **Il progetto è su GitHub?** `git remote -v`
   - Se un remote punta a `github.com` → è su GitHub.
   - Altrimenti, se `gh --version` funziona, lancia `gh auth status`: se l'host di un remote compare lì (GitHub Enterprise) → è su GitHub.
   - Altrimenti → archivio **File**, progetto **con git locale**; salta i passi da 4 a 6. Se il `CLAUDE.md` chiedeva `issues`, invece **fermati** e spiega che non c'è un remote GitHub.
4. **C'è gh?** `gh --version`
   - Comando non trovato → **FERMATI**. Di' all'utente: il progetto è su GitHub ma `gh` non è installato; installalo seguendo la guida di installazione e riprova.
   - Versione inferiore a 2.101 → **FERMATI** e chiedi di aggiornarlo: le opzioni `--parent` e `--blocked-by` servono alle skill.
5. **L'account attivo ha accesso?**
   - `gh repo view --json nameWithOwner,hasIssuesEnabled,viewerPermission,defaultBranchRef`
   - `gh api user --jq .login`
   - Se `gh repo view` dà errore, distingui dal testo:
     - "not logged in" / "authentication" → **FERMATI**: chiedi di lanciare `gh auth login`.
     - "no default remote repository" / "set-default" (capita con più remote, per esempio un fork) → **FERMATI**: chiedi di lanciare `gh repo set-default` e scegliere il repo giusto.
     - "Could not resolve" / "not found" / "404" → **FERMATI**: "L'account GitHub attivo è `<login>` e non vede questo repo. Probabilmente serve l'altro account: lancia `gh auth switch` e riprova."
     - qualsiasi altro errore → **FERMATI** e riporta il testo dell'errore all'utente.
   - Se `viewerPermission` non è `WRITE`, `MAINTAIN` o `ADMIN` → **FERMATI**: "L'account attivo `<login>` non ha permesso di scrittura su questo repo (permesso: `<valore>`). Serve un account con scrittura: lancia `gh auth switch` e riprova."
   - In tutti questi casi **non ripiegare sui file**: i documenti del progetto finirebbero divisi in due posti.
   - Se `hasIssuesEnabled` è `false` → **FERMATI** e chiedi all'utente se preferisce attivare le Issues nel repo oppure usare i file per questo progetto (in quel caso suggerisci di aggiungere `Archivio workflow: file` al `CLAUDE.md`).
6. **Tutto a posto** → archivio **Issues**. Prima di scrivere qualsiasi cosa mostra all'utente una riga: `Archivio: GitHub Issues · Account: <login> · Repo: <nameWithOwner>`.

In modalità File mostra invece: `Archivio: file in docs/workflow/ (motivo: <nessun git | nessun remote GitHub | scelto nel CLAUDE.md>)`.

**Ramo principale.**

- Modalità Issues: `defaultBranchRef.name`.
- Modalità File con git: `main` se esiste, altrimenti `master`; se non esiste nessuno dei due, chiedi all'utente. Un ramo che inizia con `feature/`, `fix/` o `proto/` non è mai il ramo principale.
- Controlla il ramo attuale con `git branch --show-current`.

## 2. Etichette (solo Issues)

Tutte le etichette del workflow hanno il prefisso `wf:` per non confondersi con quelle del team. Prima di creare la prima issue di una skill, crea (o aggiorna) quelle che userai; `--force` le aggiorna se esistono già:

```
gh label create "wf:requisiti" --color 5319E7 --description "Workflow: requisiti" --force
gh label create "wf:mappa" --color 0E8A16 --description "Workflow: mappa di un lavoro grande" --force
gh label create "wf:decisione" --color FBCA04 --description "Workflow: decisione da risolvere" --force
gh label create "wf:spec" --color 1D76DB --description "Workflow: specifica di una funzione" --force
gh label create "wf:passo" --color C5DEF5 --description "Workflow: passo del piano" --force
```

## 3. Operazioni con le Issues

**Testi lunghi.** Non mettere mai testi lunghi direttamente nella riga di comando: virgolette e a capo si rompono in modo diverso tra bash e PowerShell. Usa un file:

1. Una volta per skill, trova la cartella interna di git: `git rev-parse --absolute-git-dir`. Il file del corpo è `<quella cartella>/wf-corpo.md`, con il **percorso assoluto** (funziona anche nei worktree, e non viene mai committato).
2. Scrivi il testo in quel file con lo strumento Write (sovrascrive tutto il contenuto).
3. Se la scrittura fallisce, **non** eseguire il comando `gh`: pubblicheresti il testo precedente.
4. Passa il file con `--body-file "<percorso assoluto>"`.

Nella tabella, `<corpo>` è quel percorso assoluto.

| Operazione | Comando |
|---|---|
| Creare un'issue | `gh issue create --title "<titolo>" --label "<etichetta>" --body-file "<corpo>"` |
| Creare una sotto-issue | aggiungi `--parent <numero-madre>` |
| Dipendenza "bloccata da" | aggiungi `--blocked-by <numero>`; per più numeri prova `--blocked-by 3,5` e, se viene rifiutato, ripeti l'opzione per ogni numero |
| Leggere un'issue | `gh issue view <numero> --comments` |
| Modificare il corpo | `gh issue edit <numero> --body-file "<corpo>"` |
| Commentare | `gh issue comment <numero> --body-file "<corpo>"` |
| Chiudere | `gh issue close <numero> --comment "<motivo breve>"` |
| Cercare per etichetta | `gh issue list --label "wf:spec" --state all --search "<parole>"` |
| Pull request aperte | `gh pr list --state open --search "<parole>"` |

Relazioni tra issue. Scrivi il percorso tra virgolette doppie, così com'è: `gh api` sostituisce da solo `{owner}` e `{repo}` con il repo corrente, e le virgolette servono a PowerShell.

```
gh api "repos/{owner}/{repo}/issues/<numero>/sub_issues" --paginate --jq ".[] | {number, title, state}"
gh api "repos/{owner}/{repo}/issues/<numero>/dependencies/blocked_by" --paginate --jq ".[] | {number, state}"
```

La prima elenca le sotto-issue di una madre, la seconda da quali issue è bloccata.

**Riferimenti.** Nei testi che l'utente legge, chiama le issue per **titolo** con il numero tra parentesi ("Spec – Export CSV (#12)"), mai solo "#12".

## 4. Struttura in modalità File

```
docs/workflow/
├── requisiti-<tema>.md
├── mappa-<tema>.md          ← modalità mappa: indice
├── decisioni/<tema>/NN-<titolo>.md
├── spec/<nome-breve>.md
└── piani/<nome-breve>.md    ← i passi sono una checklist "- [ ]"
```

Ogni file inizia con una riga `Stato: aperto | chiuso | implementato | implementato sul ramo <ramo>` e, se serve, `Bloccato da: <file>`. I nomi dei file sono in minuscolo, senza accenti, con trattini al posto degli spazi.

**Commit dei documenti (File con git).** I documenti condivisi e quelli di una singola funzione vanno su rami diversi, così nessun documento sparisce cambiando ramo:

- **Requisiti, mappa e decisioni** servono a tutte le funzioni: vanno sul **ramo principale**. Dopo averli salvati, se sei sul ramo principale, fai il commit indicando i percorsi esatti, per esempio `git add docs/workflow/requisiti-<tema>.md` e poi `git commit -m "Requisiti: <tema>"`. Se non sei sul ramo principale, lascia i file senza commit e avvisa l'utente.
- **Spec e piano** di una funzione si salvano senza commit. Entrano nel primo commit del ramo di lavoro, in `implementa`, sempre indicando i percorsi esatti (`docs/workflow/spec/<nome-breve>.md`, `docs/workflow/piani/<nome-breve>.md`), mai l'intera cartella.

## 5. Git in modalità File

- **Con git locale**: si lavora su un ramo dedicato e si fanno commit, senza push né pull request.
- **Senza git** (e senza la riga `Git workflow: no`): chiedi all'utente se vuole inizializzarlo.
  - Se dice di sì:
    1. `git init`.
    2. Crea o controlla un `.gitignore` adatto allo stack: almeno file di segreti (`.env`, chiavi), dipendenze (`node_modules/`, `venv/`) e cartelle di build.
    3. `git status` e mostra all'utente l'elenco dei file che verranno salvati; se c'è qualcosa di sospetto (password, dati personali, file enormi), chiedi prima.
    4. `git add -A` e `git commit -m "Stato iniziale"`, **prima** di creare qualsiasi ramo di lavoro (senza un primo commit i confronti tra rami non funzionano).
  - Se dice di no: proponi di aggiungere `Git workflow: no` al `CLAUDE.md`, così non verrà richiesto di nuovo. Niente rami né commit: si lavora direttamente sui file e, a fine lavoro, gli ricordi che non c'è una versione precedente a cui tornare.

## 6. Nome breve

Ogni funzione ha un **nome breve**, deciso nella spec: minuscolo, senza accenti, con trattini al posto degli spazi (per esempio `export-csv`). È lo stesso nei file, nel ramo (`feature/export-csv`) e nelle ricerche. Se l'utente scrive il nome della funzione in un altro modo ("Export CSV"), cerca la spec corrispondente e usa il suo nome breve.

## 7. Consegna del lavoro

Usata da `implementa` e da `tdd`. Prerequisito: il lavoro è su un ramo **diverso** dal ramo principale, con tutti i test verdi. Se il lavoro è sul ramo principale, **non** aprire pull request: spiega all'utente la situazione e chiedi come procedere.

**Issues:**

1. `git push -u origin HEAD`. Se il push viene rifiutato, fermati e riporta l'errore.
2. Scrivi il corpo della pull request nel file del corpo (sezione 3). La struttura la dà la skill che consegna.
3. `gh pr create --base <ramo principale> --title "<titolo>" --body-file "<corpo>"`
4. **Non unire mai la pull request.** Il merge lo fa l'utente.

**File con git:** niente push né pull request. Spiega all'utente come unire il ramo quando è soddisfatto: `git switch <ramo principale>` e poi `git merge <ramo>`.

**File senza git:** elenca i file modificati.

## 8. Regole di sicurezza

- Non usare mai `git push --force`, `git reset --hard`, `git clean` o comandi che cancellano lavoro, salvo richiesta esplicita dell'utente.
- Non fare mai merge di una pull request: il merge lo fa l'utente.
- Non modificare impostazioni del repo (rami protetti, permessi, attivazione Issues) senza richiesta esplicita.
- Se un comando `gh` fallisce per permessi o autenticazione, fermati e riporta l'errore: non cercare strade alternative.
