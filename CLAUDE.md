# CommessaPro - Regole di progetto

## Cos'e l'app
Web app di gestione cantieri per Pierantoni SRL (impresa edile, Roma).
Flusso: Sopralluogo -> Preventivo -> Cantiere -> Rapportini -> SAL.
Futuro prodotto SaaS: il codice deve restare pulito e riutilizzabile.

## Architettura (NON cambiarla senza chiedere)
- Pagine HTML single-file (HTML + CSS + JS inline), una per funzione, nella root del repo.
- Hosting: GitHub Pages, branch main, root. Push su main = deploy in produzione.
- Backend: Supabase (project `iradzlocobsipjazracw`).
  - Tabella `dati`: chiave/valore JSON (legacy, in dismissione graduale).
  - Tabella `utenti`: id, nome, email, ruolo, attivo, permessi (JSON).
  - `rapporti_v1`: fonte di verita per le ore lavorate.
  - Storage bucket `Foto`, pattern: `sopralluoghi/sop_<id>/<timestamp>.jpg`
- Dati locali: localStorage con chiavi `sopralluoghi_v3`, `cantieri_v1`, `note_v1`, `rubrica_v1`, `cp_user`, `cp_settings`.
- Nessun build step, nessun framework, nessun npm. Librerie solo via CDN (gia presente supabase-js).

## Ruoli
- admin, segretaria: accesso completo.
- operaio: solo Sopralluogo (sola lettura), I miei rapporti, Cantiere, SAL.

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

## Check obbligatori dopo OGNI edit a un file HTML
1. Cercare doppi `}` accidentali, in particolare prima del blocco `// ── INIT ──`.
2. Cercare apostrofi italiani non escapati dentro stringhe JS single-quoted
   (es. 'l'agenda' -> 'l\'agenda'). Nei template literal non serve escape.
3. Verificare che il file si apra senza errori in console (SyntaxError).
4. Verificare che id HTML non siano duplicati nel file.

## Stile
- Lingua: italiano (codice, commenti, commit, UI).
- Date formato gg/mm/aaaa, valuta euro.
- Niente em dash nei testi: usare virgola, due punti o trattino breve.
- Niente emoji nei commenti del codice (nella UI sono gia usate, ok mantenerle).
- Rispettare lo stile esistente del file che si modifica (naming italiano,
  funzioni brevi, CSS con variabili :root).
