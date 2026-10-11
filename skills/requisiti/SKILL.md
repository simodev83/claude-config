---
name: requisiti
description: Interrogatorio sui requisiti di un progetto o di una funzione, ad albero delle decisioni, finché non resta nulla di vago; per lavori troppo grandi per una sessione crea una mappa di decisioni su più sessioni. Usala solo quando l'utente scrive /requisiti o quando la skill workflow la richiama.
argument-hint: "[tema o progetto]"
---

# Requisiti: l'interrogatorio

Tema: $ARGUMENTS (se è vuoto, chiedi all'utente di cosa si parla in una frase).

Scopo: arrivare a una **comprensione condivisa** di cosa costruire, facendo emergere ogni decisione che l'utente non ha ancora preso. Non si scrive codice e non si pianifica il lavoro: si decide **cosa**, non **come**.

## Passo 0: archivio e contesto

1. Carica la skill `archivio` ed esegui il suo controllo iniziale.
2. Leggi quello che esiste già: `CLAUDE.md`, README, codice rilevante, e nell'archivio eventuali requisiti o mappe sullo stesso tema.
   - Se esiste una **mappa aperta** sul tema, salta il passo 1: leggi [mappa.md](mappa.md) e vai direttamente a "Sessioni successive".
   - Se esistono già requisiti sul tema, chiedi se aggiornarli o partire da zero.

## Passo 1: scegli la modalità

Valuta la dimensione del lavoro e **proponi** una modalità, con una riga di motivazione. Decide l'utente.

- **Interrogatorio** (una sessione): il lavoro si può discutere tutto in una conversazione. È il caso normale: una funzione, un progetto piccolo o medio.
- **Mappa** (più sessioni): il lavoro è troppo grande o nebbioso per una conversazione. Per esempio: un sistema nuovo intero, una migrazione, un progetto dove non si vede ancora la strada. In questo caso leggi [mappa.md](mappa.md) e segui quello al posto dei passi seguenti.

## Passo 2: l'interrogatorio, una domanda alla volta

Costruisci mentalmente l'**albero delle decisioni**: ogni decisione apre quelle che dipendono da lei. La **frontiera** sono le decisioni che si possono chiedere adesso, perché tutto ciò da cui dipendono è già deciso.

Segui le regole del `CLAUDE.md` sulle interviste. A ogni giro:

1. Dalla frontiera scegli **una sola** domanda: quella che sblocca più decisioni o che pesa di più sul risultato.
2. Ponila in questo formato, numerando le domande in ordine per tutto l'interrogatorio:

   ```
   **D1 – <titolo breve>**
   <la domanda, con le opzioni se ci sono>
   → Consiglio: <la tua risposta consigliata e perché, in una o due righe>
   (Ancora aperte: <quante domande restano nella frontiera adesso>)
   ```

3. Aspetta la risposta. Se l'utente non è d'accordo, ha dubbi o chiede chiarimenti, resta sulla stessa domanda: spiega, proponi alternative e richiedi, finché arrivate a una soluzione condivisa. Solo allora la decisione è presa.
4. Ricalcola la frontiera: la decisione presa sblocca quelle che dipendevano da lei, e le questioni nuove emerse dalla discussione entrano nell'albero come nuove domande.

Regole:

- **I fatti li cerchi tu, le decisioni le prende l'utente.** Non chiedere mai qualcosa che puoi scoprire leggendo il codice, la configurazione o la documentazione (versioni, librerie usate, struttura esistente). Per sapere cosa dice la documentazione di una libreria o di un servizio usa l'agente `ricercatore`: una domanda per agente, con la versione presa dal file delle dipendenze; le domande indipendenti lanciale insieme e, se una risposta è `NON VERIFICATO`, dillo all'utente così com'è. Per un'esplorazione ampia del codice usa un sotto-agente. Intanto poni le domande che non dipendono dalla ricerca.
- **Consiglia sempre.** Ogni domanda ha la tua risposta consigliata, così l'utente può rispondere "ok" dove è d'accordo. Quando ci sono più opzioni, ordinale secondo le regole del `CLAUDE.md` sulle decisioni.
- **Spiega i termini tecnici** in parole semplici la prima volta che li usi: l'utente potrebbe non conoscerli.
- **Copri tutti i rami**: chi usa il sistema, cosa deve fare, cosa succede quando qualcosa va storto (errori, dati mancanti, casi limite), dati e privacy, vincoli (tempi, costi, tecnologie imposte), cosa è **fuori perimetro**.
- **Niente silenzi**: se stai per dare qualcosa per scontato, trasformalo in una domanda con il tuo consiglio.

L'interrogatorio finisce quando la frontiera è **vuota**: ogni ramo è stato percorso, nessuna questione è rimasta aperta e non resta nulla di presunto. Allora riepiloga le decisioni in una lista breve e chiedi: "È questa la comprensione condivisa?". Non salvare nulla prima della conferma.

## Passo 3: salva i requisiti

Scrivi il documento con questa struttura:

```markdown
## Obiettivo
<una o due frasi: cosa si vuole ottenere e per chi>

## Utenti
<chi usa il sistema e cosa gli serve>

## Decisioni
1. <decisione> — <perché, in una riga>
...

## Casi limite ed errori
- <cosa succede quando…>

## Vincoli
- <tempi, costi, tecnologie imposte, norme>

## Fuori perimetro
- <cosa NON si fa, esplicitamente>

## Questioni aperte
- <solo se l'utente ha scelto di rimandarle>
```

- **Issues**: crea un'issue `Requisiti – <tema>` con etichetta `wf:requisiti`.
- **File o Locale**: `<cartella>/requisiti-<tema>.md` (`<cartella>` è `docs/workflow/` per File, `.claude/specs/` per Locale: sezione 4 della skill `archivio`).

## Passo 4: chiudi

- **Se sei stata richiamata da `workflow`**: restituisci il riferimento a quanto salvato e l'elenco delle funzioni che i requisiti contengono, poi termina senza proporre comandi. Il workflow decide il seguito.
- **Altrimenti**: dai all'utente il riferimento a quanto salvato e proponi il passo successivo, `/spec <funzione>` per la prima funzione da specificare. Se i requisiti coprono più funzioni, elencale e proponi da quale partire.
