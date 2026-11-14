# Markdown Reader for Ubuntu

A clean, read-only Markdown viewer. Double-click a `.md` file and it opens in your browser with book-style typography.

**Renders:** GitHub tables and task lists · LaTeX maths (`$…$`, `$$…$$`, `\(…\)`, `\[…\]`, `align`) via MathJax · code highlighting · Mermaid diagrams · GitHub callouts (`> [!TIP]`) · `==highlight==` · relative images next to the file.

**Reading:** contents sidebar with current-section marker · light / sepia / dark · serif or sans · text size · wide layout · reading progress bar.

## Install

```bash
wget -O /tmp/mdreader_all.deb https://github.com/cosmicraga/mdreader/releases/latest/download/mdreader_all.deb
sudo apt install /tmp/mdreader_all.deb
mdview --default        # make it the default app for .md files
```

## Use

```bash
mdview notes.md         # or double-click any .md file
```

Optional alias: `echo "alias md='mdview'" >> ~/.bashrc`

## Notes

- Needs internet: MathJax, highlight.js and Mermaid load from cdnjs.
- Each opened file is written as a page to `~/mdreader/views/` (removed after 2 days).
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
