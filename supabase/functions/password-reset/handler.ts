import { codeValid, createCode, digest, emailValid } from "./otp.ts";

// Adapter dipisah agar pengujian tidak mengirim email atau mengganti akun nyata.
export interface ResetDependencies {
  configured: boolean;
  secret: string;
  allowed(key: string, limit: number): Promise<boolean>;
  issue(
    email: string,
    key: string,
    hash: string,
    id: string,
  ): Promise<{ accepted: boolean; user_id: string | null }>;
  cancel(key: string, id: string): Promise<void>;
  consume(email: string, key: string, hash: string): Promise<string | null>;
  send(email: string, code: string, id: string): Promise<void>;
  reset(userId: string, email: string, password: string): Promise<void>;
  background(task: Promise<void>): void;
}
const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "no-store",
  "Content-Type": "application/json",
};
const reply = (status: number, message: string) =>
  new Response(JSON.stringify({ message }), { status, headers });

// Membaca bertahap membatasi alokasi memori, termasuk request tanpa Content-Length.
async function readBody(request: Request): Promise<Record<string, unknown>> {
  const reader = request.body?.getReader();
  if (!reader) throw new Error("body");
  let size = 0;
  const chunks: Uint8Array[] = [];
  try {
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.length;
      if (size > 4096) {
        await reader.cancel();
        throw new Error("size");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  const result = JSON.parse(new TextDecoder().decode(bytes));
  if (!result || typeof result !== "object" || Array.isArray(result)) {
    throw new Error("body");
  }
  return result;
}

export function createHandler(deps: ResetDependencies) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") return reply(200, "ok");
    if (request.method !== "POST") return reply(405, "Metode tidak tersedia.");
    let body: Record<string, unknown>;
    try {
      body = await readBody(request);
    } catch {
      return reply(400, "Masukan tidak valid.");
    }
    const email = typeof body.email === "string"
      ? body.email.trim().toLowerCase()
      : "";
    if (!emailValid(email)) return reply(400, "Alamat email belum valid.");
    if (body.action !== "request" && body.action !== "confirm") {
      return reply(400, "Aksi tidak valid.");
    }
    const code = typeof body.code === "string"
      ? body.code.trim().toUpperCase()
      : "";
    const password = typeof body.password === "string" ? body.password : "";
    if (
      body.action === "confirm" &&
      (!codeValid(code) || password.length < 12 || password.length > 256)
    ) {
      return reply(400, "Periksa kode dan password baru (12–256 karakter).");
    }
    // Konfigurasi dicek untuk SEMUA alamat: kegagalannya tidak mengungkap akun terdaftar.
    if (!deps.configured) {
      return reply(
        503,
        "Layanan email pemulihan belum siap. Hubungi pengelola.",
      );
    }
    try {
      const ip =
        request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
        "unknown";
      const key = await digest(deps.secret, "reset-email", email);
      const ipKey = await digest(deps.secret, "reset-ip", ip);
      const actionKey = await digest(
        deps.secret,
        `reset-${body.action}`,
        email,
      );
      if (
        !(await deps.allowed(ipKey, 40)) ||
        !(await deps.allowed(actionKey, body.action === "request" ? 5 : 10))
      ) {
        return reply(
          429,
          "Terlalu banyak percobaan. Coba lagi setelah 15 menit.",
        );
      }
      if (body.action === "request") {
        const otp = createCode(), id = crypto.randomUUID();
        const hash = await digest(deps.secret, "reset-code", `${email}:${otp}`);
        const issued = await deps.issue(email, key, hash, id);
        if (issued.accepted && issued.user_id) {
          // Respons tidak menunggu layanan email, sehingga waktu kirim tidak membocorkan akun.
          deps.background(
            deps.send(email, otp, id).catch(async () => {
              console.error("password-reset: delivery failed");
              await deps.cancel(key, id);
            }).catch(() => {
              console.error("password-reset: cancellation failed");
            }),
          );
        }
        return reply(
          200,
          "Jika email terdaftar dan memenuhi syarat, kode akan dikirim. Periksa kotak masuk dan spam.",
        );
      }
      const hash = await digest(deps.secret, "reset-code", `${email}:${code}`);
      const userId = await deps.consume(email, key, hash);
      if (!userId) {
        return reply(
          400,
          "Kode salah, kedaluwarsa, atau sudah dipakai. Minta kode baru bila diperlukan.",
        );
      }
      // Kode sekali pakai dikonsumsi sebelum Auth diperbarui; jangan kirim sesi ke aplikasi.
      await deps.reset(userId, email, password);
      return reply(
        200,
        "Password berhasil diganti. Silakan masuk dengan password baru.",
      );
    } catch {
      // Jangan sertakan email, kode, token, password, atau detail database pada log/respons.
      return reply(
        503,
        "Pemulihan belum dapat diselesaikan. Jika tadi mengirim kode, minta kode baru sebelum mencoba lagi.",
      );
    }
  };
}
