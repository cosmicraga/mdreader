#!/usr/bin/env bash
# Download the libraries and fonts the reader uses into vendor/ (run on a machine with internet; commit vendor/).
# Versions are read from the cdnjs URLs in src/reader.html, so the offline copy always matches the page.
# Scripts come from the npm registry (npm checks each package against its published sha512).
set -eu
cd "$(dirname "$0")"
for c in npm curl sha256sum openssl tar; do command -v $c >/dev/null || { echo "NOT FOUND: $c"; false; }; done
ver() { sed -n "s#.*cdnjs.cloudflare.com/ajax/libs/$1/\([^/]*\)/.*#\1#p" src/reader.html | head -1; }
V_MARKED=$(ver marked); V_PURIFY=$(ver dompurify); V_HLJS=$(ver highlight.js); V_MJ=$(ver mathjax); V_MMD=$(ver mermaid)
for v in V_MARKED V_PURIFY V_HLJS V_MJ V_MMD; do [ -n "${!v}" ] || { echo "NOT FOUND: version for $v in src/reader.html"; false; }; done

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
rm -rf vendor && mkdir -p vendor/fonts vendor/licenses
# package@version  file-in-package  saved-as  cdnjs-path
while read -r PKG FILE OUT CDN; do
  echo "== $PKG"
  ( cd "$T" && npm pack --silent "$PKG" >/dev/null )
  TGZ=$(ls "$T"/*.tgz); mkdir "$T/x"; tar -xzf "$TGZ" -C "$T/x"
  cp "$T/x/package/$FILE" "vendor/$OUT"
  L=$(ls "$T"/x/package/LICENSE* 2>/dev/null | head -1); [ -n "$L" ] && cp "$L" "vendor/licenses/$(echo "${PKG%@*}" | tr -d @ | tr / -)-LICENSE.txt" || echo "   (no licence file in package)"
  echo "   npm integrity: $(npm view "$PKG" dist.integrity)"
  # same file on cdnjs? then the hosted page can use SRI
  if curl -sfL "https://cdnjs.cloudflare.com/ajax/libs/$CDN" -o "$T/cdn.js"; then
    if cmp -s "$T/cdn.js" "vendor/$OUT"; then echo "   cdnjs: identical"; echo "$CDN sha384-$(openssl dgst -sha384 -binary "vendor/$OUT" | openssl base64 -A)" >> "$T/sri"
    else echo "   cdnjs: DIFFERENT file (no SRI added)"; fi
  else echo "   cdnjs: MISSING (hosted page would break for this version)"; fi
  rm -rf "$T/x" "$TGZ"
done <<LIST
marked@$V_MARKED marked.min.js marked.min.js marked/$V_MARKED/marked.min.js
dompurify@$V_PURIFY dist/purify.min.js purify.min.js dompurify/$V_PURIFY/purify.min.js
@highlightjs/cdn-assets@$V_HLJS highlight.min.js highlight.min.js highlight.js/$V_HLJS/highlight.min.js
mathjax@$V_MJ es5/tex-svg-full.js tex-svg-full.min.js mathjax/$V_MJ/es5/tex-svg-full.min.js
mermaid@$V_MMD dist/mermaid.min.js mermaid.min.js mermaid/$V_MMD/mermaid.min.js
LIST

echo "== fonts (Google Fonts, woff2)"
FURL=$(grep -o 'https://fonts.googleapis.com/css2[^"]*' src/reader.html | head -1 | sed 's/&amp;/\&/g')
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36"
curl -sfL -A "$UA" "$FURL" -o "$T/fonts.css"
for u in $(grep -o 'https://fonts.gstatic.com/[^)]*' "$T/fonts.css" | sort -u); do
  curl -sfL "$u" -o "vendor/fonts/$(basename "$u")"
done
sed -E 's#https://fonts.gstatic.com/[^)]*/([^/)]+)#fonts/\1#g' "$T/fonts.css" > vendor/fonts.css
grep -q 'gstatic' vendor/fonts.css && { echo "fonts.css still has remote URLs"; false; }
echo "   $(ls vendor/fonts | wc -l) font files"

cat > vendor/LICENSES.md <<TXT
# Third-party files in this folder
| File | Project | Version | Licence |
|---|---|---|---|
| marked.min.js | marked | $V_MARKED | MIT |
| purify.min.js | DOMPurify | $V_PURIFY | Apache-2.0 or MPL-2.0 |
| highlight.min.js | highlight.js | $V_HLJS | BSD-3-Clause |
| tex-svg-full.min.js | MathJax | $V_MJ | Apache-2.0 |
| mermaid.min.js | Mermaid | $V_MMD | MIT |
| fonts/ | Source Serif 4, Inter, JetBrains Mono (Google Fonts) | - | SIL Open Font License 1.1 |
Licence texts: licenses/. Fetched by vendor.sh on $(date +%F).
TXT

# SRI for the hosted (CDN) page: only where cdnjs serves the identical file
if [ -s "$T/sri" ]; then
  python3 - "$T/sri" <<'PY'
import re, sys
s = open("src/reader.html").read()
for line in open(sys.argv[1]):
    path, h = line.split()
    url = "https://cdnjs.cloudflare.com/ajax/libs/" + path
    s = re.sub(r'<script src="%s"[^>]*></script>' % re.escape(url),
               '<script src="%s" integrity="%s" crossorigin="anonymous"></script>' % (url, h), s)
open("src/reader.html", "w").write(s)
PY
  echo "== SRI added to src/reader.html for $(wc -l < "$T/sri") scripts"
fi

( cd vendor && find . -type f ! -name SHA256SUMS | sort | xargs sha256sum > SHA256SUMS )
echo "== vendor/ ready: $(du -sh vendor | cut -f1)"
cat vendor/SHA256SUMS | grep -v '/fonts/' 
