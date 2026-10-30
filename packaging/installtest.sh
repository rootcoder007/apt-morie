#!/bin/sh
# Install packages from the repository the way README.md says, then check
# each one works. Runs as root in a fresh Debian, Ubuntu, Fedora or
# RHEL-family system.
#
# Usage: installtest.sh <base-url> <package>...
#   base-url  https://rootcoder007.github.io/apt-morie (or a local copy)
#   package   morie, rmorie, rmoriedata or rmoriebricklayer

set -eu

BASE="${1:?usage: installtest.sh <base-url> <package>...}"
shift

if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -q
  apt-get install -y -q --no-install-recommends ca-certificates curl gpg
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL "$BASE/key.gpg" | gpg --dearmor --yes -o /etc/apt/keyrings/rootcoder007.gpg
  echo "deb [signed-by=/etc/apt/keyrings/rootcoder007.gpg] $BASE/apt stable main" \
    > /etc/apt/sources.list.d/morie.list
  apt-get update -q
  apt-get install -y -q "$@"
  remove() { apt-get remove -y -q "$1"; }
else
  if command -v dnf5 >/dev/null 2>&1; then
    dnf install -y -q dnf5-plugins
    curl -fsSL "$BASE/rpm/morie.repo" | sed "s#https://rootcoder007.github.io/apt-morie#$BASE#" \
      > /etc/yum.repos.d/morie.repo
  else
    dnf install -y -q dnf-plugins-core epel-release
    dnf config-manager --set-enabled crb
    curl -fsSL "$BASE/rpm/morie.repo" | sed "s#https://rootcoder007.github.io/apt-morie#$BASE#" \
      > /etc/yum.repos.d/morie.repo
  fi
  dnf install -y "$@"
  remove() { dnf remove -y -q "$1"; }
fi

for p in "$@"; do
  case "$p" in
    morie) morie --version ;;
    *) Rscript -e "suppressPackageStartupMessages(library($p)); cat('$p', format(packageVersion('$p')), 'loads\n')" ;;
  esac
done

# removal takes the R package out of the site library too
last=""
for p in "$@"; do case "$p" in r*) last="$p" ;; esac; done
if [ -n "$last" ]; then
  remove "$last"
  if Rscript -e "quit(status = requireNamespace('$last', quietly = TRUE))"; then
    echo "$last removed with its package"
  else
    echo "installtest: $last is still installed after removing its package" >&2
    exit 1
  fi
fi
echo "INSTALLTEST OK: $*"
