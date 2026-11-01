#!/usr/bin/env python3
"""Print the newest file of each package and architecture.

    latest.py FILE...      one path per line, oldest versions left out
    latest.py --old FILE...  the paths latest.py would leave out

Files are .deb (name_version_arch.deb) or .rpm (name-version.arch.rpm, or name-version-release.arch.rpm).
Versions compare as dotted numbers with any letters split off, which is
enough for the versions this repository carries (1.5.2, 0.9.5.13, 1.0-12).
"""
import os
import re
import sys


def key(v):
    return [(0, int(p)) if p.isdigit() else (1, p) for p in re.findall(r"\d+|[a-z]+", v.lower())]


def split(path):
    b = os.path.basename(path)
    if b.endswith(".deb"):
        name, ver, arch = b[:-4].split("_")
        return name, arch, ver
    # name-version.arch.rpm, or name-version-release.arch.rpm
    m = re.match(r"^(.+?)-(\d[^-]*)(?:-([^-]+))?\.([^.]+)\.rpm$", b)
    if not m:
        sys.exit(f"latest.py: cannot parse {b}")
    ver = m.group(2) + ("-" + m.group(3) if m.group(3) else "")
    return m.group(1), m.group(4), ver


def main(args):
    old = args[:1] == ["--old"]
    if old:
        args = args[1:]
    best = {}
    for p in args:
        name, arch, ver = split(p)
        k = (name, arch)
        if k not in best or key(ver) > key(best[k][0]):
            best[k] = (ver, p)
    keep = {p for _, p in best.values()}
    for p in args:
        if (p in keep) != old:
            print(p)


if __name__ == "__main__":
    main(sys.argv[1:])
