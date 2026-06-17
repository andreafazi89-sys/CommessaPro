# CommessaPro

App gestione cantieri per **Andrea Fazi** (Pierantoni SRL), in ottica SaaS futura.

## Stack & deploy

- **Repo**: github.com/andreafazi89-sys/CommessaPro
- **Live**: https://andreafazi89-sys.github.io/CommessaPro
- **Hosting**: GitHub Pages da `main/(root)` — tutti i file HTML in root (non più in `public/`)
- **Backend**: Supabase project `iradzlocobsipjazracw`
- **Storage**: bucket `Foto` con pattern `sopralluoghi/sop_<id>/<timestamp>.jpg`

## Persone

### Utenti
- **Admin**: Andrea Fazi — `andreafazi89@gmail.com`
- **Segretaria**: Antonella Ventrella — `a.ventrella@pierantonicm.com` (NON Annalisa)
- **Operaio (esempio)**: Adrian Lup — `a.lup@pierantonicm.com`

### Operai censiti
Adrian Lup, Fabio Cardini, Daniele Schedel, Michele Poveste, Vasile Banta

### Capi cantiere
Andrea Fazi, Rino Lenti

> Lino Brunozzi ha lasciato l'azienda — rimosso dalle liste selezionabili.

## Struttura dati (localStorage + Supabase)

| Chiave | Contenuto |
|---|---|
| `sopralluoghi_v3` | Sopralluoghi. Foto come `[{url: "https://.../storage/.../Foto/sopralluoghi/sop_<id>/<ts>.jpg"}]` |
| `cantieri_v1` | Cantieri (i nuovi non hanno più `giornate[]`) |
| `rapporti_v1` | **Fonte di verità**: record individuali operaio/giornata/cantiere |
| `note_v1` | Note |
| `rubrica_v1` | Rubrica clienti |
| `migrazione_rapporti_v1_done` | Flag `=1` quando migrazione completa |

## Tab operative

- **sopralluogo** — geoloc + upload foto Storage, bottone "📱 Apri commessa" (WhatsApp segretaria)
- **cantiere** — diario letto da `rapporti_v1`, bottone "✓ Fine Cantiere" (mail segretaria per fattura)
- **rapporto** ("I miei rapporti") — multi-riga multi-operaio
- **sal**
- **contabilita**
- **note**
- **rubrica**

### Rapportino PDF
- Singolo contributo + giornaliero aggregato
- Logo Pierantoni
- Firma = operaio

### Permessi
- **Operai**: vedono solo i propri rapporti
- **Admin/segretaria**: vedono tutto

### Onboarding
Banner in ogni tab.

## 🚨 REGOLE FERREE 🚨

1. **Contabilità MAI visibile agli operai**
2. **Niente credenziali in chat** (numeri WhatsApp, password, ecc. — usa placeholder tipo `39XXXXXXXXXX` e chiedi all'utente di sostituirli)
3. **Sempre dry-run prima di operazioni distruttive** sui dati
4. **Backup automatici prima di migrazioni**
5. **Stile risposta**: italiano, tono pratico, step-by-step

## ⚠️ BUG RICORRENTI da verificare dopo OGNI modifica HTML

Dopo qualsiasi `Edit` su file HTML, controllare con DevTools Console (`SyntaxError` = bug):

1. **Doppia `}` prima di `// ── INIT ──`** — accade quando si chiude una funzione ma c'è già la `}` finale
2. **Apostrofi non escapati in stringhe `'...'` con testo italiano** — es. `'l'agenda'`, `'l'avanzamento'`, `'l'utente'`
   - Soluzione: scrivere senza apostrofo (`"agenda"`, `"avanzamento"`) o usare doppi apici / template literals

Spesso questi bug si generano quando si modifica in serie l'onboarding o si scrivono toast/alert in italiano.

### Verifica rapida in shell
```bash
# Bug 1: doppia } prima di INIT
grep -B1 "// ── INIT" file.html | head -5

# Bug 2: apostrofi italiani in stringhe singole
grep -n "'[^']*l'[a-zà-ù]" file.html
```

## Configurazione SEGRETARIA (per messaggi)

In testa allo `<script>` di ogni file che la coinvolge:

```js
const SEGRETARIA = {
  email: 'a.ventrella@pierantonicm.com',
  whatsapp: '39XXXXXXXXXX'  // ← formato internazionale, no + né spazi
};
```

Trigger attivi:
- **Sopralluogo salvato** → WhatsApp: "Nuovo sopralluogo - {cliente} - {indirizzo}. Aprire commessa." (`avvisaSegretariaSopralluogo()` in `sopralluogo.html`)
- **Fine cantiere** → Email: oggetto "Fine cantiere {rif} - emettere fattura" + dettagli (`notificaFineCantiere()` in `cantiere.html`)

## Backlog (priorità)

- 🔴 **Contabilità deve leggere da `rapporti_v1`** invece di `cantieri[].giornate[]`
- 🟡 Foto SAL su Storage (stesso pattern sopralluogo)
- 🟡 Bolla materiali allegabile alla giornata cantiere
- 🟡 Mappa cantieri in home (lat/lon già salvate nei sopralluoghi)

## Workflow git

Per ogni feature/fix:
1. Modifica file in root del repo
2. Verifica sintassi (vedi sezione bug ricorrenti)
3. `git add <file>`
4. `git commit -m "tipo: descrizione breve"`
5. `git push origin main`
6. Aspetta ~30-60s deploy GitHub Pages
7. Hard refresh sul live (`Cmd+Shift+R`) per evitare cache

## Note tecniche utili

- **Reverse geocoding**: usa Nominatim OSM. Se manca `addr.road`, fallback su `pedestrian/footway/path/cycleway/neighbourhood/suburb/hamlet`. Se nessuno disponibile, usa `data.display_name` (no solo CAP).
- **Compressione foto upload**: `comprimiImmagine(file, 2000, 0.85)` — canvas → JPEG max 2000px lato lungo, qualità 0.85
- **Foto in report PDF**: `object-fit: contain` (foto intere, no taglio), height 280px, sfondo `#FAFAF7`
