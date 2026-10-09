<!-- Adattato da skills/inference-tracing/report-template.md di palazzem/claude-config (licenza Apache 2.0, copia in LICENSES/Apache-2.0.txt); riscritto in italiano e modificato. -->

# Modello del rapporto

Il rapporto è un Artifact di Claude Code, pubblicato con lo strumento Artifact come dice il passo 8 della skill, e scritto in italiano. Ha queste sezioni, in quest'ordine, per ogni lavoro. Ognuna dice cosa **trovare** nei trascritti, cosa **mostrare** e cosa **scrivere**. Sostituisci ogni `<…>` con ciò che mostra questo lavoro. Chiama le cose con il loro nome in questo lavoro: uno strato può essere uno strato del piano, un passo, una pull request. Una sezione per cui il lavoro non ha dati resta, con una riga che lo dice.

Le sezioni 10 e 11 si scrivono da capo per ogni lavoro. Tutte le altre sono fisse in ciò a cui devono rispondere.

## Convenzioni

- **Ore**: locali, con il fuso e la sua differenza da UTC nominati una volta nell'intestazione, e entrambe le differenze se cambiano durante il lavoro (ora legale). Una data dovunque un'ora possa cadere in un altro giorno.
- **Durate**: in minuti, e in ore e minuti sopra i 90. La durata delle chiamate in secondi.
- **Ogni cifra** vale alla fotografia. Ogni proiezione è indicata come stima e dice su cosa si basa.
- **Lavoro o orologio**: una cifra che somma il tempo degli agenti lo dice, e lo dice anche una cifra che conta una volta sola gli agenti sovrapposti.
- **Testo**: uno o due paragrafi brevi per sezione: prima il risultato, cifre dalle misure, citazioni di una riga secondo la regola di pubblicazione della skill.
- **Grafici**: ognuno con un titolo, una riga su come leggerlo, una legenda, il valore al passaggio del mouse o al focus, e una vista a tabella degli stessi dati.
- **Colori**: lo stesso significato in ogni grafico: un colore per attore (l'utente, il regista, ogni ruolo di agente: `costruttore`, `semplificatore`, `revisore`, `ricercatore`), un grigio per l'attesa dell'utente, un altro per l'attesa di altro, il tratteggio per un giro ripreso. Le attività usano una seconda tavolozza: un colore per il ragionamento del modello, uno per ogni attività nominata, grigio per il resto.

## 1. Intestazione

- **Occhiello:** `<nome o identificativo della sessione> · aperta <data, ora> · <comando del lavoro> dal <data, ora> · <finito <data, ora> | in corso> · fotografia <data, ora, fuso, differenza>`
- **Titolo:** `<la domanda a cui risponde la pagina, come la farebbe l'utente>`
- **Apertura**, da tre a cinque frasi: `<è bloccato qualcosa: cosa è in sospeso alla fotografia, e da quanto>` · `<orologio della sessione>` · `<a cosa è andato il tempo prima del lavoro>` · `<orologio del lavoro e avanzamento: strati finiti su totale>` · `<quanto costa uno strato, e se gli strati vanno uno dopo l'altro>` · `<stima di quanto manca, con la sua base>`
- **Secondo paragrafo:** `<le due o tre cose che portano il tempo dentro il lavoro, ognuna con la sua quota>` · `<l'evento singolo più costoso>`
- **Fila delle cifre**, cinque cifre misurate con un'etichetta di una riga: `<orologio della sessione>` · `<orologio del lavoro>` · `<strati finiti su totale>` · `<quota del ragionamento sul lavoro degli agenti, con il numero di chiamate>` · `<la prima voce fuori dal ragionamento: esecuzioni e minuti>`

## 2. L'orologio da quando si è aperta la sessione

- **Trova:** quando si è aperta la sessione e con quale comando, se ne aveva uno; se è stata ripresa in un nuovo processo, e quando; ogni fase dall'apertura alla fotografia, su tutta la catena di trascritti; per ogni fase, quanto è stato lavoro degli agenti (agenti sovrapposti contati una volta), quanto attesa dell'utente e quanto attesa di altro, e di cosa; ogni domanda rimasta aperta, e per quanto.
- **Mostra:** una barra orizzontale per fase, nell'ordine in cui sono avvenute, in minuti di orologio. Tre colori: agenti al lavoro, attesa dell'utente, attesa di altro. Il valore in fondo a ogni barra.
- **Scrivi:** `<quando si è aperta la sessione e con cosa>` · `<cosa è stata ogni fase prima del lavoro>` · `<cosa è venuto dopo la fine del lavoro, se è finito>` · `<totali: agenti al lavoro, attesa dell'utente, attesa di altro>`

## 3. Il lavoro fin qui

- **Trova:** ogni giro di agente con inizio e fine, il suo ruolo, e se è un primo giro o una ripresa; i turni del regista; i momenti in cui il lavoro ha aspettato l'utente o altro; dove gli agenti si sono sovrapposti.
- **Mostra:** una striscia dei giri. Ora sull'asse orizzontale con tacche ogni ora, e la data dove cambia il giorno; una riga per attore (l'utente, il regista, ogni ruolo di agente); un blocco per giro dall'inizio alla fine, tratteggiato se è una ripresa; una fascia sopra le righe con la fase o lo strato in corso.
- **Mostra:** una tabella, una riga per fase: `Fase | Orario | Minuti | Cosa è successo`.
- **Scrivi:** `<come leggere la striscia>` · `<se gli agenti lavorano uno alla volta o si sovrappongono, e quanto>` · `<se tra i blocchi si nasconde tempo fermo>`

