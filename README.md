# Markdown Reader for Ubuntu

A clean, read-only Markdown viewer. Double-click a `.md` file and it opens in your browser with book-style typography.

**Renders:** GitHub tables and task lists · LaTeX maths (`$…$`, `$$…$$`, `\(…\)`, `\[…\]`, `align`) via MathJax · code highlighting · Mermaid diagrams · GitHub callouts (`> [!TIP]`) · `==highlight==` · relative images next to the file.

**Reading:** live reload (the page updates when you save the file) · search in document (Ctrl+F or `/`, Enter / Shift+Enter) · sidebar tabs Contents | Folder | Recent · resumes where you left off · light / sepia / dark · serif or sans · text size · wide layout · reading progress bar.

## Install

```bash
wget -O /tmp/mdreader_all.deb https://github.com/cosmicraga/mdreader/releases/latest/download/mdreader_all.deb
sudo apt install /tmp/mdreader_all.deb
mdview --default        # make it the default app for .md files
```

## Use

```bash
mdview notes.md         # or double-click any .md file
mdview --stop           # stop the live-reload watcher (it also stops by itself after 24 h)
```

Optional alias: `echo "alias md='mdview'" >> ~/.bashrc`

## Notes

- Needs internet: MathJax, highlight.js and Mermaid load from cdnjs.
- Each opened file is written as a page to `~/mdreader/views/` (removed after 2 days). Folder view covers the file's folder and 2 subfolder levels.
- Live reload: `mdview` starts a small background watcher (one per user) that follows the prepared files for 24 hours.
- `src/reader.html` also works on its own: open it in a browser and drop a `.md` file on it.

## Build from source

```bash
./build.sh              # makes mdreader_all.deb (version from debian/control)
```

## Remove

```bash
sudo apt remove mdreader
```

MIT License.
