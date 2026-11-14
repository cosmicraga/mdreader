# Markdown Reader for Ubuntu

A clean Markdown reader with a built-in editor. Double-click a `.md` file and it opens in your browser with book-style typography. **Works offline:** every library and font is inside the package and the pages make no network requests.

**Renders:** GitHub tables and task lists · LaTeX maths (`$…$`, `$$…$$`, `\(…\)`, `\[…\]`, `align`) via MathJax · code highlighting · Mermaid diagrams · GitHub callouts (`> [!TIP]`) · `==highlight==` · relative images next to the file.

**Editing:** ✎ Edit (or press `E`) opens the text beside a live preview · Ctrl+S saves · a copy of the old version is kept in `~/mdreader/backups/` (30 days) · if the file changed on disk meanwhile, Save asks first · Windows line endings are kept.

**Reading:** live reload (the page updates when you save the file) · search in document (Ctrl+F or `/`, Enter / Shift+Enter) · sidebar tabs Contents | Folder | Recent · resumes where you left off · 📂 show the file in the folder · light / sepia / dark · serif or sans · text size · wide layout · reading progress bar.

## Install

```bash
wget -O /tmp/mdreader_all.deb https://github.com/cosmicraga/mdreader/releases/latest/download/mdreader_all.deb
sudo apt install /tmp/mdreader_all.deb
mdview --default        # make it the default app for .md files
```

## Use

```bash
mdview notes.md         # or double-click any .md file
mdview                  # no file: a file picker opens (this is what the app grid icon does)
mdview --stop           # stop the live-reload watcher (it also stops by itself after 24 h)
mdview --clean          # delete all saved pages in ~/mdreader/views (keeps recent list and positions)
```

Optional alias: `echo "alias md='mdview'" >> ~/.bashrc`

## Open from the Ubuntu dash

Press the Super key, type **Markdown**, click **Markdown Reader**: a file picker opens (starts in the folder you used last). Right-click the icon > **Pin to Dash** to keep it there.

## Security

- No network: marked, DOMPurify, highlight.js, MathJax, Mermaid and the fonts ship in `/usr/share/mdreader/lib/` (fetched from npm by `vendor.sh`, checked against `vendor/SHA256SUMS` at every build). Images in a note that point to `https://` still load.
- Each page has a strict Content-Security-Policy: scripts only from local files plus the page's own inline scripts (by hash), so HTML hidden in a note cannot run code or call out. All note HTML also goes through DOMPurify; Mermaid runs in strict mode.
- Saving: the background helper listens on 127.0.0.1 only, accepts requests only from reader pages (Origin `null`, exact Host), and each page carries a secret token valid for its own file only. It writes only Markdown files the reader opened in the last 24 h, backs up first and refuses if the file changed on disk.
- Pages, tokens and backups in `~/mdreader/` are private to you (mode 600/700). 📂 only opens a folder, and only for files the reader opened.

## Notes

- Each opened file is written as a page to `~/mdreader/views/` (removed after 2 days). Folder view covers the file's folder and 2 subfolder levels.
- 📂 Show in folder uses an `mdreader://` link handled by mdview (opens Files with the file selected). Chrome asks once to open xdg-open: tick "Always allow".
- Saving needs the background helper (started by `mdview`, stops after 24 h without use). If Save says it is not running, open the file with `mdview` again.
- Live reload: `mdview` starts a small background watcher (one per user) that follows the prepared files for 24 hours.
- `src/reader.html` also works on its own (with internet, from cdnjs): open it in a browser and drop a `.md` file on it. Editing needs `mdview`.

## Build from source

```bash
./vendor.sh             # once, with internet: downloads the libraries and fonts into vendor/
./build.sh              # makes mdreader_all.deb (version from debian/control)
```

## Remove

```bash
sudo apt remove mdreader
```

MIT License.
