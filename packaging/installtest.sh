#!/bin/sh
# Install packages from the repository the way README.md says, then check
# each one works. Runs as root in a fresh Debian, Ubuntu, Fedora or
# RHEL-family system.
#
# Usage: installtest.sh <base-url> <package>...
#   base-url  https://apt.rmorie.com (or a local copy)
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
  # a CDN edge can serve a new InRelease beside an old Packages.gz for a minute after a
  # publish; apt then refuses the index ("Mirror sync in progress?"): try again, then fail
  n=0
  until apt-get update -q -o Acquire::Retries=3; do
    n=$((n + 1))
    [ "$n" -ge 5 ] && exit 1
    sleep 20
  done
  apt-get install -y -q "$@"
  remove() { apt-get remove -y -q "$1"; }
else
  if command -v dnf5 >/dev/null 2>&1; then
    dnf install -y -q dnf5-plugins
    curl -fsSL "$BASE/rpm/morie.repo" | sed "s#https://apt.rmorie.com#$BASE#" \
      > /etc/yum.repos.d/morie.repo
  else
    dnf install -y -q dnf-plugins-core epel-release
    dnf config-manager --set-enabled crb
    curl -fsSL "$BASE/rpm/morie.repo" | sed "s#https://apt.rmorie.com#$BASE#" \
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
  # dnf also drops R once nothing needs it; then the package went with it
  hash -r 2>/dev/null || true
  if ! command -v Rscript >/dev/null 2>&1; then
    echo "$last removed with its package (R removed too)"
  elif Rscript -e "quit(status = requireNamespace('$last', quietly = TRUE))"; then
    echo "$last removed with its package"
  else
    echo "installtest: $last is still installed after removing its package" >&2
    exit 1
  fi
fi
echo "INSTALLTEST OK: $*"
