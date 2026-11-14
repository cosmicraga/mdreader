# Markdown Reader (mdreader) - CONTEXT (15 Nov 2026, v1.5.0)

Markdown reader + editor for Ubuntu. Double-click a .md (or `mdview FILE.md`, alias `md`, or the app grid icon -> file picker) -> the file opens rendered in the default browser. Works offline, no network requests.
This file is in a PUBLIC repo: no platform paths, server names, keys or private notes here.

## Where things are
- Repo: ~/code/mdreader -> github.com/cosmicraga/mdreader (public, MIT, branch `master`). Commits as the GitHub noreply email (global git setting).
- On the laptop: installed as the deb; default .md app via `mdview --default` (xdg-mime, per user); alias in ~/.bashrc: `alias md='mdview'`.
- Releases: GitHub Releases, asset always named `mdreader_all.deb`; stable install link:
  `https://github.com/cosmicraga/mdreader/releases/latest/download/mdreader_all.deb`
- Installed by the deb: /usr/bin/mdview, /usr/share/mdreader/reader.html, /usr/share/mdreader/lib/ (vendored libraries + fonts), /usr/share/applications/mdreader.desktop, /usr/share/icons/hicolor/scalable/apps/mdreader.svg.
- Per user (dir 700, files 600): ~/mdreader/views/ (generated pages, server.js), recent.json, watch.json, watch.pid, server.json, secret, backups/.

## Files
| File | Role |
|---|---|
| src/reader.html | The whole reader + editor: one HTML page, inline CSS/JS. Library URLs point to cdnjs: marked 12.0.2, DOMPurify 3.4.14, highlight.js 11.9.0, MathJax 3.2.2 (es5/tex-svg-full), Mermaid 11.16.1; fonts from Google Fonts (Source Serif 4, Inter, JetBrains Mono). mdview swaps them for the local copies. Also published as a drag-drop page on claude.ai (same file, CDN version). |
| vendor.sh | Run with internet: reads the versions from the cdnjs URLs in reader.html, `npm pack`s each package (npm checks sha512), copies the file + licence into vendor/, fetches the Google Fonts woff2 into vendor/fonts + fonts.css, writes vendor/SHA256SUMS and LICENSES.md, adds SRI to reader.html where cdnjs serves the identical file. |
| vendor/ | Committed third-party files (about 7 MB). build.sh refuses to build if SHA256SUMS does not match. |
| src/mdreader.svg | App icon. |
| src/mdview | Python launcher (see "mdview" below). |
| src/mdreader.desktop | Desktop entry: Exec=/usr/bin/mdview %U; MimeType text/markdown, text/x-markdown, x-scheme-handler/mdreader. |
| debian/control, postinst, postrm | Package metadata. **Version lives in debian/control.** |
| build.sh | Checks vendor/SHA256SUMS, builds mdreader_all.deb from src/ + debian/ + vendor/ (dpkg-deb). build/ and *.deb are git-ignored. |

