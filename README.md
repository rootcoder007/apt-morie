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
| [`rpm/`](https://rootcoder007.github.io/apt-morie/rpm/) | Fedora / RHEL / openSUSE | signed `.rpm` packages + `repodata/` + [`morie.repo`](https://rootcoder007.github.io/apt-morie/rpm/morie.repo) |
| [`key.gpg`](https://rootcoder007.github.io/apt-morie/key.gpg) | both | ASCII-armored public signing key |

## Install — Debian / Ubuntu (apt)

```bash
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://rootcoder007.github.io/apt-morie/key.gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/rootcoder007.gpg
echo "deb [signed-by=/etc/apt/keyrings/rootcoder007.gpg] https://rootcoder007.github.io/apt-morie/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/morie.list
sudo apt update
sudo apt install morie                                # Python toolkit
sudo apt install rmorie rmoriedata rmoriebricklayer   # R packages (needs r-base >= 4.3)
```

## Install — Fedora 41+ (dnf5)

```bash
sudo dnf config-manager addrepo --from-repofile=https://rootcoder007.github.io/apt-morie/rpm/morie.repo
sudo dnf install morie
sudo dnf install rmorie rmoriedata rmoriebricklayer   # R packages (needs R >= 4.3)
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

## Verification

Everything is authenticated against the project GPG key (`key.gpg`):

- apt: detached + clearsigned repository metadata (`Release.gpg`, `InRelease`)
- rpm: per-package `rpmsign` signatures **and** a detached `repodata/repomd.xml.asc`

## How this repository publishes (self-contained)

The pipeline lives **in this repository**: [`.github/workflows/publish.yml`](.github/workflows/publish.yml)
polls PyPI and r-universe (every 6 h, or on manual dispatch), and for any
version not yet in the pool it builds the wrapper packages from
[`packaging/`](packaging/), signs them, regenerates the apt + dnf metadata,
and deploys to this repo's own GitHub Pages with the default `GITHUB_TOKEN`.

- It proceeds **only when the artifact is live on its registry**, so
  publish-before-registry races are impossible by construction.
- It is **idempotent** — versions already in the pool are skipped.
- It is **inert until** `GPG_PRIVATE_KEY` + `GPG_PASSPHRASE` exist as repo
  secrets.

Generated at publish time (do not hand-edit): `apt/`, `rpm/`, `key.gpg`.
Hand-maintained here: `index.html` (re-asserted on every publish), `README.md`,
`AGENTS.md`, `CITATION.cff`, `packaging/`.

> Transitional note: morie's own `release-debrpm.yml` also still publishes
> here on each `v*` tag; it can be decommissioned once this pipeline is
> confirmed in production.

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
