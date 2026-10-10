# claude-config

La mia configurazione di Claude Code: questa cartella è `~/.claude`. Contiene il regolamento globale (`CLAUDE.md`), le impostazioni, gli hook, la barra di stato e le skill personali: un workflow ingegneristico dall'idea al merge, più il TDD e due attrezzi per la manutenzione (`/rifletti` e `/cronometro`).

| Skill | Comando | Cosa fa |
|---|---|---|
| workflow | `/workflow <tema>` | Il regista: esegue requisiti → spec → piano → implementa → guardia, con approvazione dopo ogni fase di decisione |
| requisiti | `/requisiti <tema>` | Interrogatorio ad albero delle decisioni; modalità mappa per i lavori su più sessioni |
| spec | `/spec <funzione>` | Specifica con storie utente, casi limite e criteri di accettazione |
| piano | `/piano <funzione>` | Passi piccoli e verificabili raggruppati in strati, scelta dello stack, preparazione del worktree |
| implementa | `/implementa <funzione>` | Il regista della costruzione: worktree, un costruttore per passo, semplificazione e revisione per strato, collaudo finale, una pull request per strato |
| tdd | `/tdd <obiettivo>` | Ciclo rosso → verde, sempre; la usa il costruttore per ogni passo, e da sola per un bug o una piccola modifica |
| guardia | `/guardia [numero PR]` | Sorveglia le pull request fino al merge: risponde ai commenti, fa correggere, aggiorna i rami, poi chiude il worktree. Parte da sola alla consegna; `/guardia` la riprende in una nuova sessione |
| rifletti | `/rifletti [numero PR]` | Rilegge le memorie di tutti i progetti e ti propone quali diventano regole globali (nel `CLAUDE.md` o in `rules/`); apre la pull request, la guardia la segue e dopo il merge cancella le memorie superate. Va lanciata con Claude aperto in `~/.claude` |
| cronometro | `/cronometro [sessione]` | Legge il diario di un'altra sessione (per esempio un `/implementa` lungo) e pubblica una pagina con dove è andato il tempo e proposte per accorciarlo. Non tocca la sessione analizzata |
| archivio | — | Regole interne: dove salvare i documenti (GitHub Issues, `docs/workflow/` o cartella locale), worktree, strati e consegna. Non si lancia a mano |

## Agenti

Aiutanti che le skill lanciano da sole, ognuno con il suo compito e il suo modello. Stanno in `agents/`.

| Agente | Modello e impegno | Cosa fa |
|---|---|---|
| costruttore | Opus, medio | Costruisce un passo del piano in TDD, con un commit; se si blocca restituisce una domanda per l'utente |
| semplificatore | Opus, medio | Riordina il codice di uno strato senza cambiarne il comportamento, prima della revisione |
| revisore | Opus, alto | Sola lettura: revisione di uno strato, oppure collaudo finale con tabella dei criteri e verdetto |
| ricercatore | Sonnet, basso | Risponde a una domanda su una libreria leggendo solo la documentazione ufficiale, con citazione |

## Come si usa

In un progetto scrivi `/workflow <cosa vuoi costruire>`. Claude:

1. ti fa domande finché è chiaro cosa serve (requisiti) e scrive il contratto della funzione, con i criteri per dire che funziona (spec);
2. divide il lavoro in passi piccoli, raggruppati in strati: ogni strato diventerà una pull request da rileggere (piano);
3. dopo il tuo ok su questi tre documenti costruisce da solo, in una cartella a parte (worktree) che non tocca il tuo lavoro: un agente per passo, sempre con il test prima del codice, poi riordino e revisione di ogni strato e un collaudo finale criterio per criterio;
4. se il progetto è su GitHub apre le pull request e resta a sorvegliarle: risponde ai commenti e corregge finché non le unisci tu; altrimenti lascia un ramo pronto da unire.

Si ferma a chiederti qualcosa solo quando serve una tua decisione. Per un bug basta `/tdd <cosa non funziona>`.

Ogni tanto, per fare ordine:

- `/rifletti`: con il tempo Claude accumula memorie nei singoli progetti, e alcune valgono ovunque ("rispondi in italiano"). Apri il terminale, scrivi `cd ~/.claude && claude` e poi `/rifletti`: ti mostra ogni memoria con un verdetto e ti chiede quali trasformare in regole. Sceglie sempre tu, per numero.
- `/cronometro <sessione>`: quando un lavoro in un'altra finestra ci mette troppo, lancialo da una seconda sessione per capire dove va il tempo. Ricevi il link a una pagina privata.

## Cosa c'è nel repo

- `CLAUDE.md`: le regole valide in ogni progetto (lingua, account GitHub, qualità del codice, docstring e commenti).
- `rules/`: regole valide in ogni progetto che riguardano un solo strumento o momento del lavoro, un file per tema; Claude Code le carica sempre, come il `CLAUDE.md`. La crea `/rifletti` quando serve.
- `settings.json`: modello, hook e barra di stato.
- `hooks/github-account.sh`: a ogni avvio di sessione dice quale account GitHub è attivo.
- `statusline-command.sh`: la barra di stato in fondo al terminale.
- `skills/` e `agents/`: il workflow, `rifletti` e `cronometro`.

Il `.gitignore` esclude tutto tranne la configurazione elencata al suo interno. Restano sempre fuori: le credenziali, la cronologia delle conversazioni, le memorie dei progetti (`projects/`), le cache e le skill sincronizzate da claude.ai (`skills/synced/`). Per aggiungere un file o una cartella al repo va aggiunta una riga `!/<nome>` nel `.gitignore`.

## Installare su un altro computer

