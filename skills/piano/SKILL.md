---
name: piano
description: Scompone la spec di una funzione in passi piccoli, ordinati e verificabili, sceglie lo stack se non è deciso e indica per ogni passo se usare TDD o metodo classico; il piano va approvato prima di scrivere codice. Usala solo quando l'utente scrive /piano o quando la skill workflow la richiama.
argument-hint: "<funzione>"
---

# Piano: la sequenza di lavoro

Funzione: $ARGUMENTS (se è vuoto, chiedi per quale spec fare il piano).

Il piano dice **come** si arriva a soddisfare la spec: in quali passi, in che ordine, con quali strumenti. Nessuna riga di codice viene scritta prima che l'utente lo approvi.

## Passo 0: archivio e contesto

1. Carica la skill `archivio` ed esegui il suo controllo iniziale.
2. Trova e leggi la spec (etichetta `wf:spec`, o `docs/workflow/spec/<nome-breve>.md`) e prendi il suo **nome breve**. Se non esiste, fermati e proponi `/spec <funzione>`.
3. Esplora il codice: struttura, librerie in uso, come si lanciano i test, convenzioni. Per un'esplorazione ampia usa un sotto-agente.

## Passo 1: lo stack

Se il progetto ha già uno stack (linguaggio, framework, database, strumento di test), usa quello e dillo in una riga.

Lo **strumento di test** fa parte dello stack e si decide qui, con il comando per lanciare i test (per esempio `npm test`, `pytest`). Se il progetto non ha test, proponi lo strumento più comune per il suo stack e mettine l'installazione come primo passo del piano. Così `implementa` non dovrà fermarsi a chiedere.

Se va scelto, o se la funzione richiede un componente nuovo (una libreria, un servizio esterno):

- proponi **2 o 3 opzioni**, con pro e contro concreti (maturità, costo, facilità per l'utente, adatto al resto del progetto);
- verifica le informazioni sulla documentazione ufficiale e riporta i link;
- indica la tua raccomandazione;
- **aspetta la scelta dell'utente** prima di proseguire.

## Passo 2: i passi

Scomponi il lavoro in **fette verticali**: ogni passo aggiunge un pezzo di comportamento che funziona dall'inizio alla fine e si può verificare, invece di costruire uno strato alla volta (prima tutto il database, poi tutta la logica, poi tutta la grafica).

Per ogni passo scrivi:

```markdown
### Passo N – <titolo>
- Cosa: <il comportamento che aggiunge, in una o due righe>
- Criteri coperti: <numeri dei criteri di accettazione della spec>
- Modalità: TDD | classica — <motivo in poche parole>
- Verifica: <come si controlla che il passo è fatto>
- Dipende da: <passi precedenti, se ci sono>
```

**Regole per la modalità**, applicale a ogni passo:

- **TDD** per le correzioni di bug (prima un test che riproduce il bug) e per la **logica**: calcoli, regole, validazioni, trasformazioni di dati, permessi.
- **Classica** per l'aspetto grafico, le configurazioni, l'infrastruttura, gli script una tantum e i prototipi da buttare.
- In caso di dubbio scegli TDD e dillo.

Tieni i passi piccoli: un passo che richiede più di un'ora di lavoro umano va spezzato.

## Passo 3: revisione del piano

Prima di mostrarlo, ricontrolla il piano come farebbe un revisore esigente:

- [ ] **Ogni** criterio di accettazione è coperto da almeno un passo.
- [ ] L'ordine rispetta le dipendenze; nessun passo usa qualcosa che non esiste ancora.
- [ ] Ogni passo ha una verifica concreta.
- [ ] I rischi sono scritti: dati esistenti da migrare, parti delicate del codice, servizi esterni, sicurezza.
- [ ] Niente passi fuori dal perimetro della spec.

Correggi quello che non va. Per piani con più di 8 passi, fai fare questa revisione a un sotto-agente che non ha scritto il piano.

## Passo 4: approvazione e salvataggio

1. Mostra all'utente: lo stack, l'elenco dei passi con la modalità, i rischi. Chiedi l'approvazione e applica le correzioni.
2. Dopo l'approvazione salva:
   - **Issues**: per ogni passo crea una sotto-issue della spec (`--parent <spec>`, etichetta `wf:passo`, titolo `Passo N – <titolo>`), con `--blocked-by` sui passi da cui dipende. Il corpo dell'issue è il blocco `### Passo N` completo (cosa, criteri, modalità, verifica, dipendenze). Poi aggiungi alla spec un commento con stack, strumento e comando di test, rischi ed elenco dei passi.
   - **File**: `docs/workflow/piani/<nome-breve>.md`, con prima riga `Stato: aperto`, poi stack, strumento e comando di test, rischi e i passi come checklist `- [ ] Passo N – <titolo>`, ciascuno seguito dai suoi dettagli.
3. Chiudi:
   - **Se sei stata richiamata da `workflow`**: restituisci il riferimento al piano e termina senza proporre comandi.
   - **Altrimenti**: proponi il passo successivo, `/implementa <nome-breve>`.
