import { createHandler, type FileDependencies } from "./handler.ts";
const owner = "11111111-1111-4111-8111-111111111111";
const path = `${owner}/fixture.pdf`;
const bytes = new Uint8Array([1, 2, 3]);
function fixture(overrides: Partial<FileDependencies> = {}) {
  let downloads = 0;
  const handler = createHandler({
    user: () => Promise.resolve(owner),
    authorized: () => Promise.resolve(true),
    download: () => {
      downloads++;
      return Promise.resolve(new Blob([bytes]));
    },
    active: () => Promise.resolve(true),
    ...overrides,
  });
  const request = (
    body: unknown = { bucket: "student-documents", path },
    token = "test-token",
    method = "POST",
  ) =>
    handler(
      new Request("https://fixture.test", {
        method,
        headers: token ? { Authorization: `Bearer ${token}` } : {},
        body: method === "POST" ? JSON.stringify(body) : undefined,
      }),
    );
  return { request, downloads: () => downloads };
}
const assert = (ok: unknown) => {
  if (!ok) throw new Error("assertion failed");
};
Deno.test("private-file: owner receives exact bytes, no-store, POST only", async () => {
  const f = fixture();
  const r = await f.request();
  assert(
    r.status === 200 && r.headers.get("cache-control")?.includes("no-store"),
  );
  assert(r.headers.get("content-type") === "application/octet-stream");
  assert(new Uint8Array(await r.arrayBuffer()).join() === bytes.join());
  assert((await f.request(undefined, "", "OPTIONS")).status === 200);
  assert((await f.request(undefined, "test", "GET")).status === 405);
});
Deno.test("private-file: missing or forged JWT never downloads", async () => {
  const f = fixture({ user: () => Promise.resolve(null) });
  assert((await f.request(undefined, "")).status === 401);
  assert((await f.request()).status === 401);
  assert(f.downloads() === 0);
});
Deno.test("private-file: foreign owner, traversal, bucket and oversized input rejected", async () => {
  const f = fixture();
  for (
    const body of [{ bucket: "other", path }, {
      bucket: "student-documents",
      path: `${owner}/../x`,
    }, { bucket: "student-documents", path: "x".repeat(5000) }]
  ) assert((await f.request(body)).status === 400);
  assert(
    (await f.request({
      bucket: "student-documents",
      path: "22222222-2222-4222-8222-222222222222/fixture.pdf",
    })).status === 403,
  );
  assert(f.downloads() === 0);
});
Deno.test("private-file: expired/revoked/disabled session or absent metadata denies before fetch", async () => {
  const f = fixture({ authorized: () => Promise.resolve(false) });
  assert((await f.request()).status === 403);
  assert(f.downloads() === 0);
});
Deno.test("private-file: revocation during fetch does not release bytes", async () => {
  const f = fixture({ active: () => Promise.resolve(false) });
  assert((await f.request()).status === 403);
  assert(f.downloads() === 1);
});
Deno.test("private-file: upstream failure is opaque and never returns bytes", async () => {
  const f = fixture({
    download: () => {
      throw new Error("sensitive upstream detail");
    },
  });
  const r = await f.request();
  assert(r.status === 503);
  assert(!(await r.text()).includes("sensitive"));
});
Deno.test("private-file: oversized document rejected; avatar bounded separately", async () => {
  const f = fixture({
    download: () => Promise.resolve(new Blob([new Uint8Array(524289)])),
  });
  assert((await f.request()).status === 404);
  assert((await f.request({ bucket: "student-avatars", path })).status === 200);
  const large = fixture({
    download: () => Promise.resolve(new Blob([new Uint8Array(2097153)])),
  });
  assert(
    (await large.request({ bucket: "student-avatars", path })).status === 404,
  );
});
