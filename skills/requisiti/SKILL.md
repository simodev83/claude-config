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

## Passo 2: l'interrogatorio a round

Costruisci mentalmente l'**albero delle decisioni**: ogni decisione apre quelle che dipendono da lei. La **frontiera** sono le decisioni che si possono chiedere adesso, perché tutto ciò da cui dipendono è già deciso.

A ogni round:

1. Poni **tutte** le domande della frontiera, numerate, in questo formato:

   ```
   **D1 – <titolo breve>**
   <la domanda, con le opzioni se ci sono>
   → Consiglio: <la tua risposta consigliata e perché, in una o due righe>
   ```

2. Aspetta le risposte. Poi ricalcola la frontiera: le decisioni prese sbloccano quelle successive.
3. Una domanda che dipende da un'altra ancora aperta **nello stesso round** va al round dopo.

Regole:

- **I fatti li cerchi tu, le decisioni le prende l'utente.** Non chiedere mai qualcosa che puoi scoprire leggendo il codice, la configurazione o la documentazione (versioni, librerie usate, struttura esistente). Se serve una ricerca lunga, affidala a un sotto-agente e intanto poni le domande che non ne dipendono.
- **Consiglia sempre.** Ogni domanda ha la tua risposta consigliata, così l'utente può rispondere "ok" dove è d'accordo.
- **Spiega i termini tecnici** in parole semplici la prima volta che li usi: l'utente potrebbe non conoscerli.
- **Copri tutti i rami**: chi usa il sistema, cosa deve fare, cosa succede quando qualcosa va storto (errori, dati mancanti, casi limite), dati e privacy, vincoli (tempi, costi, tecnologie imposte), cosa è **fuori perimetro**.
- **Niente silenzi**: se stai per dare qualcosa per scontato, trasformalo in una domanda con il tuo consiglio.
- Round lunghi stancano: se la frontiera ha più di 8 domande, poni le 8 più importanti e tieni le altre per il round dopo.

L'interrogatorio finisce quando la frontiera è **vuota**: ogni ramo è stato percorso e non resta nulla di presunto. Allora riepiloga le decisioni in una lista breve e chiedi: "È questa la comprensione condivisa?". Non salvare nulla prima della conferma.

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
- **File**: `docs/workflow/requisiti-<tema>.md`.

## Passo 4: chiudi

- **Se sei stata richiamata da `workflow`**: restituisci il riferimento a quanto salvato e l'elenco delle funzioni che i requisiti contengono, poi termina senza proporre comandi. Il workflow decide il seguito.
- **Altrimenti**: dai all'utente il riferimento a quanto salvato e proponi il passo successivo, `/spec <funzione>` per la prima funzione da specificare. Se i requisiti coprono più funzioni, elencale e proponi da quale partire.
