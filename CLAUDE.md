# Preferenze globali

- Scrivi sempre in italiano con l'utente, in ogni progetto.
- All'inizio di ogni sessione dì all'utente su quale account GitHub stiamo lavorando (simodev83 personale, SimoneBEN324 aziendale). Il repo `bartonitaly/flagship-store` usa sempre SimoneBEN324.

## Decisioni

- Quando proponi più opzioni, ordinale solo per la qualità del risultato: correttezza, sicurezza, manutenibilità, prestazioni, facilità di gestione. Tempo di realizzazione, costi e fatica di migrazione scrivili come avvertenze, mai come criteri per l'ordine.
- Includi sempre anche l'opzione "da zero": come lo progetteremmo oggi partendo da un foglio bianco, con i cambiamenti che comporterebbe. Allarga il lavoro oltre la richiesta solo se l'utente sceglie quell'opzione.

## Interviste

Valgono ogni volta che fai domande all'utente per arrivare a una decisione: requisiti, mappa, spec o una discussione qualsiasi.

- Una domanda alla volta: un solo messaggio, oppure una sola domanda per chiamata allo strumento di domanda, sempre con il tuo consiglio. Mai un elenco di domande insieme.
- Passa alla domanda successiva solo quando sulla precedente c'è una soluzione condivisa. Se l'utente ha dubbi, obietta o fa una controdomanda, resta su quella domanda: spiega, proponi alternative e chiedi di nuovo finché siete d'accordo.
- Se una risposta apre una questione nuova, aggiungila all'albero delle decisioni e continua finché ogni ramo è chiuso. Non lasciare questioni aperte, a meno che l'utente scelga esplicitamente di rimandarne una.

## Qualità del codice

- Non disattivare mai una regola del linter e non aggiungere eccezioni o soppressioni (`eslint-disable`, `# noqa`, `@ts-ignore`, `# type: ignore` e simili). Le eccezioni le concede solo l'utente, con un motivo e una scadenza.
- Gli avvisi sono problemi da risolvere: correggi la causa degli avvisi di compilatore, linter, test, build e deprecazione, non nasconderli. Se il progetto non tratta gli avvisi come errori, proponi all'utente di farlo.
- Il codice esistente non è il metro della qualità. Se nel progetto c'è un modo di fare che viola le buone pratiche, non copiarlo: nel codice nuovo usa il modo giusto, segnala all'utente i punti esistenti da migrare e chiedi se farlo ora o dopo. Mai introdurre un terzo modo diverso dai due.

## Docstring e commenti

- Ogni modulo, classe, funzione e metodo pubblico o esportato ha una docstring che ne dichiara il contratto: cosa fa, cosa riceve e restituisce, effetti collaterali, errori, un esempio quando aiuta. Mai una ripetizione della firma. Per il codice interno, solo quando non è ovvio. Scrivila nella lingua già usata nel progetto. Se il linter ha una regola per le docstring mancanti, proponi di attivarla.
- Dentro il codice, nessun commento come regola. Scrivine uno solo per un "perché" non ovvio (un vincolo nascosto, un'invariante sottile, l'aggiramento di un problema), su una riga a sé, mai in fondo a una riga di codice.
