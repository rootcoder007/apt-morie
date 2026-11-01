# apt-morie

**Signed apt *and* dnf repository for the [MORIE ecosystem](https://github.com/rootcoder007/morie)**, served from GitHub Pages at <https://rootcoder007.github.io/apt-morie/>.

Despite the name, this one repository serves **both** package ecosystems, for **four packages**:

| Package | Backed by | Post-install pulls from | Arch |
|---|---|---|---|
| `morie` | Python CLI/toolkit | [PyPI](https://pypi.org/project/morie/) (`pip install morie==V` into `/opt/morie/venv`) | `amd64`/`arm64`, `x86_64`/`aarch64` |
| `rmorie` | R package | [r-universe](https://rootcoder007.r-universe.dev) (`install.packages`, native compile) | `all` / `noarch` |
| `rmoriedata` | R package | r-universe | `all` / `noarch` |
| `rmoriebricklayer` | R package | r-universe | `all` / `noarch` |

| Path | Ecosystem | Contents |
|---|---|---|
| [`apt/`](https://rootcoder007.github.io/apt-morie/apt/) | Debian / Ubuntu | `.deb` pool + signed `Release`/`InRelease` |
| [`rpm/`](https://rootcoder007.github.io/apt-morie/rpm/) | Fedora / RHEL | signed `.rpm` packages + `repodata/` + [`morie.repo`](https://rootcoder007.github.io/apt-morie/rpm/morie.repo) |
| [`key.gpg`](https://rootcoder007.github.io/apt-morie/key.gpg) | both | ASCII-armored public signing key |

> **Signing key changed on 30 October 2026.** The repository is now signed
> with `F82E A8D6 55D9 1879 570F  A1BE 6E5D 6869 2E9D AB51`
> ("MORIE packaging"). If you added it before then, fetch the key once more
> (the first two commands of the install below, or the `rpm --import`
> line for dnf); `apt update` and `dnf` refuse the repository until you do.

## Install — Debian / Ubuntu (apt)

```bash
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://rootcoder007.github.io/apt-morie/key.gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/rootcoder007.gpg
echo "deb [signed-by=/etc/apt/keyrings/rootcoder007.gpg] https://rootcoder007.github.io/apt-morie/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/morie.list
sudo apt update
sudo apt install morie                                # Python toolkit
sudo apt install rmorie rmoriedata rmoriebricklayer   # R packages
```

## Install — Fedora 41+ (dnf5)

```bash
sudo dnf config-manager addrepo --from-repofile=https://rootcoder007.github.io/apt-morie/rpm/morie.repo
sudo dnf install morie
sudo dnf install rmorie rmoriedata rmoriebricklayer   # R packages
# after a key change: sudo rpm --import https://rootcoder007.github.io/apt-morie/key.gpg
```

## Install — Fedora ≤ 40 / RHEL 8-9 (dnf4)

```bash
sudo dnf config-manager --add-repo https://rootcoder007.github.io/apt-morie/rpm/morie.repo
sudo dnf install morie
```

## Install — older RHEL / CentOS (yum)

```bash
sudo yum-config-manager --add-repo https://rootcoder007.github.io/apt-morie/rpm/morie.repo
sudo yum install morie
```

## R packages: what they need

The R packages carry no R code themselves: installing one installs the
package of that name from r-universe (and its dependencies from CRAN) into
R's site library and compiles it on your machine, so the first install takes
a few minutes. Removing the package removes it from the library again.

| Package | Needs R | Debian / Ubuntu | Fedora / RHEL |
|---|---|---|---|
| `rmoriebricklayer` | 4.1 or later | Debian 12+, Ubuntu 22.04+ | Fedora, EPEL 9/10 |
| `rmoriedata`, `rmorie` | 4.3 or later | Debian 13+, Ubuntu 24.04+ | Fedora, EPEL 9/10 |

On RHEL and its rebuilds, enable EPEL and CRB first (`dnf install epel-release`,
`dnf config-manager --set-enabled crb`).

## Verification

Everything is authenticated against the project GPG key (`key.gpg`):

- apt: detached + clearsigned repository metadata (`Release.gpg`, `InRelease`)
- rpm: per-package `rpmsign` signatures **and** a detached `repodata/repomd.xml.asc`

## How this repository is published

Two workflows write to it:

- **morie** — morie's own `release-debrpm.yml` builds the `morie`
  packages on each morie release and pushes them here.
- **rmorie, rmoriedata, rmoriebricklayer** — this repository's
  [`publish.yml`](.github/workflows/publish.yml), every 6 hours and on
  every push, builds the wrapper of each version r-universe serves that
  the pool lacks ([`packaging/`](packaging/)).

Whichever of them ran last, `publish.yml` then rebuilds the apt and dnf
metadata from every package in the pool ([`packaging/reindex.sh`](packaging/reindex.sh))
and signs it, so a morie release never drops the R packages. The pool
keeps only the newest version of each package and architecture
([`packaging/latest.py`](packaging/latest.py)); older files are removed
first. It skips a run with nothing to do, re-signs any package the key
does not verify (after a key change), and refuses to sign with any key but
the one in `key.gpg`. Signing uses the `GPG_PRIVATE_KEY` and
`GPG_PASSPHRASE` repository secrets; without them it publishes nothing.

Generated (do not hand-edit): `apt/`, `rpm/`. Hand-maintained: `key.gpg`,
`index.html`, `README.md`, `CITATION.cff`, `packaging/`,
`.github/workflows/`.

## The MORIE ecosystem

| Component | What | Install from |
|---|---|---|
| [morie](https://github.com/rootcoder007/morie) | Python + R toolkit | [PyPI](https://pypi.org/project/morie/) · [Homebrew](https://github.com/rootcoder007/homebrew-morie) · apt/dnf (here) · container |
| [rmorie](https://github.com/rootcoder007/rmorie) | R-only lite package | [r-universe](https://rootcoder007.r-universe.dev) · apt/dnf (here) |
| [rmoriedata](https://github.com/rootcoder007/rmoriedata) | Integrated datasets for rmorie | r-universe · apt/dnf (here) |
| [rmorie-bricklayer](https://github.com/rootcoder007/rmorie-bricklayer) | Reproducible data capsules with provenance | r-universe · apt/dnf (here) |

## License and citation

morie is licensed **AGPL-3.0-or-later**. To cite the software, see
[`CITATION.cff`](CITATION.cff) (BibTeX in the
[morie README](https://github.com/rootcoder007/morie#citation)).
