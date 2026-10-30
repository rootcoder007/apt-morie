#!/usr/bin/env bash
# Rebuild and sign the apt and dnf metadata from every package in the
# pool, whoever put it there (morie's release workflow adds morie; this
# repository's publish.yml adds the R packages).
#
# Usage: GPG_KEYID=... GPG_PASSPHRASE=... ./packaging/reindex.sh
# Run from the repository root, with the signing key imported.

set -euo pipefail

: "${GPG_KEYID:?GPG_KEYID not set}"
: "${GPG_PASSPHRASE:?GPG_PASSPHRASE not set}"

sign() { # sign <mode> <out> <in>
  gpg --batch --yes --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" \
      --default-key "${GPG_KEYID}" --digest-algo SHA512 --armor "$1" -o "$2" "$3"
}

# apt: Architecture: all packages are listed under both arches
for arch in amd64 arm64; do
  d="apt/dists/stable/main/binary-${arch}"
  mkdir -p "${d}"
  ( cd apt && dpkg-scanpackages --multiversion --arch "${arch}" pool/main /dev/null ) \
    > "${d}/Packages"
  gzip -9nkf "${d}/Packages"
done
rm -f apt/dists/stable/Release apt/dists/stable/Release.gpg apt/dists/stable/InRelease
( cd apt/dists/stable && apt-ftparchive \
    -o APT::FTPArchive::Release::Origin=rootcoder007 \
    -o APT::FTPArchive::Release::Label=morie \
    -o APT::FTPArchive::Release::Suite=stable \
    -o APT::FTPArchive::Release::Codename=stable \
    -o APT::FTPArchive::Release::Architectures="amd64 arm64" \
    -o APT::FTPArchive::Release::Components=main \
    -o APT::FTPArchive::Release::Description="MORIE ecosystem apt repository" \
    release . > ../Release.new && mv ../Release.new Release )
sign --detach-sign apt/dists/stable/Release.gpg apt/dists/stable/Release
sign --clearsign apt/dists/stable/InRelease apt/dists/stable/Release

# dnf
rm -rf rpm/repodata
createrepo_c --general-compress-type=gz rpm >/dev/null
sign --detach-sign rpm/repodata/repomd.xml.asc rpm/repodata/repomd.xml
cat > rpm/morie.repo <<'REPO'
[morie]
name=morie (rootcoder007)
baseurl=https://rootcoder007.github.io/apt-morie/rpm
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://rootcoder007.github.io/apt-morie/key.gpg
REPO

echo "apt: $(grep -c '^Package:' apt/dists/stable/main/binary-amd64/Packages) amd64 entries," \
     "$(grep -c '^Package:' apt/dists/stable/main/binary-arm64/Packages) arm64 entries;" \
     "dnf: $(ls rpm/packages/*.rpm | wc -l) packages"
