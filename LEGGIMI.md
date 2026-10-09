# claude-config

La mia configurazione di Claude Code: questa cartella è `~/.claude`. Contiene il regolamento globale (`CLAUDE.md`), le impostazioni, gli hook, la barra di stato e le skill personali: un workflow ingegneristico dall'idea alla pull request, più il TDD.

| Skill | Comando | Cosa fa |
|---|---|---|
| workflow | `/workflow <tema>` | Il regista: esegue requisiti → spec → piano → implementa, con approvazione dopo ogni fase di decisione |
| requisiti | `/requisiti <tema>` | Interrogatorio ad albero delle decisioni; modalità mappa per i lavori su più sessioni |
| spec | `/spec <funzione>` | Specifica con storie utente, casi limite e criteri di accettazione |
| piano | `/piano <funzione>` | Passi piccoli e verificabili, scelta dello stack, modalità TDD o classica per passo |
| implementa | `/implementa <funzione> [tdd\|classica]` | Ramo dedicato, test, verifica dei criteri, revisione automatica, pull request |
| tdd | `/tdd <obiettivo>` | Ciclo rosso → verde; usabile anche da sola per correggere un bug |
| archivio | — | Regole interne: dove salvare (GitHub Issues o `docs/workflow/`). Non si lancia a mano |

## Agenti

Aiutanti che le skill lanciano da sole, ognuno con il suo compito e il suo modello. Stanno in `agents/`.

| Agente | Modello e impegno | Cosa fa |
|---|---|---|
| costruttore | Opus, medio | Costruisce un passo del piano in TDD, con un commit; se si blocca restituisce una domanda per l'utente |
| semplificatore | Opus, medio | Riordina il codice di uno strato senza cambiarne il comportamento, prima della revisione |
| revisore | Opus, alto | Sola lettura: revisione di uno strato, oppure collaudo finale con tabella dei criteri e verdetto |
| ricercatore | Sonnet, basso | Risponde a una domanda su una libreria leggendo solo la documentazione ufficiale, con citazione |

## Cosa c'è nel repo

Il `.gitignore` esclude tutto tranne la configurazione elencata al suo interno. Restano sempre fuori: le credenziali, la cronologia delle conversazioni, le memorie dei progetti (`projects/`), le cache e le skill sincronizzate da claude.ai (`skills/synced/`). Per aggiungere un file o una cartella al repo va aggiunta una riga `!/<nome>` nel `.gitignore`.

## Installare su un altro computer

Su Ubuntu, o dentro WSL su Windows. Il repo è privato: serve `gh` con l'account simodev83.

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
      "Skill(piano)", "Skill(implementa)", "Skill(tdd)"
    ]
  }
}
```

Se il file esiste già, aggiungi solo le righe dentro `"allow"`.

## Impostazioni per progetto

Nel `CLAUDE.md` di un progetto puoi fissare alcune scelte:

- `Archivio workflow: file` → sempre file in `docs/workflow/`
- `Archivio workflow: issues` → sempre GitHub Issues
- `Git workflow: no` → progetto senza git: le skill non ti chiederanno più di inizializzarlo

## Crediti

Il metodo di interrogatorio, la modalità mappa e le regole del TDD sono ispirati a [mattpocock/skills](https://github.com/mattpocock/skills) (licenza MIT) di Matt Pocock. I testi di queste skill sono scritti da zero, in italiano.

Gli agenti e il modo di lavorare per strati sono adattati da [palazzem/claude-config](https://github.com/palazzem/claude-config) (licenza Apache 2.0). I testi sono riscritti in italiano.
