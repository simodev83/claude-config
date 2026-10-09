---
name: spec
description: Trasforma i requisiti di una singola funzione in una specifica precisa e verificabile, con storie utente, casi limite e criteri di accettazione numerati. Usala solo quando l'utente scrive /spec o quando la skill workflow la richiama.
argument-hint: "<funzione>"
---

# Spec: il contratto di una funzione

Funzione: $ARGUMENTS (se è vuoto, chiedi quale funzione specificare).

La spec è il **contratto**: dice esattamente cosa deve fare la funzione e come si verifica che lo faccia. Alla fine del lavoro, `implementa` controllerà il codice criterio per criterio contro questo documento.

## Passo 0: archivio e contesto

1. Carica la skill `archivio` ed esegui il suo controllo iniziale.
2. Cerca i requisiti collegati (etichetta `wf:requisiti`, o `<cartella>/requisiti-*.md`; `<cartella>` è `docs/workflow/` per File, `.claude/specs/` per Locale, come nella sezione 4 della skill `archivio`) e leggili.
3. Esplora il codice esistente per capire dove si inserisce la funzione e quali convenzioni usa il progetto (nomi, struttura, test già presenti). Per sapere cosa permette una libreria o un servizio usa l'agente `ricercatore`, come nel passo 1 della skill `piano`.

## Passo 1: niente nuovo interrogatorio

La spec **sintetizza** quello che è già stato deciso. Non ripetere le domande dei requisiti.

- Se mancano i requisiti e la funzione è piccola, bastano poche domande mirate (al massimo 5, ognuna con il tuo consiglio).
- Se mancano i requisiti e la funzione è grande o vaga, fermati e proponi prima `/requisiti`.
- Se trovi una contraddizione tra requisiti e codice esistente, chiedi all'utente come risolverla.

## Passo 2: i punti di test

Un **punto di test** è il confine esterno da cui si controlla la funzione senza guardarci dentro: per esempio una funzione pubblica, un endpoint di un'API, una pagina. I test andranno solo lì.

Proponi i punti di test, preferendo quelli già esistenti e il più "in alto" possibile: meno punti ci sono, meglio è. Spiega la proposta in parole semplici e **chiedi conferma** all'utente.

## Passo 3: scrivi la spec

Scegli il **nome breve** della funzione (regole nella sezione 6 della skill `archivio`, per esempio `export-csv`) e scrivilo in testa alla spec: lo useranno piano, ramo e file. Prima controlla che sia libero: nessun'altra spec con lo stesso nome nell'archivio e, con git, niente in `git worktree list` e in `git branch --list "*/<nome-breve>*"`. Se è già usato, scegline un altro.

```markdown
Nome breve: <nome-breve>

## Problema
<il problema dal punto di vista dell'utente>

## Soluzione
<la soluzione dal punto di vista dell'utente>

## Storie utente
1. Come <chi>, voglio <cosa>, così da <perché>.
...

## Criteri di accettazione
1. <condizione verificabile: "Quando …, allora …">
...

## Casi limite ed errori
- <situazione> → <comportamento atteso>

## Decisioni tecniche
- <moduli coinvolti, interfacce, formato dei dati, modifiche al database>

## Test
- Punti di test: <quelli confermati al passo 2>
- Cosa si verifica: <il comportamento visibile dall'esterno, non i dettagli interni>

## Fuori perimetro
- <cosa questa spec NON copre>

## Riferimenti
- Requisiti: <titolo e numero, o percorso del file>
```

Regole:

- **Criteri verificabili.** Ogni criterio deve poter diventare un test o un controllo concreto. "Deve essere veloce" non va bene; "la pagina si carica in meno di 2 secondi con 1.000 prenotazioni" sì. Nel collaudo finale ogni criterio dovrà avere la sua prova: un test che passa o un controllo concreto.
- **Niente percorsi di file né codice** nelle decisioni tecniche: invecchiano in fretta. Descrivi moduli e interfacce.
- **Tutto il perimetro della funzione, niente di più.** Quello che resta fuori va scritto in "Fuori perimetro".

## Passo 4: approvazione e salvataggio

1. Mostra all'utente la spec e chiedi l'approvazione. Applica le correzioni richieste.
2. Dopo l'approvazione salva:
   - **Issues**: issue `Spec – <Funzione>` con etichetta `wf:spec`. Se esiste un'issue di requisiti o una mappa collegata, crea la spec come sua sotto-issue (`--parent`).
   - **File o Locale**: `<cartella>/spec/<nome-breve>.md`, con prima riga `Stato: aperto`.
3. Chiudi:
   - **Se sei stata richiamata da `workflow`**: restituisci il riferimento alla spec e il nome breve, poi termina senza proporre comandi.
   - **Altrimenti**: proponi il passo successivo. Consiglia `/piano <nome-breve>` se la funzione tocca più parti del sistema o richiede scelte tecniche, altrimenti `/implementa <nome-breve>` direttamente, e lascia scegliere l'utente.
