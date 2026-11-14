> DONE in v1.4.0 (15 Nov 2026). Kept as the record of the plan; current design is in CONTEXT.md.

# Offline mode - plan (for v1.4.0)

## Goal
The installed reader makes NO internet connections: no cdnjs, no Google Fonts. Works without Wi-Fi.
Why: (1) a tampered cdnjs file would run inside the page and could send out the note being viewed and the folder/recent file names; (2) Google sees each page load via fonts; (3) works offline.
The claude.ai drag-drop page keeps the CDN version (same reader.html).

## Design
1. `vendor.sh` (new, run on the laptop, which has internet) downloads the exact pinned files into `vendor/` and commits them (about 4-6 MB):
   - marked 12.0.2: https://cdnjs.cloudflare.com/ajax/libs/marked/12.0.2/marked.min.js
   - DOMPurify 3.1.6: https://cdnjs.cloudflare.com/ajax/libs/dompurify/3.1.6/purify.min.js
   - highlight.js 11.9.0: https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js
   - MathJax 3.2.2: https://cdnjs.cloudflare.com/ajax/libs/mathjax/3.2.2/es5/tex-svg-full.min.js (combined file; confirm it loads no extra components offline: watch the browser Network tab)
   - Mermaid 10.9.1: https://cdnjs.cloudflare.com/ajax/libs/mermaid/10.9.1/mermaid.min.js
   - Fonts: fetch the Google Fonts CSS with a modern browser User-Agent (gives woff2), download every font URL into vendor/fonts/, rewrite the CSS to relative paths -> vendor/fonts.css.
   - Write vendor/SHA256SUMS; vendor.sh prints it. Licence files: MIT (marked, mermaid), Apache-2.0/MPL-2.0 (DOMPurify), BSD-3 (highlight.js), Apache-2.0 (MathJax), OFL (fonts) -> vendor/LICENSES.md.
2. build.sh copies vendor/ to /usr/share/mdreader/lib/ in the deb.
3. mdview, when building a page, rewrites each `https://cdnjs.cloudflare.com/ajax/libs/...` script src and the Google Fonts <link> to `file:///usr/share/mdreader/lib/...` IF the local file exists (otherwise keeps the CDN URL). Map: one dict URL -> local file name. Remove the two `<link rel=preconnect>` lines too.
4. Optional extra lock: add a Content-Security-Policy <meta> to generated pages allowing only file: scripts/styles/fonts/images plus data:/blob: (blocks any network request from the page; external images in notes would then not load - decide; maybe allow img from https).
5. README + CONTEXT: "Works offline; makes no network requests".

## Tests
- `mdview` a note with maths, code, Mermaid, a table: everything renders with Wi-Fi OFF.
- DevTools Network tab: no request leaves file://.
- Live reload, search, folder, 📂 still work.
- Hosted claude.ai page unchanged (still CDN).
- Run public-repo-check before release (vendor files are third-party minified JS: expect "large files" lines, fine).
