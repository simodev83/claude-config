---
name: workflow
description: Il regista - guida un lavoro dall'idea alla pull request eseguendo in ordine requisiti, spec, piano e implementa, con l'approvazione dell'utente dopo ogni fase di decisione e l'esecuzione autonoma fino alla pull request.
argument-hint: "<tema o funzione>"
disable-model-invocation: true
---

# Workflow: dall'idea alla pull request

Tema: $ARGUMENTS (se è vuoto, chiedi all'utente cosa vuole costruire, in una frase).

Il regista non fa il lavoro delle fasi: le richiama nell'ordine giusto, controlla che ognuna sia approvata e tiene l'utente informato su dove si trova.

```
requisiti ──ok──▶ spec ──ok──▶ piano ──ok──▶ implementa ──▶ pull request ──▶ Merge (utente)
```

## Passo 0: archivio e stato

1. Carica la skill `archivio` ed esegui il suo controllo iniziale. Le fasi lo ripeteranno: va bene, è veloce.
2. Cerca cosa esiste già sul tema:
   - nell'archivio: requisiti, mappa, spec, piano (con le ricerche per etichetta della skill `archivio`, oppure i file in `docs/workflow/`);
   - con git: `git branch --list "feature/*" "fix/*"`;
   - in modalità Issues: `gh pr list --state open --search "<tema>"`.
3. Se il lavoro è già iniziato, di' all'utente a che punto è ("Requisiti fatti, spec approvata, manca il piano") e proponi di ripartire dalla fase successiva. Se c'è una mappa aperta, si riparte da `requisiti`, che proseguirà la mappa.

## Passo 1: dimensione e percorso

Valuta la dimensione del lavoro e **proponi** un percorso, con una riga di motivazione:

| Dimensione | Esempio | Percorso proposto |
|---|---|---|
| Piccolo | Una modifica chiara in una parte del sistema | spec → implementa |
| Medio | Una funzione nuova che tocca più parti | requisiti → spec → piano → implementa |
| Grande | Un sistema nuovo, una migrazione, idee ancora nebbiose | requisiti in modalità **mappa**, su più sessioni; poi spec → piano → implementa per ogni funzione |
| Banale | Un refuso, un colore, un testo | Nessun workflow: proponi di farlo direttamente |

Una fase si salta **solo** dopo l'ok esplicito dell'utente.

## Passo 2: le fasi

Richiama ogni fase con lo strumento Skill, passando il tema o la funzione come argomento.

1. **`requisiti`**: finisce quando l'utente conferma la comprensione condivisa. È il **primo punto di approvazione**.
   - Se l'utente sceglie la modalità mappa, questa sessione si ferma dopo aver tracciato la mappa o risolto una decisione. Spiega che il workflow riprenderà con `/workflow <tema>` nelle prossime sessioni, una decisione alla volta.
   - Se i requisiti contengono più funzioni, elencale e chiedi da quale partire. Le fasi successive si fanno **una funzione alla volta**.
2. **`spec`**: finisce quando l'utente approva la spec. È il **secondo punto di approvazione**.
3. **`piano`**: finisce quando l'utente approva stack e passi. È il **terzo punto di approvazione**.
4. **`implementa`**: da qui si lavora **in autonomia**, senza chiedere conferme, fino alla pull request. Ci si ferma prima solo nei casi previsti dalla skill: modifiche non salvate trovate all'inizio, `git pull` fallito, ramo già esistente, passo impossibile, criteri non chiusi dopo 3 giri, push rifiutato.

Quando richiami una fase, passale come argomento **solo** il tema o il nome breve, niente altro: il resto del testo verrebbe letto come parte del nome. La fase capisce dal contesto della conversazione (questa skill è attiva) di essere richiamata dal workflow, e in quel caso restituisce il riferimento a ciò che ha salvato invece di proporre comandi.

Tra una fase e l'altra scrivi una sola riga: "Fase X completata e salvata in <riferimento>. Passo a Y." Non chiedere un'altra conferma: l'approvazione della fase vale come via libera. Dalla spec in poi usa il **nome breve** della funzione.

## Conversazioni lunghe

Tutto ciò che ogni fase produce è salvato nell'archivio, quindi il lavoro può continuare in una sessione nuova senza perdere nulla. Se la conversazione è diventata molto lunga (tipicamente dopo un interrogatorio esteso), proponi all'utente di aprire una nuova sessione e scrivere `/workflow <tema>`: ripartirà dalla fase successiva.

## Fine

Quando la pull request è aperta:

- riepiloga in poche righe: requisiti, spec, piano e pull request, con i collegamenti;
- ricorda che il merge spetta all'utente e cosa controllare prima di farlo;
- se restano altre funzioni dai requisiti, proponi la prossima con `/workflow <funzione>`;
- se non ne restano, chiedi all'utente se chiudere i requisiti (issue `wf:requisiti` chiusa con un commento, oppure `Stato: chiuso` nel file).
