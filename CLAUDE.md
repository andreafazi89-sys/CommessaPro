# CommessaPro - Regole di progetto

## Cos'e l'app
Web app di gestione cantieri per Pierantoni SRL (impresa edile, Roma).
Flusso: Sopralluogo -> Preventivo -> Cantiere -> Rapportini -> SAL.
Futuro prodotto SaaS: il codice deve restare pulito e riutilizzabile.

## Architettura (NON cambiarla senza chiedere)
- Pagine HTML single-file (HTML + CSS + JS inline), una per funzione, nella root del repo.
  Unica eccezione: `stile.css` condiviso (colori, avvisi, spunte), caricato da
  tutte le pagine con `<link rel="stylesheet" href="stile.css?v=N">` prima dello
  `<style>` della pagina. Quando si modifica, aumentare N in tutte le pagine.
- Hosting: GitHub Pages, branch main, root. Push su main = deploy in produzione.
- Backend: Supabase (project `iradzlocobsipjazracw`).
  - Tabella `dati`: chiave/valore JSON (legacy, in dismissione graduale).
  - Tabella `utenti`: id, nome, email, ruolo, attivo, permessi (JSON).
  - `rapporti_v1`: fonte di verita per le ore lavorate.
  - Storage bucket `Foto`, pattern: `sopralluoghi/sop_<id>/<timestamp>.jpg`
- `archivio.html`: crea il pacchetto ZIP della commessa (scheda, foto scaricate,
  giornate in CSV, dati.json) e poi marca `archiviato:true` su sopralluogo e
  cantiere. Non cancella nulla dal bucket Foto.
- Sopralluogo in due fasi sullo STESSO record di `sopralluoghi_v3`:
  - Fase 1, `sopralluogo.html` (sopralluogo rapido): cliente e referente
    scelti dalla rubrica, indirizzo cantiere compilato dalla sede del cliente,
    lavorazioni richieste, note, foto. Il campo `cliente` resta la stringa
    "CLIENTE - Referente" usata da report, cantiere e archivio.
  - Fase 2, `sviluppo.html` (scheda di sviluppo, SOLO admin): piano, accessi,
    opere provvisionali, lavorazioni con misure, rifiuti, squadra, forniture.
    Salvata nel campo `sviluppo` del record; produce il testo per la bozza
    di preventivo. Piano, superficie, accesso e misure NON stanno in fase 1.
- Attivita' fisse: record di `cantieri_v1` con `fisso:true` (oggi Magazzino
  Giardinetti e Ricerca materiali). Sempre selezionabili nei rapportini, in
  fondo alla scelta, a prescindere da stato e `dataFine`. Non compaiono in
  Cantiere, SAL, Contabilita, Archivio e nei conteggi della Home. Nessun
  sopralluogo collegato. Si creano solo a mano sul DB, non c'e' pulsante.
- `rubrica_v1`: ogni record e' un referente. `nome` = cliente (WFP, IFAD...),
  `ref` = persona, `indirizzo` = sede del cliente.
- Dati locali: localStorage con chiavi `sopralluoghi_v3`, `cantieri_v1`, `note_v1`, `rubrica_v1`, `cp_user`, `cp_settings`.
- Nessun build step, nessun framework, nessun npm. Librerie solo via CDN (gia presente supabase-js).

## Ruoli (dal 19/10/2026; il ruolo `segretaria` non esiste piu)
- admin (solo Andrea): vede e puo' tutto. Solo lui: Archivio e Archivia,
  eliminazione di un cantiere,
  Manutenzione in Home, Esporta dati, scheda di sviluppo (fase 2), gestione
  utenti, eliminazione foto SAL, Contabilita e Note (spente in Home).
- direzione (Fabio, Rino): Sopralluogo, Rapportini in consultazione, Cantiere
  con Fine Cantiere e Riapri, SAL completo, Rubrica.
- ufficio (Pamela, Antonella): Sopralluogo, Rapportini in consultazione,
  Cantiere senza Fine e Riapri, SAL in sola lettura, Rubrica.
- operaio: I miei rapporti e SAL. Niente Sopralluogo (non li fanno) e niente
  Cantiere (dal 21/10/2026, meno distrazioni): le due pagine rimandano alla Home.
- I rapportini li compilano solo gli operai (l'admin puo' ancora inserirli).
- Tab Cantiere: scheda in sola lettura (dati, diario lavori dai rapportini,
  PDF del singolo rapportino, scorciatoie a Sopralluogo e SAL). Niente
  Registra giornata e niente cestini nel diario: le correzioni si fanno
  dai Rapportini. Le vecchie `giornate[]` restano solo per la migrazione.
  Riquadro "Ore lavorate" (dal 21/10/2026): totale ore, giornate e operai,
  ore per operaio e per mese, ricalcolati dai rapportini contando anche i
  colleghi citati (ore intere). Il diario e' raggruppato per mese e per
  giornata, tutto chiuso: si apre toccando.
  Direzione e ufficio vedono "Rapportini": tutti i rapporti, scarico PDF,
  niente Nuova giornata.
- Manutenzione resta raggiungibile da link per tutti: serve a recuperare i
  rapportini rimasti solo sul telefono di un operaio.
- Permessi per utente (`utenti.permessi`, matita in Home): valgono per tutti
  tranne l'admin e possono solo togliere (nascosto, sola lettura), mai
  aggiungere sezioni al ruolo.