## 4. Dove è andato il tempo di ogni strato

- **Trova:** per ogni strato, la sua finestra e i minuti di ogni tipo di giro al suo interno: primo passaggio per ruolo, riprese per ruolo, e il resto — la finestra meno l'orologio coperto dai suoi giri (passaggi di consegna, attese, controlli del regista come il rilancio dei test). Lo strato più economico e cosa ha cambiato. Quali strati sono tornati per un altro giro, perché, e quanto è costato.
- **Mostra:** una barra orizzontale a pila per strato, nell'ordine in cui sono stati costruiti, in minuti. Un segmento per tipo di giro, le riprese tratteggiate, il resto in grigio. Il totale in fondo a ogni barra.
- **Mostra:** una vista a tabella: `Strato | Totale | <minuti per tipo di giro> | <esecuzioni dell'attività principale, per ruolo> | <suoi minuti>`, con una riga di somma sugli strati finiti.
- **Scrivi:** `<lo strato più economico, cosa ha cambiato, e quindi il costo fisso di un passaggio nel metodo>` · `<di cosa è fatto quel costo fisso>` · `<gli strati che hanno avuto bisogno di un altro giro, perché, e il costo>` · `<i casi fuori norma>`

## 5. Cosa facevano gli agenti

- **Trova:** i minuti totali di lavoro degli agenti — il tempo del modello e degli strumenti di ogni agente, sommato — divisi tra ragionamento del modello e tempo degli strumenti per attività; la stessa divisione per ruolo.
- **Mostra:** una barra a tutta larghezza delle quote per tutti gli agenti insieme, poi una barra a pila per ruolo in minuti. Segmenti: ragionamento del modello, l'attività principale, il resto della sua famiglia, altri strumenti. La legenda porta minuti e quota.
- **Scrivi:** `<lavoro totale, e quanto è ragionamento, attività principale, resto>` · `<i ruoli la cui divisione spicca>`

## 6. Il tempo del modello

- **Trova:** il numero di chiamate; la durata mediana di una chiamata; la quota di chiamate oltre i 30 secondi e la loro quota di tempo del modello; le chiamate più lunghe con il loro tempo di ragionamento e cosa hanno prodotto; modello ed effort di ogni agente, e se li fissa la sua definizione o li eredita dalla sessione; dimensione del contesto rispetto alla durata delle chiamate.
- **Mostra:** barre affiancate per fascia di durata (da 0 a 5 s, da 5 a 15, da 15 a 30, da 30 a 60, da 60 a 120, oltre 120): quota di chiamate accanto a quota di tempo del modello.
- **Mostra:** una tabella delle chiamate singole più lunghe: `Durata | Agente | Ragionamento | Cosa ha prodotto`, l'ultima colonna come nome di strumento o firma di comando.
- **Scrivi:** `<numero di chiamate e durata mediana>` · `<quante poche chiamate tengono quanto tempo, e cosa sono>` · `<modello ed effort per ruolo, e dove sono fissati>` · `<come la dimensione del contesto sposta i tempi>`

## 7. Attività principale: `<il suo nome>`

La voce che sta in cima al tempo di questo lavoro fuori dal ragionamento: un'attività degli strumenti, oppure un'attesa. Ripeti la sezione per una seconda voce quando anche quella porta tempo vero. Quando la prima voce è una piccola parte del lavoro, o l'attesa più grande è dell'utente, la prima riga della sezione lo dice.

