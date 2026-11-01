// node test/index.test.mjs: R2 first, then Pages; paths cleaned; methods limited.
import assert from "node:assert/strict";
import worker, { cleanPath, ttl } from "../src/index.js";

// paths
assert.equal(cleanPath("/"), "/index.html");
assert.equal(cleanPath("/apt/dists/stable/InRelease"), "/apt/dists/stable/InRelease");
assert.equal(cleanPath("/apt/../key.gpg"), null);
assert.equal(cleanPath("/apt/%2e%2e/key.gpg"), null);
assert.equal(cleanPath("/a//b"), null);
assert.equal(cleanPath("/%zz"), null);

// fake R2 holding one large package
const big = new TextEncoder().encode("R2 BYTES");
const objs = new Map([["apt-morie/apt/pool/bookworm/r-cran-rmorie_1.5.2_amd64.deb", big]]);
const MIRROR = {
  async get(k) {
    if (!objs.has(k)) return null;
    const b = objs.get(k);
    return { size: b.length, httpEtag: '"e1"', body: new Blob([b]).stream(), writeHttpMetadata() {} };
  },
};
// fake Pages
const seen = [];
globalThis.fetch = async (url, init) => {
  seen.push([url, init.method, init.cf]);
  if (url.includes("/key.gpg?")) return new Response("PAGES KEY", { status: 200, headers: { "content-length": "9" } });
  return new Response("nope", { status: 404 });
};
const env = { MIRROR };
const get = (p, m = "GET") => worker.fetch(new Request("https://apt.rmorie.com" + p, { method: m }), env);

let r = await get("/apt/pool/bookworm/r-cran-rmorie_1.5.2_amd64.deb");
assert.equal(r.status, 200);
assert.equal(r.headers.get("x-served-from"), "r2");
assert.equal(r.headers.get("content-type"), "application/vnd.debian.binary-package");
assert.match(r.headers.get("cache-control"), /max-age=86400/);
assert.equal(await r.text(), "R2 BYTES");
assert.equal(seen.length, 0, "an R2 hit never asks Pages");

r = await get("/key.gpg");
assert.equal(r.status, 200);
assert.equal(r.headers.get("x-served-from"), "pages");
assert.match(r.headers.get("cache-control"), /max-age=300/);
assert.equal(await r.text(), "PAGES KEY");
assert.match(seen.at(-1)[0], /^https:\/\/rootcoder007\.github\.io\/apt-morie\/key\.gpg\?g=\d+$/);

r = await get("/apt/dists/stable/nothing");
assert.equal(r.status, 404);
assert.equal(r.headers.get("cache-control"), "no-store");

r = await get("/key.gpg", "HEAD");
assert.equal(r.status, 200);
assert.equal(await r.text(), "");

r = await get("/key.gpg", "POST");
assert.equal(r.status, 405);
// the URL parser resolves %2e%2e before the Worker sees it: /apt/%2e%2e/x is /x, inside the repo
r = await get("/apt/%2e%2e/x");
assert.equal(r.status, 404);
assert.equal(seen.at(-1)[0], "https://rootcoder007.github.io/apt-morie/x?g=3");

// the site page is held at the edge as briefly as the indexes; packages a day
assert.equal(ttl("/index.html"), 300);
assert.equal(ttl("/apt/dists/stable/InRelease"), 300);
assert.equal(ttl("/apt/pool/bookworm/r-cran-rmorie_1.5.2_amd64.deb"), 86400);
r = await get("/");
assert.match(seen.at(-1)[0], /^https:\/\/rootcoder007\.github\.io\/apt-morie\/index\.html\?g=\d+$/);
assert.equal(seen.at(-1)[2].cacheTtl, 300);

// no R2 binding at all: Pages answers
r = await worker.fetch(new Request("https://apt.rmorie.com/key.gpg"), {});
assert.equal(r.headers.get("x-served-from"), "pages");
console.log("apt worker: ok");
