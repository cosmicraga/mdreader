# Markdown Reader (mdreader) - CONTEXT (15 Nov 2026)

Read-only Markdown viewer for Ubuntu. Double-click a .md (or `mdview FILE.md`, alias `md`) -> the file opens rendered in the default browser. No editor, on purpose.

## Where things are
- Repo: ~/code/mdreader -> github.com/cosmicraga/mdreader (public, MIT, branch `master`).
- Releases: GitHub Releases, asset always named `mdreader_all.deb` so
  `https://github.com/cosmicraga/mdreader/releases/latest/download/mdreader_all.deb` is the stable install link.
- Installed on the laptop as the deb (v1.2.1): /usr/bin/mdview, /usr/share/mdreader/reader.html, /usr/share/applications/mdreader.desktop. Default .md app via `mdview --default` (xdg-mime, per user).
- Hosted copy (drag-drop only): claude.ai artifact "Markdown Reader" (slug 5c6dd861-b300-4afe-b4a0-2e94563e0291).
- Alias in ~/.bashrc: `alias md='mdview'`.

## Files
| File | Role |
|---|---|
| src/reader.html | The whole reader: one HTML page, inline CSS/JS. Libraries from cdnjs: marked 12.0.2, DOMPurify 3.1.6, highlight.js 11.9.0, MathJax 3.2.2 (tex-svg-full), Mermaid 10.9.1. Fonts: Source Serif 4, Inter, JetBrains Mono (Google Fonts). |
| src/mdview | Python launcher. Reads the .md, injects `<base href="file://DIR/">` + `window.__MD={text,name}` into a copy of reader.html, writes ~/mdreader/views/NAME-NNNNN.html, xdg-open. Views older than 2 days are deleted. `--default` sets the xdg-mime default. |
| src/mdreader.desktop | Desktop entry, MimeType text/markdown, text/x-markdown. |
| debian/control, postinst, postrm | Package metadata. **Version lives in debian/control.** |
| build.sh | Builds mdreader_all.deb from src/ + debian/ (dpkg-deb). build/ and *.deb are git-ignored. |

## How reader.html works (key decisions)
- Math is pulled out BEFORE marked parses (placeholders M<n>; code spans/fences skipped), then restored as `\(..\)` / `\[..\]` and typeset by MathJax SVG. Reason: `_ * \` inside formulas break Markdown. Supported: `$..$`, `$$..$$`, `\(..\)`, `\[..\]`, bare `\begin{align|equation|gather|multline|eqnarray}`.
- MathJax SVG (not KaTeX) because the claude.ai artifact CSP blocks external stylesheets/fonts; SVG needs neither.
- highlight.js theme is inline CSS (same CSP reason).
- GitHub callouts `> [!NOTE|TIP|IMPORTANT|WARNING|CAUTION]`, `==mark==`, task lists, tables wrapped for side-scroll, YAML front-matter stripped, BOM stripped.
- In-page `#` links are handled by a click handler (scrollIntoView) because the injected `<base>` would otherwise send them to the folder.
- Preferences in localStorage (try/catch): theme light/sepia/dark, serif/sans, font size 13-28, wide layout.
- Views go to ~/mdreader (visible folder) because snap Firefox cannot read /tmp or hidden dirs.

## History
- 1.0.0 (15 Nov): first release.
- 1.1.1 (15 Nov): Folder view (sidebar tabs Contents | Folder | Recent; Folder = .md files in the opened file's folder + 2 subfolder levels, skipping hidden dirs, node_modules, build, dist, venv, _archive; max 300; files before subfolders), Recent = last 15 files (~/mdreader/recent.json); mdview prepares a view for each (name = stem-sha1(path)[:8].html), links open in the same tab, content as of the mdview run. Reading position per file (localStorage mdr-pos:<path>), restored after MathJax/Mermaid, 'Start from top' toast. Fix: [hidden]{display:none!important} (author display:flex was overriding the hidden attribute).
- 1.2.1 (15 Nov): `mdview --clean` = stop the watcher, delete everything in ~/mdreader/views, watch.json and watch.pid; keeps recent.json and reading positions. (Automatic clean-up still runs at each mdview start: pages not refreshed for 2 days.)
- 1.2.0 (15 Nov): live reload + search. Live: mdview starts one background watcher per user (`mdview --watch`, pid in ~/mdreader/watch.pid, `mdview --stop`) that follows every prepared file listed in ~/mdreader/watch.json for 24 h; on save it rewrites views/<name>.live.js with __mdLive(mtime_ns, text); the page loads that script every second (script tags work file:// to file://, fetch does not) and re-renders in place keeping the scroll position. Search: Ctrl+F or /, wraps hits in <mark class=hit>, skips maths/SVG/code labels, Enter/Shift+Enter, Esc clears; re-runs after a live update.
- 1.0.1 (15 Nov): fixed text shaking at page bottom (horizontal overflow toggling a scrollbar). Fix: html/body overflow-x:clip, scrollbar-gutter:stable, overflow-anchor:none, scroll handler throttled with rAF, progress bar uses transform.

## Release routine
1. Edit src/ ; bump `Version:` in debian/control.
2. `./build.sh && sudo apt install ./mdreader_all.deb` ; test with `mdview ~/code/infra/NOW.md`.
3. `git add -A && git commit -m "X.Y.Z: ..." && git push`
4. `gh release create vX.Y.Z mdreader_all.deb --title "Markdown Reader X.Y.Z" --notes "..."`
Rule: never put platform paths, keys or private notes in this repo (public).

## Known limits
- Needs internet (cdnjs libraries). Images from the web load in the deb version; not in the claude.ai hosted copy (CSP).
- Live reload follows a file for 24 h after mdview last prepared it; after that, run mdview again.
- Folder/Recent pages are snapshots from the mdview run until opened (then live reload brings them up to date).
- Not in the Snap Store / Ubuntu archive (GitHub release only).

## Ideas / roadmap (15 Nov 2026) - priority: 1, 5, 8 first
1. DONE 1.2.0 - Live reload: page refreshes when the .md is saved (write in any editor, read beside it).
2. Offline mode: bundle MathJax, highlight.js, Mermaid in the deb (~5 MB), no internet needed.
3. DONE 1.2.0 - Search in document: search box, highlight matches, jump between them.
4. Links between notes: a link to another .md opens it in the reader.
5. Book tags: show @recall, @step, @check, @solved etc. as styled boxes (paste files read like the book).
6. Print / PDF: clean handout layout, page breaks before chapters.
7. DONE 1.1.1 - Folder view: sidebar listing all .md files in the folder.
8. Presentation mode: each --- or # heading becomes a full-screen slide (teach from notes).
9. Focus mode: hide bar and contents, dim all but the current paragraph.
10. DONE 1.1.1 - Recent files + reading position: reopen a file where you left off.
