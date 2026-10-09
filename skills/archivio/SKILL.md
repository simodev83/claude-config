---
name: archivio
description: Regole condivise su dove salvare requisiti, mappe, spec e piani del workflow (GitHub Issues, file in docs/workflow o cartella locale non condivisa), su come aprire e chiudere il worktree di lavoro, impilare gli strati con gh stack, usare gh e git in modo sicuro e consegnare il lavoro con pull request. Caricala quando una delle skill requisiti, spec, piano, implementa, tdd o workflow te lo chiede; non serve in nessun altro caso.
user-invocable: false
---

# Archivio del workflow

Le skill del workflow (`requisiti`, `spec`, `piano`, `implementa`, `tdd`, `workflow`) salvano quello che producono in un **archivio**, di tre tipi:

- **Issues**: GitHub Issues del repo del progetto, visibili a chi vede il repo.
- **File**: file Markdown nella cartella `docs/workflow/` del progetto, salvati nel repo con commit.
- **Locale**: file Markdown nella cartella `.claude/specs/` del progetto, **mai** salvati nel repo: restano solo su questo computer. Serve per i repo di lavoro, dove i documenti del workflow non devono finire sotto gli occhi del team.

Lo stesso controllo decide anche la **consegna** del codice:

- **GitHub**: worktree, uno o più strati, una pull request per strato.
- **Git locale**: worktree con un solo ramo, niente push né pull request.
- **Senza git**: si lavora direttamente sui file.

| Archivio | Consegna possibile |
|---|---|
| Issues | GitHub |
| Locale | GitHub, git locale, senza git |
| File | git locale, senza git |

Archivio e consegna si scelgono **una volta all'inizio di ogni skill**, con il controllo qui sotto, e non cambiano durante la skill.

## 1. Controllo iniziale

Leggi sempre il testo degli errori: dice quale caso si è verificato.

