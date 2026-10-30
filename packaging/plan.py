#!/usr/bin/env python3
"""What publish.yml builds, and whether the index is complete.

    plan.py PACKAGES     one line per R package r-universe serves:
                         "<pkg> <version> <R floor> <needs,comma,list>"
    plan.py --complete   exit 0 when the apt and dnf indexes list every
                         package in the pool, 1 when they do not
"""
import glob
import gzip
import os
import re
import sys

PKGS = ("rmoriebricklayer", "rmoriedata", "rmorie")  # build order


def stanzas(text):
    for block in re.split(r"\n\s*\n", text):
        fields, key = {}, None
        for line in block.splitlines():
            if line[:1] in (" ", "\t") and key:
                fields[key] += " " + line.strip()
            elif ":" in line:
                key, val = line.split(":", 1)
                fields[key] = val.strip()
        if fields:
            yield fields


def plan(path):
    found = {}
    for f in stanzas(open(path, encoding="utf-8").read()):
        if f.get("Package") in PKGS:
            found[f["Package"]] = f
    for pkg in PKGS:
        f = found.get(pkg)
        if f is None:
            sys.exit(f"plan.py: {pkg} is not in {path}")
        m = re.search(r"\bR\s*\(>=\s*([0-9.]+)\)", f.get("Depends", ""))
        floor = m.group(1) if m else "4.3"
        deps = re.findall(r"[A-Za-z][A-Za-z0-9.]*",
                          re.sub(r"\([^)]*\)", "", f.get("Imports", "") +
                                 "," + f.get("LinkingTo", "")))
        needs = sorted(set(d for d in deps if d in PKGS and d != pkg))
        print(pkg, f["Version"], floor, ",".join(needs) or "-")


def complete():
    pool = set(os.path.basename(p) for p in glob.glob("apt/pool/main/*.deb"))
    for arch in ("amd64", "arm64"):
        want = set(p for p in pool if p.endswith(("_%s.deb" % arch, "_all.deb")))
        try:
            text = open("apt/dists/stable/main/binary-%s/Packages" % arch).read()
        except OSError:
            return False
        have = set(os.path.basename(m) for m in
                   re.findall(r"^Filename: (\S+)", text, re.M))
        if want != have:
            return False
    rpms = set(os.path.basename(p) for p in glob.glob("rpm/packages/*.rpm"))
    prim = glob.glob("rpm/repodata/*primary.xml.gz")
    if len(prim) != 1:
        return False
    with gzip.open(prim[0], "rt", encoding="utf-8") as fh:
        hrefs = set(os.path.basename(h) for h in
                    re.findall(r'<location href="([^"]+)"', fh.read()))
    return rpms == hrefs and os.path.exists("rpm/repodata/repomd.xml.asc")


if __name__ == "__main__":
    if sys.argv[1:] == ["--complete"]:
        sys.exit(0 if complete() else 1)
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    plan(sys.argv[1])