## mdview
- Offline: if all 5 libraries exist in /usr/share/mdreader/lib (or ~/mdreader/lib), each cdnjs <script> becomes file:///usr/share/mdreader/lib/<name> (integrity attrs dropped: SRI fails on file://), the Google Fonts link becomes lib/fonts.css, preconnect removed, and a CSP <meta> is added: default-src 'none'; script-src file: + sha256 of every inline script on the page; style-src file: 'unsafe-inline'; font-src file: data:; img-src file: data: blob: https:; connect-src http://127.0.0.1:*; base-uri file:; form-action/frame-src/object-src 'none'. Order in <head>: charset, CSP, base, __MD script.
- Save helper: inside the watcher process, HTTPServer on 127.0.0.1:<random port>, port in server.json + views/server.js (page loads it by script tag). POST /save {path, tok, base, text}: Origin must be "null", Host exactly 127.0.0.1:port, JSON content type (forces a CORS preflight), body <= 8 MB; tok = HMAC-SHA256(~/mdreader/secret, path) so a page can only save its own file; path must be in watch.json (opened in the last 24 h) with a Markdown extension; base mtime must match (else 409); backup to ~/mdreader/backups/<view-stem>-<time>.md (deleted after 30 days); CRLF kept; atomic replace with the same mode. A watcher without a matching server.json (older version) is restarted.
- No arguments (app grid): zenity file picker (multiple, starts in the folder of the last recent file); cancelled = nothing.
- `mdview FILE.md ...`: builds a page per file in ~/mdreader/views/<stem>-<sha1(path)[:8]>.html = reader.html + `<base href="file://DIR/">` + `window.__MD={text,name,path,dir,root,view,links{},mtime,live,folder[],recent[]}`; opens it with xdg-open (main() parses args, open_files() does the work).
- Folder view: prepares a page for every .md in the file's folder + 2 subfolder levels (skips hidden, node_modules, build, dist, venv, __pycache__, _archive; max 300; files before subfolders) and for the 15 recent files (recent.json). Sidebar links open those pages in the same tab.
- Live reload: starts one watcher per user (`mdview --watch`, detached; pid in watch.pid). It follows every prepared file in watch.json for 24 h; on save it rewrites views/<name>.live.js = `__mdLive(mtime_ns, text)`. The page loads that script every second (script tags work file:// -> file://, fetch does not) and re-renders in place keeping the scroll position.
- `--default`: xdg-mime default for .md and mdreader://. `--stop`: stop watcher. `--clean`: stop watcher, delete views/*, watch.json, watch.pid (keeps recent + positions).
- Links between notes (1.5.0): note_links() finds `[t](x.md)`, `[id]: x.md`, `<a href>` (fenced/inline code skipped; relative, absolute, file://, `<a b.md>`, #heading and ?query stripped) -> (key, real). key = os.path.normpath of the path the browser computes from the <base> (no symlinks resolved), real = resolve(). Pages are built for: the files, their folders, the recent files, plus every file those link to (one step, max 100 extra; MAX_LINKED). Each page gets `links` = {key: page URI} for targets that have a page (this run or still watched). reader.html noteLink() rewrites the href: same note -> `#hash`; page known -> page + `#hash`; else `mdreader://open?path=&h=&from=` (link added after the run, or two steps away). Linked pages get tokens + watch entries, so edit and live reload work there. jumpToHash() scrolls to `#heading` after render (beats the saved position); falls back to slugBase(hash).
- `mdreader://open?path=<abs .md>&h=<heading>&from=<note>`: open_link() -> open_files([file], jump=h). Any web page can call it, so: absolute path, Markdown extension, existing file <= 3 MB, AND (from is a known file whose text links to it, OR it lies under the folder of a known file, <= 2 subfolder levels, no hidden parts). Known = recent.json + active watch.json. Refused / missing -> notify-send message. Heading kept through views/jump-<random>.html (meta refresh; xdg-open drops #fragments; removed by the 2-day clean-up).
- `mdreader://reveal?path=<file>` (the 📂 button): reveal() runs `nautilus --select <file>` (else xdg-open on the folder). Only paths in recent.json/watch.json (any web page can call the link). Opens folders only, never runs files. Scheme registered on every run (ensure_scheme). Chrome asks once ("Always allow").
- Clean-up: at every mdview start, pages not refreshed for 2 days are deleted.
- file:// arguments are URL-decoded (names with spaces work).

## reader.html - key decisions
- Math pulled out BEFORE marked (placeholders M<n>; code skipped), restored as `\(..\)`/`\[..\]`, typeset by MathJax SVG. Supports `$..$`, `$$..$$`, `\(..\)`, `\[..\]`, bare `\begin{align|equation|gather|multline|eqnarray}`.
- MathJax SVG (not KaTeX) and inline highlight.js theme: the claude.ai page CSP blocks external stylesheets/fonts.
- DOMPurify on all rendered HTML; Mermaid securityLevel strict. Mermaid sources are kept in a JS array (data-i index), NOT in an attribute: DOMPurify's SAFE_FOR_XML removes attributes containing `-->`.
- Editor (only when __MD.tok exists): ✎ Edit / E; body.editing = sticky textarea left 50%, preview right (narrow: Text/Preview toggle); preview re-renders 300 ms after typing; Tab inserts 2 spaces; Ctrl+S saves; Done asks before discarding; beforeunload warns. Live updates while editing: same text -> mark saved; not dirty -> load into editor; dirty -> warn, Save then gets 409 and asks to overwrite.
- Callouts `> [!NOTE|TIP|IMPORTANT|WARNING|CAUTION]`, `==mark==`, task lists, tables in a side-scroll wrapper, YAML front-matter and BOM stripped.
- In-page `#` links handled by a click handler (the injected <base> would send them to the folder).
- Sidebar tabs Contents | Folder | Recent (tabs shown whenever __MD exists). `[hidden]{display:none!important}` is required (author display rules override the hidden attribute - that was the 1.1.1 bug).
- Reading position per file in localStorage `mdr-pos:<path>`, restored after MathJax/Mermaid, "Start from top" toast.
- Search: Ctrl+F or /, wraps hits in <mark class=hit>, skips maths/SVG/labels, Enter/Shift+Enter, Esc clears; re-runs after live update.
- Scroll jitter fix (1.0.1): html/body overflow-x:clip, scrollbar-gutter:stable, overflow-anchor:none, rAF-throttled scroll handler, progress bar via transform.
- Preferences in localStorage: theme light/sepia/dark, serif/sans, size 13-28, wide layout, last sidebar tab.
- Pages live in ~/mdreader (visible folder) because snap Firefox cannot read /tmp or hidden folders.

## History
- 1.0.0 first release. 1.0.1 scroll jitter fix. 1.1.1 folder view, recent files, reading position. 1.2.0 live reload, search. 1.2.1 `--clean`. 1.3.0 📂 show in folder, file-URI decoding. 1.5.0 links between notes (build-time scan + mdreader://open fallback, #heading jumps). 1.4.0 offline (vendored libs, CSP), editor + save helper, DOMPurify 3.4.14 and Mermaid 11.16.1 (XSS fixes), private file modes, 📂 limited to known files, app grid opens a file picker, own icon; fix: Mermaid diagrams with `-->` now render.
- Security clean-up (15 Nov): history rewritten to the noreply email; GitHub "keep email private" + "block pushes that expose email" ON.

## Release routine
1. Edit src/; bump `Version:` in debian/control. Library version changed in reader.html? run ./vendor.sh again.
2. `./build.sh && sudo apt install ./mdreader_all.deb`; test with `mdview any-file.md`.
3. Run the public-repo check (secrets, emails, private paths) before every release.
4. `git add -A && git commit -m "X.Y.Z: ..." && git push`
5. `gh release create vX.Y.Z mdreader_all.deb --title "Markdown Reader X.Y.Z" --notes "..."`

## Known limits
- Remote https images in a note still load in the deb version (allowed in the CSP on purpose); not in the claude.ai hosted copy (its CSP).
- Not in the Snap Store / Ubuntu archive (GitHub release only).
- Saving needs the watcher (stops 24 h after the last mdview run): Save then says so; run mdview on the file again.
- Live reload follows a file for 24 h after mdview last prepared it.
- Links in a note are mapped when mdview builds the page; a link added later (or a note two links away) goes through mdreader://open: Chrome asks once to open xdg-open, and the note opens in a new tab.
- Folder/Recent pages are snapshots from the mdview run until opened (then live reload updates them).

## Roadmap (priority now: 5, 8)
1. DONE 1.2.0 - Live reload.
2. DONE 1.4.0 - Offline mode + editor.
3. DONE 1.2.0 - Search in document.
4. DONE 1.5.0 - Links between notes: a link to another .md opens it in the reader.
5. NEXT - Book tags: show @recall, @step, @check, @solved etc. as styled boxes (paste files read like the book).
6. Print / PDF: clean handout layout, page breaks before chapters.
7. DONE 1.1.1 - Folder view.
8. Presentation mode: each --- or # heading becomes a full-screen slide (teach from notes).
9. Focus mode: hide bar and contents, dim all but the current paragraph.
10. DONE 1.1.1 - Recent files + reading position.
