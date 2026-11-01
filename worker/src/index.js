// apt.rmorie.com: the morie apt + dnf repository.
//
// The repository is built and signed by .github/workflows/publish.yml and published two ways:
//  - GitHub Pages (https://rootcoder007.github.io/apt-morie/), which holds every file today;
//  - the R2 bucket morie-mirror under apt-morie/, for files too large for Pages (the prebuilt R
//    packages). The morie-mirror Worker copies them there, checking each hash.
// A request is answered from R2 when the file is there, else from Pages, so one address serves
// both and nothing changes for users when a file moves. apt and dnf check every file against
// the signed index (InRelease, repomd.xml.asc), so where a file came from does not matter to
// them; this Worker only has to serve the bytes unchanged.

const PAGES = "https://rootcoder007.github.io/apt-morie";
const PREFIX = "apt-morie";
// the signed indexes change on every publish; the packages never change under one name
const SHORT = 300;
const LONG = 86400;
// part of the edge cache key: raise it to drop every copy the edge holds from Pages
const GEN = 2;

const isIndex = (p) =>
  /\/(InRelease|Release|Release\.gpg|Packages(\.gz|\.xz)?)$/.test(p) ||
  p.startsWith("/rpm/repodata/") || p === "/rpm/morie.repo" || p === "/key.gpg";

export function cleanPath(raw) {
  let p;
  try {
    p = decodeURIComponent(raw);
  } catch {
    return null;
  }
  if (!p.startsWith("/") || p.includes("\0") || p.split("/").some((s) => s === ".." || s === ".")) return null;
  if (p.includes("//")) return null;
  return p === "/" ? "/index.html" : p;
}

const TYPES = {
  ".deb": "application/vnd.debian.binary-package",
  ".rpm": "application/x-rpm",
  ".gz": "application/gzip",
  ".xz": "application/x-xz",
  ".gpg": "application/pgp-keys",
  ".asc": "application/pgp-signature",
  ".xml": "application/xml",
  ".html": "text/html; charset=utf-8",
  ".css": "text/css",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".repo": "text/plain; charset=utf-8",
};
const typeOf = (p) => TYPES[Object.keys(TYPES).find((e) => p.endsWith(e))] || "application/octet-stream";

// the pages and indexes change on every publish; the packages never change under one name
export const ttl = (p) => (isIndex(p) || p.endsWith(".html") ? SHORT : LONG);

function cacheHeader(p) {
  return `public, max-age=${ttl(p)}`;
}

async function fromR2(env, p, req) {
  if (!env.MIRROR) return null;
  const o = await env.MIRROR.get(PREFIX + p, { range: req.headers, onlyIf: req.headers });
  if (!o) return null;
  const h = new Headers();
  o.writeHttpMetadata(h);
  h.set("etag", o.httpEtag);
  h.set("content-type", typeOf(p));
  h.set("cache-control", cacheHeader(p));
  h.set("x-served-from", "r2");
  if (!("body" in o) || !o.body) return new Response(null, { status: 304, headers: h });
  if (o.range) {
    const off = o.range.offset ?? 0;
    const len = o.range.length ?? o.size - off;
    h.set("content-range", `bytes ${off}-${off + len - 1}/${o.size}`);
    return new Response(req.method === "HEAD" ? null : o.body, { status: 206, headers: h });
  }
  return new Response(req.method === "HEAD" ? null : o.body, { status: 200, headers: h });
}

async function fromPages(p, req) {
  const fwd = new Headers();
  for (const k of ["range", "if-none-match", "if-modified-since"]) {
    const v = req.headers.get(k);
    if (v) fwd.set(k, v);
  }
  const r = await fetch(PAGES + p, {
    method: req.method,
    headers: fwd,
    cf: { cacheTtl: ttl(p), cacheEverything: true, cacheKey: `${PAGES}${p}?g=${GEN}` },
  });
  const h = new Headers();
  for (const k of ["content-length", "content-range", "etag", "last-modified", "accept-ranges"]) {
    const v = r.headers.get(k);
    if (v) h.set(k, v);
  }
  h.set("content-type", r.ok ? typeOf(p) : "text/plain; charset=utf-8");
  h.set("cache-control", r.ok ? cacheHeader(p) : "no-store");
  h.set("x-served-from", "pages");
  if (!r.ok && r.status !== 304 && r.status !== 206) {
    return new Response(r.status === 404 ? "not found\n" : `upstream answered ${r.status}\n`,
      { status: r.status === 404 ? 404 : 502, headers: h });
  }
  return new Response(req.method === "HEAD" ? null : r.body, { status: r.status, headers: h });
}

export default {
  async fetch(req, env) {
    if (req.method !== "GET" && req.method !== "HEAD") {
      return new Response("method not allowed\n", { status: 405, headers: { allow: "GET, HEAD" } });
    }
    const p = cleanPath(new URL(req.url).pathname);
    if (!p) return new Response("bad path\n", { status: 400 });
    const r2 = await fromR2(env, p, req);
    if (r2) return r2;
    return fromPages(p, req);
  },
};
