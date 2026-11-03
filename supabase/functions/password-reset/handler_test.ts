// Tes murni: tidak menyentuh akun, Resend, atau database produksi.
import { createHandler, type ResetDependencies } from "./handler.ts";
import { codeValid, createCode, digest } from "./otp.ts";
const assert = (condition: unknown, message = "assertion failed") => {
  if (!condition) throw new Error(message);
};
function fixture() {
  const calls: string[] = [], tasks: Promise<void>[] = [];
  let known = true, consumed = false, sentCode = "";
  const deps: ResetDependencies = {
    configured: true,
    secret: "test-only-secret-long-enough-12345678",
    allowed: () => Promise.resolve(true),
    issue: () =>
      Promise.resolve({ accepted: true, user_id: known ? "user-1" : null }),
    cancel: () => {
      calls.push("cancel");
      return Promise.resolve();
    },
    consume: () => {
      if (consumed) return Promise.resolve(null);
      consumed = true;
      return Promise.resolve("user-1");
    },
    send: (_, code) => {
      sentCode = code;
      calls.push("send");
      return Promise.resolve();
    },
    reset: () => {
      calls.push("reset");
      return Promise.resolve();
    },
    background: (task) => {
      tasks.push(task);
    },
  };
  const handle = createHandler(deps);
  return {
    deps,
    calls,
    tasks,
    unknown: () => {
      known = false;
    },
    code: () => sentCode,
    post: (body: unknown) =>
      handle(
        new Request("https://example.test", {
          method: "POST",
          body: JSON.stringify(body),
        }),
      ),
    handle,
  };
}
const request = { action: "request", email: "student@example.test" };
const confirm = {
  ...request,
  action: "confirm",
  code: "AB3C4D",
  password: "new-test-password",
};

Deno.test("Kode selalu enam karakter, campuran huruf besar dan angka", () => {
  const codes = new Set<string>();
  for (let i = 0; i < 2000; i++) {
    const code = createCode();
    assert(codeValid(code));
    codes.add(code);
  }
  assert(codes.size > 1990);
});
Deno.test("HMAC berbeda menurut secret, tujuan, email dan kode", async () => {
  const hashes = await Promise.all([
    digest("secret1", "code", "a:AB3C4D"),
    digest("secret2", "code", "a:AB3C4D"),
    digest("secret1", "email", "a:AB3C4D"),
    digest("secret1", "code", "b:AB3C4D"),
    digest("secret1", "code", "a:AB3C4E"),
  ]);
  assert(new Set(hashes).size === hashes.length);
  assert(hashes.every((h) => /^[a-f0-9]{64}$/.test(h)));
});
Deno.test("Email terdaftar/tidak terdaftar mendapat respons identik, hanya akun dikenal menerima email", async () => {
  const f = fixture();
  const yes = await f.post(request);
  await Promise.all(f.tasks);
  assert(codeValid(f.code()));
  f.unknown();
  const no = await f.post(request);
  assert(yes.status === no.status && await yes.text() === await no.text());
  assert(f.calls.filter((c) => c === "send").length === 1);
});
Deno.test("Kirim ulang saat cooldown tidak mengirim email kedua", async () => {
  const f = fixture();
  f.deps.issue = () => Promise.resolve({ accepted: false, user_id: null });
  assert((await f.post(request)).status === 200);
  assert(f.calls.length === 0);
});
Deno.test("Resend gagal membatalkan challenge tanpa membocorkan detail", async () => {
  const f = fixture();
  f.deps.send = () => Promise.reject(new Error("private provider detail"));
  const response = await f.post(request);
  await Promise.all(f.tasks);
  assert(response.status === 200);
  assert(f.calls.includes("cancel"));
  assert(!(await response.text()).includes("private"));
});
Deno.test("Kode valid sekali pakai, replay tidak mengganti password lagi", async () => {
  const f = fixture();
  assert((await f.post(confirm)).status === 200);
  assert((await f.post(confirm)).status === 400);
  assert(f.calls.filter((c) => c === "reset").length === 1);
});
Deno.test("Salah/kedaluwarsa/akun tidak memenuhi syarat tidak menyentuh Auth", async () => {
  const f = fixture();
  f.deps.consume = () => Promise.resolve(null);
  assert((await f.post(confirm)).status === 400);
  assert(f.calls.length === 0);
});
Deno.test("Rate limit menolak sebelum menerbitkan atau memakai kode", async () => {
  const f = fixture();
  f.deps.allowed = () => Promise.resolve(false);
  assert((await f.post(request)).status === 429);
  assert((await f.post(confirm)).status === 429);
  assert(f.calls.length === 0);
});
Deno.test("Konfigurasi kosong gagal seragam tanpa mengirim email", async () => {
  const f = fixture();
  f.deps.configured = false;
  assert((await f.post(request)).status === 503);
  assert(f.calls.length === 0);
});
Deno.test("Masukan berbahaya, format kode dan ukuran body dibatasi", async () => {
  const f = fixture();
  for (
    const body of [
      null,
      [],
      { ...request, email: "wrong" },
      { ...request, action: "unknown" },
      { ...confirm, code: "123456" },
      { ...confirm, code: "ABCDEF" },
      { ...confirm, password: "short" },
      { ...confirm, password: "a".repeat(257) },
      { ...request, extra: "a".repeat(5000) },
    ]
  ) {
    assert((await f.post(body)).status === 400);
  }
  assert(f.calls.length === 0);
});
Deno.test("CORS, metode dan error internal aman", async () => {
  const f = fixture();
  assert(
    (await f.handle(new Request("https://example.test", { method: "OPTIONS" })))
      .status === 200,
  );
  assert((await f.handle(new Request("https://example.test"))).status === 405);
  f.deps.reset = () => Promise.reject(new Error("secret"));
  const r = await f.post(confirm);
  assert(r.status === 503);
  assert(!(await r.text()).includes("secret"));
  assert(r.headers.get("Cache-Control") === "no-store");
});
