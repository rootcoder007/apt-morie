# Shared metadata for the R wrapper packages; sourced by fpm-r-deb.sh
# and fpm-r-rpm.sh after PKG is set.
#
#   R_FLOOR  R version the package's DESCRIPTION Depends on (default 4.3)
#   NEEDS    the other wrapper packages it imports, space separated
#
# publish.yml reads both from r-universe's PACKAGES file.

R_FLOOR="${R_FLOOR:-4.3}"
NEEDS="${NEEDS:-}"

case "${PKG}" in
  rmoriebricklayer)
    LICENSE="AGPL-3.0-only"
    URL="https://github.com/rootcoder007/rmorie-bricklayer" ;;
  rmorie|rmoriedata)
    LICENSE="AGPL-3.0-or-later"
    URL="https://github.com/rootcoder007/${PKG}" ;;
  *)
    echo "rpkg.sh: unknown package ${PKG}" >&2
    exit 2 ;;
esac

DESC="MORIE ecosystem R package ${PKG} (installs from r-universe)."

# R code run by the post-install script: installs ${PKG} and its
# dependencies from r-universe + CRAN into the site library, compiling on
# this machine, then checks it loads and reports the version it got
# (r-universe serves the newest version, which may be past ${VERSION}).
RINSTALL="
  target <- if (length(.Library.site) && nzchar(.Library.site[1])) .Library.site[1] else .Library[1]
  dir.create(target, recursive = TRUE, showWarnings = FALSE)
  options(Ncpus = max(1L, parallel::detectCores(), na.rm = TRUE))
  install.packages(\"${PKG}\",
    repos = c(\"https://rootcoder007.r-universe.dev\", \"https://cloud.r-project.org\"),
    lib = target)
  if (!requireNamespace(\"${PKG}\", lib.loc = target, quietly = TRUE))
    stop(\"${PKG}: install failed\")
  message(\"${PKG} \", format(packageVersion(\"${PKG}\", lib.loc = target)),
          \" installed in \", target)
"

RREMOVE="
  target <- if (length(.Library.site) && nzchar(.Library.site[1])) .Library.site[1] else .Library[1]
  suppressWarnings(try(remove.packages(\"${PKG}\", lib = target), silent = TRUE))
"
