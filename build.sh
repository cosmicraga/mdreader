#!/usr/bin/env bash
# Build mdreader_all.deb from src/ and debian/. Version comes from debian/control.
set -eu
cd "$(dirname "$0")"
VER=$(sed -n 's/^Version: //p' debian/control)
B=build/mdreader
rm -rf build && mkdir -p $B/DEBIAN $B/usr/bin $B/usr/share/mdreader $B/usr/share/applications $B/usr/share/doc/mdreader
install -m 755 debian/postinst debian/postrm $B/DEBIAN/
install -m 644 debian/control                $B/DEBIAN/
install -m 755 src/mdview                    $B/usr/bin/mdview
install -m 644 src/reader.html               $B/usr/share/mdreader/reader.html
install -m 644 src/mdreader.desktop          $B/usr/share/applications/mdreader.desktop
install -m 644 README.md                     $B/usr/share/doc/mdreader/README.md
dpkg-deb --root-owner-group --build $B mdreader_all.deb >/dev/null
echo "Built mdreader_all.deb (version $VER)"