- Il ruolo in `cp_user` viene riletto da `utenti` all'apertura della Home.
- Sul DB: vincolo `utenti_ruolo_valido` sui quattro ruoli; `dati` scrivibile
  da admin, direzione e ufficio, gli operai scrivono solo `rapporti_v1`.
- Utente disattivato (`utenti.attivo = false`, dal 21/10/2026): nessun permesso
  sul DB anche con la sessione aperta. `mio_ruolo()` non restituisce il ruolo e
  `utente_attivo()` e' falso: niente lettura/scrittura su `dati`, `sal_foto` e
  bucket Foto. Resta leggibile solo la propria riga in `utenti` (serve al logout).
- Fine Cantiere: stato `Completato` e `dataFine`. Nei rapportini il cantiere
  resta selezionabile per 30 giorni da `dataFine`, poi sparisce dalla scelta.
  `archiviato` non influisce sulla scelta del rapportino.
- Riepilogo mese (in `rapporto.html`, scheda "Riepilogo mese"): SOLO admin e ufficio.
  Griglia operai x giorni, sola lettura: ore proprie, citato come collega,
  giorni lavorativi vuoti. Nessun avviso agli operai: le discordanze si
  sistemano a fine mese.
- Dove hanno lavorato (in `rapporto.html`, scheda accanto al Riepilogo mese):
  stessi permessi (admin e ufficio). Giorni x operai con il codice commessa
  (primo pezzo di `commessa`, il titolo per le attivita' fisse), elenco
  commesse in fondo. Entrambe le schede hanno "Esporta PDF" (stampa del
  browser: presenze A4 orizzontale, commesse A4 verticale).

## Regole NON negoziabili
1. La sezione Contabilita e i dati economici (margini, preventivi, tariffe, costi)
   NON devono MAI essere visibili o raggiungibili dagli operai. Ne via UI, ne
   navigando direttamente agli URL delle pagine.
2. MAI credenziali, password o chiavi segrete nel codice o nei commit.
   (La publishable key Supabase nel sorgente e ammessa: e pubblica per design.)
3. Prima di qualsiasi operazione distruttiva sui dati (migrazioni, delete di massa):
   dry-run + backup automatico. Mai eseguire direttamente.
4. Ogni fix o feature = un commit separato con messaggio chiaro in italiano.
   Mai accorpare modifiche non correlate nello stesso commit.

## Sincronizzazione dati (NON tornare indietro su questo)
- `dati` e' una tabella chiave/valore: ogni chiave contiene un array intero.
  Non scrivere MAI l'array locale sopra quello del server.
- Ogni modifica passa da `salvaRecord(chiave, records)`: rilegge la versione
  remota, applica SOLO i record appena toccati, riscrive. Per allineare la copia
  locale si usa `allinea(chiave)`, che tiene la versione del server e riapplica
  la coda offline (`cp_pending_<chiave>`).
- Le cancellazioni sono marcature `eliminato:true` con `timestamp` aggiornato,
  mai rimozioni dall'array: i getter filtrano gli eliminati.
- `dbSalva` deve sempre restituire l'esito e mostrare l'errore all'utente:
  supabase-js non lancia eccezioni, restituisce {error}.
- Le pagine non devono cancellare da sole collegamenti o record perche' non li
  trovano nell'elenco locale: l'elenco locale puo' essere semplicemente vecchio.

## Check obbligatori dopo OGNI edit a un file HTML
1. Cercare doppi `}` accidentali, in particolare prima del blocco `// ── INIT ──`.
2. Cercare apostrofi italiani non escapati dentro stringhe JS single-quoted
   (es. 'l'agenda' -> 'l\'agenda'). Nei template literal non serve escape.
3. Verificare che il file si apra senza errori in console (SyntaxError).
4. Verificare che id HTML non siano duplicati nel file.

## Grafica (decisa con Andrea il 20/10/2026)
- Colori: mattone di oggi (`--brick`), definiti SOLO in `stile.css`. Le pagine
  non ridefiniscono `:root`. `--white` e' il colore del testo (nome storico).
- Colori di stato fissi e separati dal colore principale: verde salvato,
  ambra attenzione/offline (`--amber`), rosso errore (`--red`).
- Il nome "Pierantoni" non compare da nessuna parte nell'app.
- Telefono in cantiere: testi minimo 12 px (eccetto PDF), pulsanti alti
  almeno 40-44 px, zoom consentito (niente `user-scalable=no`), date gg/mm/aaaa.
- Avvisi temporanei (`.toast`): barra in alto sopra la testata, non sopra le liste.
- Home: Impostazioni (ingranaggio) solo admin; per gli operai "I miei rapporti"
  e' in evidenza; le voci solo admin stanno in fondo sotto "Gestione".
- I miei rapporti: i record nella coda offline mostrano "Solo sul telefono".

## Stile
- Lingua: italiano (codice, commenti, commit, UI).
- Date formato gg/mm/aaaa, valuta euro.
- Niente em dash nei testi: usare virgola, due punti o trattino breve.
- Niente emoji nei commenti del codice (nella UI sono gia usate, ok mantenerle).
- Rispettare lo stile esistente del file che si modifica (naming italiano,
  funzioni brevi, CSS con variabili :root).
