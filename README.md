# apt-morie

**Signed apt *and* dnf repository for [morie](https://github.com/rootcoder007/morie)**, served from GitHub Pages at <https://rootcoder007.github.io/apt-morie/>.

Despite the name, this one repository serves **both** package ecosystems:

| Path | Ecosystem | Contents |
|---|---|---|
| [`apt/`](https://rootcoder007.github.io/apt-morie/apt/) | Debian / Ubuntu | `.deb` pool + signed `Release`/`InRelease` (`amd64`, `arm64`) |
| [`rpm/`](https://rootcoder007.github.io/apt-morie/rpm/) | Fedora / RHEL / openSUSE | signed `.rpm` packages + `repodata/` + [`morie.repo`](https://rootcoder007.github.io/apt-morie/rpm/morie.repo) (`x86_64`, `aarch64`) |
| [`key.gpg`](https://rootcoder007.github.io/apt-morie/key.gpg) | both | ASCII-armored public signing key |

## Install — Debian / Ubuntu (apt)

```bash
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://rootcoder007.github.io/apt-morie/key.gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/rootcoder007.gpg
echo "deb [signed-by=/etc/apt/keyrings/rootcoder007.gpg] https://rootcoder007.github.io/apt-morie/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/morie.list
sudo apt update && sudo apt install morie
```

## Install — Fedora 41+ (dnf5)

```bash
sudo dnf config-manager addrepo --from-repofile=https://rootcoder007.github.io/apt-morie/rpm/morie.repo
sudo dnf install morie
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

## How this repository is maintained

The `apt/`, `rpm/`, `key.gpg`, and `index.html` artifacts are **generated** —
published automatically by [morie's `release-debrpm.yml` workflow](https://github.com/rootcoder007/morie/blob/main/.github/workflows/release-debrpm.yml)
on every `v*` tag (deb + rpm are built from the morie wheel via fpm, signed, and
deployed here cross-repo). Do not hand-edit them; changes belong in the morie
repository. Only this README, `AGENTS.md`, and `CITATION.cff` are maintained by
hand.

## The MORIE ecosystem

| Component | What | Install from |
|---|---|---|
| [morie](https://github.com/rootcoder007/morie) | Python + R toolkit (this repo packages its CLI) | [PyPI](https://pypi.org/project/morie/) · [Homebrew](https://github.com/rootcoder007/homebrew-morie) · apt/dnf (here) · container |
| [rmorie](https://github.com/rootcoder007/rmorie) | R-only lite package | [r-universe](https://rootcoder007.r-universe.dev) |
| [rmoriedata](https://github.com/rootcoder007/rmoriedata) | Integrated datasets for rmorie | r-universe |
| [rmorie-bricklayer](https://github.com/rootcoder007/rmorie-bricklayer) | Reproducible data capsules with provenance | r-universe |

## License and citation

morie is licensed **AGPL-3.0-or-later**. To cite the software, see
[`CITATION.cff`](CITATION.cff) (BibTeX in the
[morie README](https://github.com/rootcoder007/morie#citation)).
