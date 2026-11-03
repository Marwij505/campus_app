// SDK Supabase asli dengan HTTP tiruan: password dan email nyata tidak disentuh.
import { createDependencies } from "./services.ts";

function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
function fixture(failure = "") {
  const calls: {
    path: string;
    body: Record<string, unknown>;
    auth: string | null;
  }[] = [];
  const user = {
    id: "00000000-0000-4000-8000-000000000001",
    email: "student@example.test",
    aud: "authenticated",
    created_at: new Date().toISOString(),
  };
  const jwt = `${btoa("{}")}.${
    btoa(
      JSON.stringify({
        sub: user.id,
        exp: Math.floor(Date.now() / 1000) + 3600,
      }),
    )
  }.signature`;
  const transport: typeof fetch = async (input, init) => {
    const req = new Request(input, init);
    const url = new URL(req.url);
    const path = url.pathname + url.search;
    const body = req.method === "GET"
      ? {}
      : JSON.parse(await req.text() || "{}");
    calls.push({ path, body, auth: req.headers.get("authorization") });
    let data: unknown = {};
    let status = 200;
    if (url.hostname === "api.resend.com") {
      status = failure === "delivery" ? 422 : 200;
      data = { id: "mail-test" };
    } else if (path === "/auth/v1/admin/generate_link") {
      data = {
        ...user,
        id: failure === "identity-link" ? "other-user" : user.id,
        hashed_token: "internal-token",
        action_link: "https://unused.test",
        verification_type: "recovery",
      };
    } else if (path === "/auth/v1/verify") {
      data = {
        access_token: jwt,
        refresh_token: "test-refresh",
        expires_in: 3600,
        token_type: "bearer",
        user: {
          ...user,
          id: failure === "identity-session" ? "other-user" : user.id,
        },
      };
    } else if (path === "/auth/v1/user") {
      status = failure === "policy" ? 422 : 200;
      data = status === 200
        ? user
        : { msg: "password rejected", code: "weak_password" };
    } else if (path.startsWith("/auth/v1/logout")) {
      status = failure === "signout" && path.includes("global") ? 500 : 204;
    } else if (path.startsWith("/rest/v1/rpc/")) {
      data = true;
    } else throw new Error(`Unexpected request ${path}`);
    return new Response(status === 204 ? null : JSON.stringify(data), {
      status,
      headers: { "Content-Type": "application/json" },
    });
  };
  const deps = createDependencies({
    url: "https://example.test",
    serviceKey: "test-server-key",
    anonKey: "test-client-key",
    resendKey: "test-mail-key",
    sender: "Campus App <noreply@example.test>",
    secret: "test-only-secret-at-least-32-characters",
  }, transport);
  return { deps, calls, user };
}
async function rejects(task: Promise<unknown>) {
  let rejected = false;
  try {
    await task;
  } catch {
    rejected = true;
  }
  assert(rejected, "Must fail closed");
}

Deno.test("Adapter Resend mengirim kode sebagai teks dengan pengirim dan idempotency", async () => {
  const f = fixture();
  await f.deps.send(f.user.email, "AB3C4D", "request-1");
  assert(f.calls.length === 1);
  assert(f.calls[0].auth === "Bearer test-mail-key");
  assert(String(f.calls[0].body.text).includes("AB3C4D"));
  assert(f.calls[0].body.from === "Campus App <noreply@example.test>");
  await rejects(
    fixture("delivery").deps.send(f.user.email, "AB3C4D", "request-2"),
  );
});
Deno.test("Adapter reset menjalankan recovery, kebijakan password, pencabutan sesi dan logout", async () => {
  const f = fixture();
  await f.deps.reset(f.user.id, f.user.email, "new-test-password");
  assert(
    f.calls.map((c) => c.path).join("|") === [
      "/auth/v1/admin/generate_link",
      "/auth/v1/verify",
      "/rest/v1/rpc/revoke_password_reset_sessions",
      "/auth/v1/user",
      "/auth/v1/logout?scope=global",
      "/rest/v1/rpc/revoke_password_reset_sessions",
      "/auth/v1/logout?scope=local",
    ].join("|"),
  );
  assert(f.calls[3].body.password === "new-test-password");
  assert(f.calls[1].body.token_hash === "internal-token");
  assert(f.calls[3].auth !== "Bearer test-server-key");
});
Deno.test("Identitas hasil recovery harus cocok sebelum password diubah", async () => {
  for (const reason of ["identity-link", "identity-session"]) {
    const f = fixture(reason);
    await rejects(f.deps.reset(f.user.id, f.user.email, "new-test-password"));
    assert(!f.calls.some((c) => c.path === "/auth/v1/user"));
  }
});
Deno.test("Kebijakan password dan kegagalan pencabutan sesi tidak dilaporkan sukses", async () => {
  for (const reason of ["policy", "signout"]) {
    const f = fixture(reason);
    await rejects(f.deps.reset(f.user.id, f.user.email, "new-test-password"));
    assert(f.calls.at(-1)?.path === "/auth/v1/logout?scope=local");
  }
});
