---
name: tdd
description: Sviluppo guidato dai test (TDD) - prima un test che fallisce, poi il minimo codice per farlo passare, una fetta alla volta; per i bug, prima un test che riproduce l'errore. Usala quando l'utente scrive /tdd o chiede di lavorare "test first" o "red-green"; la carica anche l'agente costruttore per ogni passo del piano.
argument-hint: "[cosa costruire o bug da correggere]"
---

# TDD: prima il test, poi il codice

Obiettivo: $ARGUMENTS (dentro un passo del piano, l'obiettivo è il passo).

Il TDD è un ciclo **rosso → verde**:

1. **Rosso**: scrivi un test per il prossimo pezzetto di comportamento e fallo girare. **Deve fallire**, e per il motivo giusto.
2. **Verde**: scrivi il **minimo** codice che lo fa passare.
3. **Rifinitura**: con tutti i test verdi, migliora il codice se serve (nomi, duplicazioni), senza cambiarne il comportamento. I test restano verdi.

Poi il pezzetto successivo.

Il codice si scrive sempre così: non esiste una modalità "prima il codice, poi i test".

## Dentro un passo del piano

Di solito ti carica l'agente `costruttore`, per un solo passo. Segui il ciclo e le regole qui sotto con i punti di test dell'incarico. Cartella, ramo, commit e rapporto li regola l'agente: ignora la sezione "Se usi questa skill da sola".

## Se usi questa skill da sola

Quando l'utente lancia `/tdd` direttamente, senza spec né piano:

1. **Archivio.** Carica la skill `archivio` ed esegui il suo controllo iniziale (sezione 1).
2. **Dimensione.** Se il lavoro si rivela grande (più funzioni, decisioni da prendere, più di uno strato da circa 300 righe), fermati e proponi `/workflow` o `/spec`.
3. **Nome e ramo.** Scegli tu il nome breve secondo la sezione 6 di `archivio`, perché non c'è una spec che lo fissi. Il ramo è `fix/<nome-breve>` per un bug, `feature/<nome-breve>` per una novità.
4. **Preparazione.** Guarda nel progetto come si installano le dipendenze, quali file locali servono (per esempio `.env`) e come si lanciano i test. Se non ci sono test, proponi lo strumento più comune per lo stack. Mostra all'utente, in parole semplici, nome breve, ramo, preparazione e comando di test, e **aspetta l'ok**.
5. **Worktree.** Con git, apri il worktree come nella sezione 8 di `archivio`, con il ramo e la preparazione del punto 4; il passo 7 (documenti) non si applica. Senza git lavora direttamente sui file.
6. **Punti di test**, poi il ciclo, come descritto sotto.
7. **Verifica finale.** Fai girare **tutti** i test, più linter e controllo dei tipi se il progetto li ha. Con git, fai il commit dei soli file del lavoro, indicati per nome.
8. **Consegna.** Chiedi all'utente se consegnare il lavoro. Se sì, segui la sezione 10 di `archivio` con uno strato solo e questo corpo della pull request: cosa è cambiato, quali test lo verificano, i controlli concreti fatti sui pezzi senza test, e `Closes #<numero>` se il bug ha un'issue. Dopo il merge, chiudi il worktree come nella sezione 8 di `archivio`.

## Prima di scrivere il primo test: i punti di test

Un **punto di test** è il confine esterno da cui si osserva il comportamento senza guardare dentro: una funzione pubblica, un endpoint, un comando. I test si scrivono **solo** lì.

- Dentro un passo del piano, usa i punti di test dell'incarico.
- Da sola, proponi tu i punti di test all'utente, in parole semplici, e **aspetta la conferma**. Non si scrive nessun test su un punto non confermato.

## Correggere un bug

1. Scrivi un test che **riproduce il bug**: con il codice attuale deve fallire mostrando proprio l'errore segnalato.
2. Fallo girare e verifica che fallisca per quel motivo. Se passa, non hai riprodotto il bug: cerca ancora, non correggere alla cieca.
3. Correggi il codice finché il test passa.
4. Fai girare tutti i test: la correzione non deve rompere altro.

Il test resta nel progetto: se il bug dovesse tornare, se ne accorgerà subito.

## Regole del ciclo

- **Una fetta alla volta.** Un test, il codice minimo, di nuovo verde. Mai scrivere tutti i test prima e tutto il codice dopo: i test scritti in blocco verificano un comportamento *immaginato*, non quello reale.
- **Rosso prima di verde.** Un test che non hai mai visto fallire non dimostra nulla.
- **Codice minimo.** Niente funzioni "che serviranno dopo": le aggiungerà un test futuro, se serviranno davvero.
- **Fai girare i test davvero**, ogni volta. Non dichiarare mai un test "verde" senza averlo eseguito.

Per capire cosa rende buono un test ed evitare gli errori più comuni, leggi [test-buoni.md](test-buoni.md) prima del primo ciclo.

## Pezzi senza un comportamento da provare

Alcuni pezzi non hanno un comportamento da osservare con un test: installare una dipendenza, scrivere un file di configurazione, l'aspetto grafico di una pagina. Falli e verificali con un controllo concreto (un comando che li usa, un'esecuzione, una schermata), poi dichiarali: nel rapporto del `costruttore`, oppure nel resoconto all'utente e nella pull request. Non sono un motivo per saltare i test sul resto: tutto ciò che ha un comportamento passa dal ciclo rosso → verde.
