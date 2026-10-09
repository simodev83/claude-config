---
name: tdd
description: Sviluppo guidato dai test (TDD) - prima un test che fallisce, poi il minimo codice per farlo passare, una fetta alla volta; per i bug, prima un test che riproduce l'errore. Usala quando l'utente scrive /tdd o chiede di lavorare "test first" o "red-green", e quando la skill implementa esegue un passo in modalità TDD.
argument-hint: "[cosa costruire o bug da correggere]"
---

# TDD: prima il test, poi il codice

Obiettivo: $ARGUMENTS (se la skill è stata caricata da `implementa`, l'obiettivo è il passo in corso).

Il TDD è un ciclo **rosso → verde**:

1. **Rosso**: scrivi un test per il prossimo pezzetto di comportamento e fallo girare. **Deve fallire**, e per il motivo giusto.
2. **Verde**: scrivi il **minimo** codice che lo fa passare.
3. **Rifinitura**: con tutti i test verdi, migliora il codice se serve (nomi, duplicazioni), senza cambiarne il comportamento. I test restano verdi.

Poi il pezzetto successivo.

## Se sei stata caricata da `implementa`

Segui solo il ciclo e le regole qui sotto per il passo in corso, usando i punti di test della spec. Preparazione, commit e consegna restano compito di `implementa`: ignora la sezione "Se usi questa skill da sola".

## Se usi questa skill da sola

Quando l'utente lancia `/tdd` direttamente, senza `implementa`:

1. Carica la skill `archivio` ed esegui il suo controllo iniziale.
2. Se il progetto usa git, lavora su un ramo `fix/<nome>` (bug) o `feature/<nome>` (novità), con `<nome>` scritto secondo le regole del nome breve. Crealo come nel passo 1 di `implementa`: prima `git status` (se ci sono modifiche non salvate, fermati e chiedi cosa farne), poi ramo principale aggiornato con `git pull --ff-only`, poi `git switch -c`. Se l'utente preferisce restare sul ramo principale, rispetta la scelta: in quel caso alla fine non si apre una pull request.
3. Individua come si lanciano i test del progetto. Se non ci sono test, proponi lo strumento più comune per lo stack e aspetta l'ok.
4. Alla fine: fai girare **tutti** i test e, con git, fai il commit. Poi chiedi all'utente se consegnare il lavoro. Se sì, segui la sezione 10 ("Consegna del lavoro") della skill `archivio`, con questo corpo della pull request: cosa è cambiato, quali test lo verificano, e `Closes #<numero>` se il bug ha un'issue.
5. Se il lavoro si rivela grande (più funzioni, decisioni da prendere), fermati e proponi `/workflow` o `/spec`.

## Prima di scrivere il primo test: i punti di test

Un **punto di test** è il confine esterno da cui si osserva il comportamento senza guardare dentro: una funzione pubblica, un endpoint, un comando. I test si scrivono **solo** lì.

- Se arrivi da `implementa`, usa i punti di test della spec.
- Altrimenti proponi tu i punti di test all'utente, in parole semplici, e **aspetta la conferma**. Non si scrive nessun test su un punto non confermato.

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

## Quando il TDD non conviene

Se l'obiettivo riguarda soprattutto l'aspetto grafico, una configurazione, uno script una tantum o un prototipo da buttare, dillo all'utente: il metodo classico (codice prima, poi un controllo) è più adatto. Procedi con il TDD solo se lui conferma.
