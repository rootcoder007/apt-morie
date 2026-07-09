#!/usr/bin/env bash
# Build an RPM for an R package of the MORIE ecosystem via fpm.
#
# Usage: ./packaging/fpm-r-rpm.sh <PKG> <VERSION>
#   PKG:     R package name (rmorie | rmoriedata | rmoriebricklayer)
#   VERSION: package version as served by r-universe, e.g. 1.0.2
#
# Output: dist/${PKG}-${VERSION}.noarch.rpm
#
# Same wrapper philosophy as morie's .rpm: no upstream source inside; the
# post-install scriptlet installs from r-universe + CRAN into the system
# site library, compiling natively on the target -- hence noarch.

set -euo pipefail

PKG="${1:?usage: fpm-r-rpm.sh <PKG> <VERSION>}"
VERSION="${2:?usage: fpm-r-rpm.sh <PKG> <VERSION>}"

mkdir -p dist "staging/${PKG}-rpm/usr/share/doc/${PKG}" "staging/${PKG}-scripts"

cat > "staging/${PKG}-rpm/usr/share/doc/${PKG}/README" <<DOC
${PKG} ${VERSION} -- installed from https://rootcoder007.r-universe.dev
via the post-install scriptlet of this package. The R library lives in the
site library reported by .Library.site. AGPL-3.0-or-later.
DOC

cat > "staging/${PKG}-scripts/postinst" <<POSTINST
#!/usr/bin/env bash
set -e
if ! command -v Rscript >/dev/null 2>&1; then
  echo "${PKG} postinst: Rscript is required but not found." >&2
  exit 1
fi
Rscript --vanilla -e '
  target <- if (length(.Library.site) && nzchar(.Library.site[1])) .Library.site[1] else .Library[1]
  dir.create(target, recursive = TRUE, showWarnings = FALSE)
  install.packages("${PKG}",
    repos = c("https://rootcoder007.r-universe.dev", "https://cloud.r-project.org"),
    lib = target)
  if (!requireNamespace("${PKG}", quietly = TRUE)) stop("${PKG}: install failed")
'
POSTINST
chmod +x "staging/${PKG}-scripts/postinst"

cat > "staging/${PKG}-scripts/prerm" <<PRERM
#!/usr/bin/env bash
set -e
Rscript --vanilla -e '
  target <- if (length(.Library.site) && nzchar(.Library.site[1])) .Library.site[1] else .Library[1]
  suppressWarnings(try(remove.packages("${PKG}", lib = target), silent = TRUE))
' || true
PRERM
chmod +x "staging/${PKG}-scripts/prerm"

fpm -s dir -t rpm \
  --name "${PKG}" \
  --version "${VERSION}" \
  --architecture noarch \
  --maintainer "Vansh Singh Ruhela <vsruhela@proton.me>" \
  --url "https://github.com/rootcoder007/${PKG}" \
  --license "AGPL-3.0-or-later" \
  --description "MORIE ecosystem R package ${PKG} (installs from r-universe)." \
  --depends "R-core >= 4.3" \
  --depends "R-core-devel" \
  --depends "gcc-c++" \
  --depends "make" \
  --depends "libcurl-devel" \
  --depends "openssl-devel" \
  --depends "libxml2-devel" \
  --after-install "staging/${PKG}-scripts/postinst" \
  --before-remove "staging/${PKG}-scripts/prerm" \
  --package "dist/${PKG}-${VERSION}.noarch.rpm" \
  -C "staging/${PKG}-rpm" \
  usr

echo "Built: dist/${PKG}-${VERSION}.noarch.rpm"
ls -lh "dist/${PKG}-${VERSION}.noarch.rpm"
