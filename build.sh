#!/usr/bin/env bash
# Build mdreader_all.deb from src/ + debian/ + vendor/. Version comes from debian/control.
set -eu
cd "$(dirname "$0")"
VER=$(sed -n 's/^Version: //p' debian/control)
[ -f vendor/SHA256SUMS ] || { echo "NOT FOUND: vendor/ (run ./vendor.sh first)"; false; }
( cd vendor && sha256sum --quiet -c SHA256SUMS ) || { echo "vendor/ does not match vendor/SHA256SUMS: not building"; false; }
B=build/mdreader
rm -rf build && mkdir -p $B/DEBIAN $B/usr/bin $B/usr/share/mdreader/lib $B/usr/share/applications $B/usr/share/doc/mdreader $B/usr/share/icons/hicolor/scalable/apps
install -m 755 debian/postinst debian/postrm $B/DEBIAN/
install -m 644 debian/control                $B/DEBIAN/
install -m 755 src/mdview                    $B/usr/bin/mdview
install -m 644 src/reader.html               $B/usr/share/mdreader/reader.html
install -m 644 src/mdreader.desktop          $B/usr/share/applications/mdreader.desktop
install -m 644 src/mdreader.svg              $B/usr/share/icons/hicolor/scalable/apps/mdreader.svg
install -m 644 README.md                     $B/usr/share/doc/mdreader/README.md
cp -r vendor/. $B/usr/share/mdreader/lib/
find $B/usr/share/mdreader/lib -type d -exec chmod 755 {} + ; find $B/usr/share/mdreader/lib -type f -exec chmod 644 {} +
dpkg-deb --root-owner-group --build $B mdreader_all.deb >/dev/null
echo "Built mdreader_all.deb (version $VER, offline libraries checked)"
