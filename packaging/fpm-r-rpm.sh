#!/usr/bin/env bash
# Build a RPM for an R package of the MORIE ecosystem via fpm.
#
# Usage: R_FLOOR=4.3 NEEDS="rmoriebricklayer" ./packaging/fpm-r-rpm.sh <PKG> <VERSION>
#   PKG:     R package name (rmorie | rmoriedata | rmoriebricklayer)
#   VERSION: package version as served by r-universe, e.g. 1.0.3
#   R_FLOOR, NEEDS: see packaging/rpkg.sh
#
# Output: dist/${PKG}-${VERSION}.noarch.rpm
#
# Same wrapper philosophy as morie's .rpm: no upstream source inside; the
# post-install scriptlet installs from r-universe + CRAN into the system
# site library, compiling natively on the target -- hence noarch.

set -euo pipefail

PKG="${1:?usage: fpm-r-rpm.sh <PKG> <VERSION>}"
VERSION="${2:?usage: fpm-r-rpm.sh <PKG> <VERSION>}"
. "$(dirname "$0")/rpkg.sh"

mkdir -p dist "staging/${PKG}-rpm/usr/share/doc/${PKG}" "staging/${PKG}-scripts"

cat > "staging/${PKG}-rpm/usr/share/doc/${PKG}/README" <<DOC
${PKG} ${VERSION} -- installed from https://rootcoder007.r-universe.dev
via the post-install script of this package. The R library lives in the
site library reported by .Library.site. ${LICENSE}.
DOC

cat > "staging/${PKG}-scripts/postinst" <<POSTINST
#!/bin/sh
set -e
if ! command -v Rscript >/dev/null 2>&1; then
  echo "${PKG} postinst: Rscript is required but not found." >&2
  exit 1
fi
Rscript --vanilla -e '${RINSTALL}'
POSTINST
chmod +x "staging/${PKG}-scripts/postinst"

# only on erase ($1 = 0): an upgrade's %post reinstalls over the old copy
cat > "staging/${PKG}-scripts/prerm" <<PRERM
#!/bin/sh
[ "\$1" = 0 ] || exit 0
command -v Rscript >/dev/null 2>&1 || exit 0
Rscript --vanilla -e '${RREMOVE}' || true
PRERM
chmod +x "staging/${PKG}-scripts/prerm"

deps=()
for n in ${NEEDS}; do deps+=(--depends "${n}"); done

fpm -s dir -t rpm \
  --name "${PKG}" \
  --version "${VERSION}" \
  --architecture noarch \
  --maintainer "Vansh Singh Ruhela <vsruhela@proton.me>" \
  --url "${URL}" \
  --license "${LICENSE}" \
  --description "${DESC}" \
  --depends "R-core >= ${R_FLOOR}" \
  --depends "R-core-devel" \
  --depends "gcc-c++" \
  --depends "make" \
  --depends "libcurl-devel" \
  --depends "zlib-devel" \
  "${deps[@]}" \
  --after-install "staging/${PKG}-scripts/postinst" \
  --before-remove "staging/${PKG}-scripts/prerm" \
  --package "dist/${PKG}-${VERSION}.noarch.rpm" \
  -C "staging/${PKG}-rpm" \
  usr

echo "Built: dist/${PKG}-${VERSION}.noarch.rpm"
ls -lh "dist/${PKG}-${VERSION}.noarch.rpm"