Su Ubuntu, o dentro WSL su Windows. Il repo è privato: serve `gh` con l'account simodev83.

### Cosa serve

- Claude Code, installato come indica la sua documentazione per Linux.
- `git`, `jq` e `timeout` (questo c'è già in Ubuntu): `sudo apt install git jq`.
- `gh` (GitHub CLI) almeno alla versione 2.101, installato seguendo la sua guida ufficiale per Ubuntu: il pacchetto `gh` di Ubuntu è troppo vecchio. Poi `gh auth login` una volta per ogni account (simodev83 e SimoneBEN324); per passare dall'uno all'altro, `gh auth switch`. Ogni account deve avere anche il permesso `workflow`, senza il quale GitHub rifiuta i commit che toccano i controlli automatici (`.github/workflows`): lancialo, per ogni account attivo, in un terminale normale e non dentro Claude, perché chiede di premere Invio e di confermare nel browser: `gh auth refresh -h github.com -s workflow`.
- L'estensione per le pull request a strati: `gh extension install github/gh-stack`.

### Su Windows, con WSL

WSL fa girare Ubuntu dentro Windows. Claude Code, gli strumenti qui sopra e i progetti vanno tutti dentro Ubuntu.

1. In PowerShell aperto come amministratore: `wsl --install -d Ubuntu`, poi riavvia il computer.
2. Apri "Ubuntu" dal menu Start, scegli nome utente e password, e installa quello che serve come qui sopra.
3. Tieni i progetti nella cartella di Ubuntu (`~/...`), non nei dischi di Windows (`/mnt/c/...`): lì tutto è molto più lento e i permessi dei file non funzionano bene.

### Scaricare la configurazione

Prima rendi attivo l'account giusto e fai usare a git l'accesso di `gh`:

```bash
gh auth switch -u simodev83
gh auth setup-git
```

Se `~/.claude` non esiste ancora:

```bash
gh repo clone simodev83/claude-config ~/.claude
```

Se `~/.claude` esiste già (Claude Code è stato aperto almeno una volta):

```bash
cd ~/.claude
git init -b main
git remote add origin https://github.com/simodev83/claude-config.git
git fetch origin
git checkout -f -t origin/main
```

`checkout -f` sovrascrive i file della configurazione con quelli del repo; credenziali e cronologia non sono nel repo e restano intatte.

Per aggiornare: `git -C ~/.claude pull`.

Le skill si modificano direttamente qui, in `~/.claude/skills`: non c'è più uno script di installazione.

## Meno richieste di permesso

Durante `/workflow` Claude richiama le altre skill e lancia comandi `git` e `gh`: Claude Code può chiederti il permesso le prime volte. Per i comandi, quando compare la richiesta scegli l'opzione che non chiede più per quel comando, ma solo per quelli di lettura o creazione (`git status`, `git commit`, `gh issue`, `gh pr create`…), mai per comandi che cancellano. Per le skill puoi autorizzarle una volta per tutte in `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Skill(archivio)", "Skill(requisiti)", "Skill(spec)",
      "Skill(piano)", "Skill(implementa)", "Skill(tdd)",
      "Skill(guardia)", "Skill(rifletti)"
    ]
  }
}
```

Se il file esiste già, aggiungi solo le righe dentro `"allow"`.

## Impostazioni per progetto

Nel `CLAUDE.md` di un progetto (condiviso con chi usa il repo) oppure nel `CLAUDE.local.md` (solo tuo, resta fuori dal repo) puoi fissare alcune scelte:

- `Archivio workflow: issues` → documenti nelle GitHub Issues del repo
- `Archivio workflow: file` → documenti in `docs/workflow/`, salvati nel repo; il lavoro resta su un ramo locale, senza pull request
- `Archivio workflow: locale` → documenti in `.claude/specs/`, solo su questo computer: adatto ai repo di lavoro, dove il team non deve vederli; le pull request si aprono come sempre
- `Git workflow: no` → progetto senza git: le skill non ti chiederanno più di inizializzarlo

Se non fissi nulla: GitHub Issues se il repo è su GitHub ed è tuo; file in `docs/workflow/` se il progetto non è su GitHub. Se il repo appartiene a un'organizzazione, la prima volta Claude ti chiede dove salvare i documenti e scrive la risposta nel `CLAUDE.local.md`.

Se crei tu a mano il `CLAUDE.local.md`, escludilo dal repo: `echo /CLAUDE.local.md >> "$(git rev-parse --git-path info/exclude)"`.

## Crediti

Il metodo di interrogatorio, la modalità mappa e le regole del TDD sono ispirati a [mattpocock/skills](https://github.com/mattpocock/skills) (licenza MIT) di Matt Pocock. I testi di queste skill sono scritti da zero, in italiano.

Gli agenti `costruttore` e `ricercatore`, la regia di `implementa`, il modo di lavorare per strati con `gh stack` (skill `piano`, `implementa` e `archivio`), la guardia, `rifletti` (con i suoi script) e `cronometro` sono adattati da [palazzem/claude-config](https://github.com/palazzem/claude-config) (licenza Apache 2.0, copia in `LICENSES/Apache-2.0.txt`). I testi sono riscritti in italiano e modificati; i file adattati lo dichiarano in testa. Lo script della guardia (`skills/guardia/scripts/`) è una versione modificata di quello della skill `shepherd`: le modifiche sono elencate in testa a `guarda-pr.sh`.

Le prove dello script si lanciano con `skills/guardia/scripts/prove/prova.sh` (servono `bash`, `jq` e `timeout`); quelle degli script di `rifletti` con `skills/rifletti/scripts/prove/prova.sh` (servono `bash`, `jq` e `git`).