1. **Scelte fissate nel progetto.** Cerca queste righe nei file `CLAUDE.md`, `.claude/CLAUDE.md` e `CLAUDE.local.md` alla radice del progetto:
   - `Archivio workflow: issues`, `Archivio workflow: file` oppure `Archivio workflow: locale`;
   - `Git workflow: no` (l'utente ha già rifiutato di usare git in questo progetto: non chiederlo di nuovo).
2. **C'è git?** `git rev-parse --is-inside-work-tree`
   - Errore → consegna **senza git** (sezione 7). Archivio **Locale** se il `CLAUDE.md` lo chiede, altrimenti **File**. Se il `CLAUDE.md` chiedeva `issues`, **fermati** e spiega che il progetto non è un repo git.
   - Se il `CLAUDE.md` dice `Archivio workflow: file` → archivio **File**, consegna **git locale**; salta i passi da 3 a 6.
3. **Il progetto è su GitHub?** `git remote -v`
   - Se un remote punta a `github.com` → è su GitHub.
   - Altrimenti, se `gh --version` funziona, lancia `gh auth status`: se l'host di un remote compare lì (GitHub Enterprise) → è su GitHub.
   - Altrimenti → consegna **git locale**; archivio **Locale** se il `CLAUDE.md` lo chiede, altrimenti **File**; salta i passi da 4 a 6. Se il `CLAUDE.md` chiedeva `issues`, invece **fermati** e spiega che non c'è un remote GitHub.
4. **C'è gh?** `gh --version`
   - Comando non trovato → **FERMATI**. Di' all'utente: il progetto è su GitHub ma `gh` non è installato; installalo seguendo la guida di installazione e riprova.
   - Versione inferiore a 2.101 → **FERMATI** e chiedi di aggiornarlo: le opzioni `--parent` e `--blocked-by` servono alle skill.
5. **L'account attivo ha accesso?**
   - `gh repo view --json nameWithOwner,hasIssuesEnabled,viewerPermission,defaultBranchRef,isInOrganization`
   - `gh api user --jq .login`
   - Se `gh repo view` dà errore, distingui dal testo:
     - "not logged in" / "authentication" → **FERMATI**: chiedi di lanciare `gh auth login`.
     - "no default remote repository" / "set-default" (capita con più remote, per esempio un fork) → **FERMATI**: chiedi di lanciare `gh repo set-default` e scegliere il repo giusto.
     - "Could not resolve" / "not found" / "404" → **FERMATI**: "L'account GitHub attivo è `<login>` e non vede questo repo. Probabilmente serve l'altro account: lancia `gh auth switch` e riprova."
     - qualsiasi altro errore → **FERMATI** e riporta il testo dell'errore all'utente.
   - Se `viewerPermission` non è `WRITE`, `MAINTAIN` o `ADMIN` → **FERMATI**: "L'account attivo `<login>` non ha permesso di scrittura su questo repo (permesso: `<valore>`). Serve un account con scrittura: lancia `gh auth switch` e riprova."
   - In tutti questi casi **non ripiegare su un altro archivio**: i documenti del progetto finirebbero divisi in due posti.
   - Tutto a posto → consegna **GitHub**.
6. **Quale archivio?**
   - Il `CLAUDE.md` dice `locale` → archivio **Locale**.
   - Il `CLAUDE.md` dice `issues` → archivio **Issues**.
   - Il `CLAUDE.md` non dice nulla e `isInOrganization` è `true` → **chiedi** all'utente, in parole semplici: il repo appartiene a un'organizzazione, quindi le Issues le vedrebbe tutto il team; in alternativa i documenti possono restare solo su questo computer (Locale). Scrivi la risposta come riga `Archivio workflow: <scelta>` in `CLAUDE.local.md`, che è il file personale del progetto, e se `git check-ignore -q CLAUDE.local.md` fallisce aggiungi `/CLAUDE.local.md` alle esclusioni locali (sezione 5). Se però `git ls-files CLAUDE.local.md` stampa qualcosa, il file è già condiviso nel repo: chiedi all'utente dove scrivere la riga.
   - Altrimenti → archivio **Issues**.
   - Con archivio **Issues**, se `hasIssuesEnabled` è `false` → **FERMATI** e chiedi all'utente se preferisce attivare le Issues nel repo oppure usare l'archivio Locale (in quel caso suggerisci di aggiungere `Archivio workflow: locale` al `CLAUDE.local.md`).
7. **Strumenti per la consegna** (solo per le skill che consegnano codice, `implementa` e `tdd`, e solo con consegna GitHub):
   - `jq --version` → se manca, **FERMATI** e chiedi di installarlo con `sudo apt install jq`.
   - `gh stack --version` → se manca, **FERMATI** e chiedi di installarlo con `gh extension install github/gh-stack`.

Prima di scrivere qualsiasi cosa mostra all'utente una riga:

- consegna GitHub: `Archivio: <GitHub Issues | cartella locale .claude/specs/> · Consegna: pull request · Account: <login> · Repo: <nameWithOwner>`;
- altrimenti: `Archivio: <file in docs/workflow/ | cartella locale .claude/specs/> · Consegna: <ramo locale | senza git> (motivo: <nessun git | nessun remote GitHub | scelto nel CLAUDE.md>)`.

**Ramo principale.**

- Consegna GitHub: `defaultBranchRef.name`.
- Consegna git locale: `main` se esiste, altrimenti `master`; se non esiste nessuno dei due, chiedi all'utente. Un ramo che inizia con `feature/`, `fix/` o `proto/` non è mai il ramo principale.
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

**Testi lunghi.** Non mettere mai testi lunghi direttamente nella riga di comando: virgolette e a capo si rompono. Usa un file:

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

Relazioni tra issue. Scrivi il percorso tra virgolette doppie, così com'è: `gh api` sostituisce da solo `{owner}` e `{repo}` con il repo corrente.

```
gh api "repos/{owner}/{repo}/issues/<numero>/sub_issues" --paginate --jq ".[] | {number, title, state}"
gh api "repos/{owner}/{repo}/issues/<numero>/dependencies/blocked_by" --paginate --jq ".[] | {number, state}"
```

La prima elenca le sotto-issue di una madre, la seconda da quali issue è bloccata.

**Riferimenti.** Nei testi che l'utente legge, chiama le issue per **titolo** con il numero tra parentesi ("Spec – Export CSV (#12)"), mai solo "#12".

## 4. Documenti in modalità File e Locale

La struttura è la stessa; cambia solo la cartella di partenza, `<cartella>`: `docs/workflow/` per File, `.claude/specs/` per Locale.

```
<cartella>
├── requisiti-<tema>.md
├── mappa-<tema>.md          ← modalità mappa: indice
├── decisioni/<tema>/NN-<titolo>.md
├── spec/<nome-breve>.md
└── piani/<nome-breve>.md    ← i passi sono una checklist "- [ ]"
```

Ogni file inizia con una riga `Stato: aperto | chiuso | implementato | implementato sul ramo <ramo>` e, se serve, `Bloccato da: <file>`. I nomi dei file sono in minuscolo, senza accenti, con trattini al posto degli spazi.

**File con git: commit dei documenti.** I documenti condivisi e quelli di una singola funzione vanno su rami diversi, così nessun documento sparisce cambiando ramo:

- **Requisiti, mappa e decisioni** servono a tutte le funzioni: vanno sul **ramo principale**. Dopo averli salvati, se sei sul ramo principale, fai il commit indicando i percorsi esatti, per esempio `git add docs/workflow/requisiti-<tema>.md` e poi `git commit -m "Requisiti: <tema>"`. Se non sei sul ramo principale, lascia i file senza commit e avvisa l'utente.
- **Spec e piano** di una funzione si salvano senza commit nella cartella principale del progetto. Quando si apre il worktree vengono spostati dentro ed entrano nel suo primo commit (sezione 8).

**Locale.** Prima di scrivere il primo documento, se il progetto usa git:

1. `git ls-files .claude/specs` deve stampare niente: se stampa qualcosa, la cartella è già condivisa nel repo; **fermati** e chiedi all'utente.
2. Aggiungi `/.claude/specs/` alle esclusioni locali (sezione 5).

I documenti Locale non si spostano mai, non si aggiungono mai con `git add` e restano nella cartella principale del progetto anche mentre si lavora nel worktree: chi lavora nel worktree li legge con il **percorso assoluto** `<radice>/.claude/specs/...` (sezione 8).

## 5. Esclusioni locali

Le cartelle e i file che non devono mai finire nel repo, ma che riguardano solo questo computer, si escludono nel file di esclusione **locale** di git, non nel `.gitignore` (che è condiviso con il team).

1. Il file è quello stampato da `git rev-parse --git-path info/exclude`; è lo stesso per la cartella principale e per tutti i worktree.
2. Per ogni riga da aggiungere, controlla prima se c'è già con `grep -qxF "<riga>" "<file>"`; aggiungila in fondo solo se manca.

| Riga | Quando |
|---|---|
| `/.claude/worktrees/` | Prima di aprire il primo worktree (sezione 8) |
| `/.claude/specs/` | Archivio Locale, prima del primo documento (sezione 4) |
| `/CLAUDE.local.md` | Quando ci scrivi la scelta dell'archivio e il file non è già ignorato (sezione 1) |

## 6. Nome breve

Ogni funzione ha un **nome breve**, deciso nella spec: minuscolo, senza accenti, con trattini al posto degli spazi (per esempio `export-csv`). È lo stesso nei file, nei rami, nel worktree (`.claude/worktrees/export-csv`) e nelle ricerche. Se l'utente scrive il nome della funzione in un altro modo ("Export CSV"), cerca la spec corrispondente e usa il suo nome breve.

## 7. Progetto senza git

Se manca la riga `Git workflow: no`, chiedi all'utente se vuole inizializzare git.

- Se dice di sì:
  1. `git init`.
  2. Crea o controlla un `.gitignore` adatto allo stack: almeno file di segreti (`.env`, chiavi), dipendenze (`node_modules/`, `venv/`) e cartelle di build.
  3. Con archivio Locale, aggiungi subito `/.claude/specs/` alle esclusioni locali (sezione 5).
  4. `git status` e mostra all'utente l'elenco dei file che verranno salvati; se c'è qualcosa di sospetto (password, dati personali, file enormi), chiedi prima.
  5. `git add -A` e `git commit -m "Stato iniziale"`, **prima** di creare qualsiasi ramo o worktree (senza un primo commit i confronti tra rami non funzionano).
  6. Da qui la consegna è **git locale**.
- Se dice di no: proponi di aggiungere `Git workflow: no` al `CLAUDE.md`, così non verrà richiesto di nuovo. Niente worktree, rami né commit: si lavora direttamente sui file e, a fine lavoro, gli ricordi che non c'è una versione precedente a cui tornare.

## 8. Worktree

Un **worktree** è una seconda cartella dello stesso progetto, con un suo ramo: il codice nuovo si scrive lì, mentre la cartella principale resta com'era. Lo usano le skill che scrivono codice (`implementa`, `tdd`) con consegna GitHub o git locale; senza git non c'è worktree.

- `<radice>`: la cartella principale del progetto, cioè la cartella che contiene la cartella stampata da `git rev-parse --path-format=absolute --git-common-dir` (funziona anche se sei già in un worktree).
- `<percorso>`: `<radice>/.claude/worktrees/<nome-breve>`.
- Un solo worktree per funzione: tutti gli strati vivono nello stesso worktree, uno dopo l'altro.

### Apertura

1. **Esiste già?** Se `git worktree list` mostra `<percorso>`, il lavoro è già iniziato: entra con lo strumento `EnterWorktree` passando `path: "<percorso>"` e salta al passo 9. Non crearne mai un secondo.
2. **Modifiche non salvate.** Nella `<radice>` lancia `git status --porcelain`. Escludi dall'elenco solo spec e piano di questa funzione in modalità File. Se resta qualcosa, **fermati** e spiega all'utente in parole semplici: il lavoro partirà dall'ultima versione salvata del progetto e non conterrà queste modifiche. Chiedi se proseguire così o fermarsi perché le salvi lui. Non metterle mai da parte, non annullarle e non farne il commit tu.
3. **Esclusione.** Aggiungi `/.claude/worktrees/` alle esclusioni locali (sezione 5).
4. **Ramo.** È il ramo del primo strato, preso dal piano (sezione 9). Se `git rev-parse --verify --quiet "refs/heads/<ramo>"` lo trova già, **fermati** e chiedi all'utente se è lavoro vecchio da riprendere o da lasciare stare: non riusarlo e non cancellarlo da solo.
5. **Creazione.**
   - Consegna GitHub: `git fetch origin`, poi `git worktree add -b <ramo> "<percorso>" origin/<principale>`.
   - Consegna git locale: `git worktree add -b <ramo> "<percorso>" <principale>`.
6. **Ingresso.** Strumento `EnterWorktree` con `path: "<percorso>"`. Da qui ogni file del progetto si scrive nel worktree, mai nella `<radice>`; l'unica eccezione sono i documenti dell'archivio Locale.
7. **Documenti (solo File).** Sposta spec e piano dalla `<radice>` al worktree, allo stesso percorso relativo: `mkdir -p` delle cartelle, poi `mv "<radice>/docs/workflow/spec/<nome-breve>.md" "<percorso>/docs/workflow/spec/<nome-breve>.md"` e lo stesso per il piano. Poi, nel worktree, il primo commit con i percorsi esatti: `git add docs/workflow/spec/<nome-breve>.md docs/workflow/piani/<nome-breve>.md` e `git commit -m "Documenti: <nome-breve>"`.
8. **File locali e dipendenze**, dalla sezione del piano che li elenca:
   - per ogni file locale da copiare (per esempio `.env`): se manca nella `<radice>`, **fermati** e chiedi. Se nel worktree `git check-ignore -q <file>` fallisce, il file finirebbe nel repo: **fermati** e avvisa l'utente. Altrimenti `cp "<radice>/<file>" "<percorso>/<file>"`;
   - lancia nel worktree il comando di installazione delle dipendenze; se fallisce, **fermati** e riporta l'errore.
9. **Verifica di partenza.** Lancia nel worktree il comando di test del piano. Se i test falliscono prima di qualsiasi modifica, **fermati**: spiega all'utente che il problema c'era già e chiedi come procedere. Se lo strumento di test non è ancora installato perché lo installa il primo passo del piano, dillo e prosegui.

### Chiusura

Si chiude il worktree solo quando il lavoro è unito al ramo principale, oppure quando l'utente chiede di abbandonarlo.

1. **Controllo.**
   - Consegna GitHub: per ogni ramo, `gh pr view <ramo> --json state --jq .state` deve dare `MERGED`.
   - Consegna git locale: `git branch --merged <principale>` deve elencare il ramo.
   - Se non è così e l'utente non ha chiesto di abbandonare il lavoro, **fermati** e dillo.
   - Se l'utente ha chiesto di abbandonarlo, mostragli i commit che andrebbero persi (`git log --oneline <principale>..<ramo in cima>`) e chiedi una conferma esplicita prima di proseguire.
2. `git -C "<percorso>" status --porcelain` deve stampare niente; altrimenti **fermati** e mostra all'utente cosa resterebbe perso.
3. Se il lavoro aveva più strati, lancia nel worktree `gh stack unstack --local`: toglie solo il ricordo locale della pila e non tocca GitHub.
4. Se la sessione è nel worktree, esci con `ExitWorktree` e `action: "keep"`.
5. `git worktree remove "<percorso>"`. Mai con `--force`: se si rifiuta, **fermati** e riporta l'errore.
6. Per ogni ramo: `git branch -D <ramo>` (con `-D` perché un merge "squash" non risulta unito per git; il passo 1 garantisce che il lavoro è salvo o che l'utente ha confermato). Con consegna GitHub, se `git ls-remote --exit-code --heads origin <ramo>` lo trova ancora, `git push origin --delete <ramo>`.
7. Cancella i corpi delle pull request della funzione (sezione 10): `rm -r "<cartella comune>/wf/<nome-breve>"`.
8. Con consegna GitHub, se la `<radice>` è sul ramo principale e senza modifiche, aggiornala con `git -C "<radice>" pull --ff-only`.

## 9. Strati

Uno **strato** è un pezzo del lavoro con un solo scopo, abbastanza piccolo da rileggere in una volta (circa 300 righe): ha un suo ramo e, con consegna GitHub, una sua pull request. Gli strati sono **impilati**: ognuno parte da quello sotto, il primo dal ramo principale. Chi rivede le pull request vede solo le modifiche di uno strato alla volta.

**Nomi dei rami.** Li fissa il piano: il primo strato è `feature/<nome-breve>` (per un bug `fix/<nome-breve>`), i successivi `feature/<nome-breve>-<n>` con `<n>` da 2 in su, dal basso verso l'alto.

**Consegna git locale.** Niente pila: tutti gli strati diventano commit successivi sull'unico ramo del worktree.

**Consegna GitHub, uno strato.** Il ramo del worktree è lo strato: `gh stack` non serve.

**Consegna GitHub, più strati.** La pila si gestisce con `gh stack`. Tutti i comandi vanno lanciati in modo **non interattivo**, altrimenti restano bloccati in attesa di una risposta:

- passa sempre il nome del ramo come argomento a `init`, `add` e `checkout`;
- usa `gh stack view` sempre con `--json`;
- non usare mai `gh stack submit` (crea pull request in bozza), `gh stack modify`, `gh stack switch` né `gh stack merge`.

| Operazione | Comandi |
|---|---|
| Preparazione, una volta per repo | `git config rerere.enabled true`; se `git remote` elenca più di un remote, anche `git config remote.pushDefault origin` |
| Aprire il secondo strato | sul primo strato finito: `gh stack init --base <principale> <ramo-1>` (adotta il ramo del worktree), poi `gh stack add <ramo-2>` |
| Aprire uno strato successivo | sullo strato in cima, finito: `gh stack add <ramo-n>` |
| Muoversi | `gh stack up`, `gh stack down`, `gh stack top`, `gh stack bottom`, `gh stack checkout <ramo>` |
| Correggere uno strato sotto | `gh stack checkout <ramo>`, correzione e commit, poi `gh stack rebase --upstack --no-trunk` |
| Stato della pila | `gh stack view --json` |

**Dopo una correzione** su uno strato sotto, fai girare tutti i test su quello strato e su ogni strato sopra (`gh stack up` da uno all'altro), poi torna in cima con `gh stack top`.

**Conflitti.** Se `gh stack rebase` termina con codice 3, c'è un conflitto: leggi nel messaggio i file in conflitto, risolvi i segni `<<<<<<<`, `=======`, `>>>>>>>`, aggiungi i file con `git add <file>` e lancia `gh stack rebase --continue`. Se non riesci a risolverlo con certezza, `gh stack rebase --abort` (riporta tutti i rami a prima) e **fermati**.

## 10. Consegna del lavoro

Usata da `implementa` e da `tdd`. Prerequisito: il lavoro è su rami **diversi** dal ramo principale, con tutti i test verdi su ogni strato. Se il lavoro è sul ramo principale, **non** aprire pull request: spiega all'utente la situazione e chiedi come procedere.

**Corpi delle pull request.** Uno per strato, scritto con lo strumento Write in `<cartella comune>/wf/<nome-breve>/pr-<n>.md`, dove `<cartella comune>` è quella stampata da `git rev-parse --path-format=absolute --git-common-dir` e `<n>` è il numero dello strato. La struttura la dà la skill che consegna. Se la scrittura fallisce, non lanciare il comando `gh`.

**Consegna GitHub, uno strato:**

1. `git push -u origin <ramo>`. Se il push viene rifiutato, fermati e riporta l'errore.
2. `gh pr create --base <principale> --head <ramo> --title "<titolo>" --body-file "<corpo>"`

**Consegna GitHub, più strati:**

1. `gh stack push`: pubblica tutti i rami della pila.
2. Per ogni strato, dal basso verso l'alto: `gh pr create --head <ramo> --base <ramo dello strato sotto, o <principale> per il primo> --title "<titolo>" --body-file "<corpo>"`.
3. `gh stack link <ramo-1> <ramo-2> … <ramo-n>`: raggruppa su GitHub le pull request già create, senza crearne altre.
   - Se termina con codice 9, il repo non ha le pile di pull request attive: le pull request esistono comunque, ognuna basata su quella sotto. Dillo all'utente: vanno rilette e unite dal basso verso l'alto. Non cambiare tu le impostazioni del repo.
4. Verifica con `gh stack view --json` che ogni ramo abbia la sua pull request aperta.

**In entrambi i casi:**

- Se un ramo ha già una pull request aperta (`gh pr view <ramo> --json state`), non crearne una seconda.
- **Mai in bozza**: niente `--draft`. Una pull request consegnata è pronta da rileggere.
- **Non unire mai le pull request** (né `gh pr merge` né `gh stack merge`): il merge lo fa l'utente.
- Dopo il merge il worktree si chiude come nella sezione 8.

**Consegna git locale:** niente push né pull request. Spiega all'utente come unire il ramo quando è soddisfatto: nella cartella principale del progetto, `git switch <principale>` e poi `git merge <ramo>`. Poi può chiedere a Claude di chiudere il worktree (sezione 8).

**Senza git:** elenca i file modificati.

## 11. Regole di sicurezza

- Non usare mai `git push --force`, `git reset --hard`, `git clean`, `git stash`, `git worktree remove --force` o comandi che cancellano lavoro, salvo richiesta esplicita dell'utente. L'unica pubblicazione che riscrive i rami è `gh stack push` dopo un `gh stack rebase`: tocca solo i rami della pila e si ferma se qualcun altro li ha cambiati.
- Non toccare le modifiche non salvate dell'utente nella cartella principale: niente commit, stash o annullamenti.
- Non mettere mai nel `.gitignore` le esclusioni che riguardano solo questo computer: vanno nelle esclusioni locali (sezione 5).
- Non fare mai merge di una pull request: il merge lo fa l'utente.
- Non modificare impostazioni del repo (rami protetti, permessi, attivazione Issues, pile di pull request) senza richiesta esplicita.
- Se un comando `gh` fallisce per permessi o autenticazione, fermati e riporta l'errore: non cercare strade alternative.
