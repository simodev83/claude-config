# Cosa rende buono un test

## Un buon test

- **Verifica il comportamento, non l'implementazione.** Controlla cosa fa il codice visto da fuori, dal punto di test. Se domani riscrivi l'interno della funzione senza cambiarne il comportamento, il test deve continuare a passare.
- **Si legge come una specifica.** Il nome dice quale capacità esiste: "il cliente può prenotare un tavolo libero", "la prenotazione su un tavolo occupato viene rifiutata". Non "test funzione 3".
- **Ha un valore atteso indipendente.** Il risultato atteso viene da un esempio fatto a mano o dalla spec, scritto come valore fisso. Non viene ricalcolato come fa il codice.
- **È isolato e ripetibile.** Non dipende dall'ordine dei test, dall'ora, dalla rete o da dati lasciati da altri test.
- **Controlla una cosa sola.** Quando fallisce, si capisce subito cosa si è rotto.

## Errori da evitare

| Errore | Come si riconosce | Cosa fare invece |
|---|---|---|
| **Legato all'implementazione** | Il test si rompe quando riorganizzi il codice, anche se il comportamento non è cambiato. Controlla metodi privati, finti collaboratori interni, o legge il database invece di usare l'interfaccia. | Testa solo dal punto di test pubblico. |
| **Tautologico** | Il valore atteso è calcolato come fa il codice (`atteso = a + b` per testare `somma(a, b)`). Passa sempre, per costruzione. | Scrivi il valore atteso a mano: `somma(2, 3)` deve dare `5`. |
| **A fette orizzontali** | Prima tutti i test, poi tutto il codice. | Un test, il suo codice, verde; poi il successivo. |
| **Troppi finti oggetti (mock)** | Il test simula quasi tutto e alla fine verifica solo le simulazioni. | Simula solo ciò che è davvero esterno e lento o costoso: servizi di terzi, email, pagamenti. |
| **Test fragile nel tempo** | Passa o fallisce a seconda del giorno, dell'ora o dell'ordine di esecuzione. | Fissa data, ora e dati di partenza dentro il test. |

## Quando simulare (mock)

Simula solo ai **confini del sistema**: servizi esterni, invio di email, pagamenti, orologio di sistema. Non simulare i pezzi interni del tuo codice. Se per testare qualcosa devi simulare molte parti interne, è un segnale che il punto di test è nel posto sbagliato: parlane con l'utente.
