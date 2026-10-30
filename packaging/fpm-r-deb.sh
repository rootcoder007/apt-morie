#!/usr/bin/env bash
# Build a Debian .deb for an R package of the MORIE ecosystem via fpm.
#
# Usage: R_FLOOR=4.3 NEEDS="rmoriebricklayer" ./packaging/fpm-r-deb.sh <PKG> <VERSION>
#   PKG:     R package name (rmorie | rmoriedata | rmoriebricklayer)
#   VERSION: package version as served by r-universe, e.g. 1.0.3
#   R_FLOOR, NEEDS: see packaging/rpkg.sh
#
# Output: dist/${PKG}_${VERSION}_all.deb
#
# Same wrapper philosophy as morie's .deb: the package carries no upstream
# source. Its post-install script installs the package (with dependencies)
# from r-universe + CRAN into the system site library, compiling natively
# on the target machine -- which is why the .deb is Architecture: all.

set -euo pipefail

PKG="${1:?usage: fpm-r-deb.sh <PKG> <VERSION>}"
VERSION="${2:?usage: fpm-r-deb.sh <PKG> <VERSION>}"
. "$(dirname "$0")/rpkg.sh"

mkdir -p dist "staging/${PKG}-deb/usr/share/doc/${PKG}" "staging/${PKG}-scripts"

cat > "staging/${PKG}-deb/usr/share/doc/${PKG}/README" <<DOC
${PKG} ${VERSION} -- installed from https://rootcoder007.r-universe.dev
via the post-install script of this package. The R library lives in the
site library reported by .Library.site. ${LICENSE}.
DOC

cat > "staging/${PKG}-scripts/postinst" <<POSTINST
#!/bin/sh
set -e
[ "\$1" = configure ] || exit 0
if ! command -v Rscript >/dev/null 2>&1; then
  echo "${PKG} postinst: Rscript is required but not found." >&2
  exit 1
fi
Rscript --vanilla -e '${RINSTALL}'
POSTINST
chmod +x "staging/${PKG}-scripts/postinst"

# only on removal: an upgrade's postinst reinstalls over the old copy
cat > "staging/${PKG}-scripts/prerm" <<PRERM
#!/bin/sh
case "\$1" in remove|purge) ;; *) exit 0 ;; esac
command -v Rscript >/dev/null 2>&1 || exit 0
Rscript --vanilla -e '${RREMOVE}' || true
PRERM
chmod +x "staging/${PKG}-scripts/prerm"

deps=()
for n in ${NEEDS}; do deps+=(--depends "${n}"); done

fpm -s dir -t deb \
  --name "${PKG}" \
  --version "${VERSION}" \
  --architecture all \
  --maintainer "Vansh Singh Ruhela <vsruhela@proton.me>" \
  --url "${URL}" \
  --license "${LICENSE}" \
  --description "${DESC}" \
  --depends "r-base-core (>= ${R_FLOOR})" \
  --depends "r-base-dev" \
  --depends "build-essential" \
  --depends "libcurl4-openssl-dev" \
  --depends "zlib1g-dev" \
  "${deps[@]}" \
  --after-install "staging/${PKG}-scripts/postinst" \
  --before-remove "staging/${PKG}-scripts/prerm" \
  --deb-no-default-config-files \
  --package "dist/${PKG}_${VERSION}_all.deb" \
  -C "staging/${PKG}-deb" \
  usr

echo "Built: dist/${PKG}_${VERSION}_all.deb"
ls -lh "dist/${PKG}_${VERSION}_all.deb"