- **Trova:** cos'è l'attività e dove la configura il progetto; quanto dura un'esecuzione; esecuzioni, mediana e totale, con quelle in sottofondo contate; chi l'ha lanciata e quante volte per strato; quante esecuzioni l'hanno ripetuta su codice non cambiato; la riga di una skill, di una definizione di agente o di un incarico che la prescrive; cosa nel progetto la rende lenta; qualcosa nel lavoro che la sta già cambiando.
- **Mostra:** un elenco di fatti, ognuno un'affermazione in grassetto con le sue cifre.
- **Mostra:** una tabella dei comandi più costosi, sempre: `Firma del comando | Attività | Esecuzioni | Mediana | Totale | Chi`.
- **Scrivi:** `<cos'è e quanto costa un'esecuzione>` · `<chi deve lanciarla, citando la riga>` · `<chi la ripete, e su cosa>` · `<perché è lenta>`

## 8. Cosa non è il problema

- **Trova:** una cifra per ogni sospetto abituale: richieste di permesso (quanto durano le modifiche ai file), agenti bloccati o in giro a vuoto (tentativi ripetuti, e cosa è in sospeso alla fotografia), passaggi di consegna tra agenti, strumenti di git e GitHub, linter, CI (se è stato pubblicato qualcosa, e quanto sono durati i suoi giri, dove i trascritti lo mostrano), macchina sovraccarica (durata dello stesso comando lungo il lavoro).
- **Mostra:** un elenco, una riga per ogni sospetto che i dati scagionano: il sospetto in grassetto, poi la cifra che lo scagiona.

## 9. Il metodo è giusto?

- **Trova:** le definizioni di skill e agenti che hanno guidato il lavoro; dove il lavoro le ha seguite; ogni punto in cui non l'ha fatto, con l'ora della riga che lo mostra; quali costi del lavoro sono prescritti dalle definizioni; l'evento singolo più costoso e di cosa era fatto.
- **Scrivi:** `<il giudizio in una frase>` · `<ogni scostamento: cosa dice la definizione, cosa ha fatto il lavoro, quanto è costato>` · `<i costi che sono scelte di progetto, non errori>` · `<l'evento più costoso>`

## 10. Proposte

Scritte per questo lavoro. Apri con un paragrafo che dice come sono ordinati i gruppi.

Due gruppi, sempre questi: **Migliorare il metodo** e **Migliorare il collo di bottiglia del software**, il secondo nominando il collo di bottiglia quando il lavoro ne ha uno. Ognuno si apre con la sua soluzione da zero ed è in ordine di qualità del risultato. Un gruppo senza proposte lo dice in una riga, con la cifra che mostra perché. Ogni proposta è una scheda:

- **Sigla e titolo:** `<A1, A2 … | B1, B2 …>` `<la modifica, come istruzione>`
- **Etichetta:** `<Da zero | Nessuna perdita di qualità | Allenta una garanzia | Rischio per la qualità | Non misurato | Già fatto>`
- **Modifica** (o **Progetto**, per la scheda da zero): `<cosa cambiare, abbastanza in concreto da poterlo fare>`
- **Comporta**, per la scheda da zero: `<i cambiamenti che servono per arrivarci>`
- **Prove:** `<le cifre di questo lavoro che la motivano>`
- **Effetto:** `<cosa farebbe risparmiare o migliorare, con la base>`
- **Avvertenza:** `<cosa costa, cosa rischia o cosa lascia non misurato>`

## 11. Cosa farebbero risparmiare le modifiche

- **Trova:** per ogni proposta con una base misurabile, il risparmio su un tratto del lavoro già concluso.
- **Mostra:** una tabella: `Modifica | Base in questo lavoro | Risparmio`.
- **Scrivi:** `<il tratto su cui sono misurati i risparmi>` · `<che le righe si sovrappongono e non si sommano>` · `<la proiezione complessiva, indicata come stima>`

## 12. Metodo e limiti

- **Come è stato misurato:** `<ogni trascritto della catena, con la prima e l'ultima riga>` · `<quanti trascritti di agenti sono stati misurati>` · `<che niente è stato mandato alla sessione analizzata e niente del progetto è stato lanciato>` · `<come sono stati attribuiti gli intervalli>` · `<cosa presuppone ogni proiezione>`
- **Fotografie:** `<quali cifre valgono a quale ora>`
- **Correzioni:** `<cosa sbagliava una versione precedente di questa pagina>`, quando la pagina è stata ripubblicata.
- **Valori nascosti:** `<quanti valori sono stati tolti, e di che tipo>`
- **Limiti:** `<cosa i trascritti non potevano mostrare: comandi in sottofondo senza durata, chiamate ancora in sospeso, cosa non è stato analizzato>`
