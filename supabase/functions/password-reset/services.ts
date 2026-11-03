import { createClient } from "npm:@supabase/supabase-js@2.99.2";
import type { ResetDependencies } from "./handler.ts";

// Konfigurasi hanya di server. Transport dapat diganti saat tes tanpa email/akun nyata.
export interface ResetConfig {
  url: string;
  serviceKey: string;
  anonKey: string;
  resendKey: string;
  sender: string;
  secret: string;
}
export function createDependencies(
  config: ResetConfig,
  transport: typeof fetch = fetch,
): ResetDependencies {
  const { url, serviceKey, anonKey, resendKey, sender, secret } = config;
  const options = {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { fetch: transport },
  };
  const admin = createClient(url, serviceKey, options);
  async function rpc(name: string, params: Record<string, unknown>) {
    const { data, error } = await admin.rpc(name, params);
    if (error) throw new Error("database");
    return data;
  }

  return {
    configured: Boolean(resendKey && sender && secret.length >= 32 && anonKey),
    secret,
    allowed: (key, limit) =>
      rpc("consume_login_attempt", { p_key: key, p_limit: limit }),
    issue: (email, key, hash, id) =>
      rpc("issue_password_reset", {
        p_email: email,
        p_key: key,
        p_digest: hash,
        p_id: id,
      }),
    cancel: async (key, id) => {
      await rpc("cancel_password_reset", { p_key: key, p_id: id });
    },
    consume: (email, key, hash) =>
      rpc("consume_password_reset", {
        p_email: email,
        p_key: key,
        p_digest: hash,
      }),
    background: (task) => {
      // Supabase menjaga tugas email tetap hidup setelah respons HTTP dikembalikan.
      (globalThis as unknown as {
        EdgeRuntime: { waitUntil(task: Promise<void>): void };
      }).EdgeRuntime.waitUntil(task);
    },
    send: async (email, code, id) => {
      const response = await transport("https://api.resend.com/emails", {
        method: "POST",
        signal: AbortSignal.timeout(15000),
        headers: {
          Authorization: `Bearer ${resendKey}`,
          "Content-Type": "application/json",
          "Idempotency-Key": id,
        },
        body: JSON.stringify({
          from: sender,
          to: [email],
          subject: "Kode pemulihan Campus App",
          text:
            `Kode pemulihan Campus App: ${code}\n\nBerlaku 10 menit, hanya sekali pakai. Masukkan di aplikasi untuk mengganti password. Jangan bagikan kode ini. Jika tidak meminta pemulihan, abaikan email ini.`,
        }),
      });
      await response.body?.cancel();
      if (!response.ok) throw new Error("delivery");
    },
    reset: async (userId, email, password) => {
      // Link internal tidak dikirim ke mahasiswa. OTP kustom sudah diverifikasi database.
      const { data: link, error: linkError } = await admin.auth.admin
        .generateLink({ type: "recovery", email });
      if (linkError || link.user?.id !== userId) throw new Error("recovery");
      const recovery = createClient(url, anonKey, options);
      const { data, error } = await recovery.auth.verifyOtp({
        type: "recovery",
        token_hash: link.properties.hashed_token,
      });
      if (error || data.user?.id !== userId || !data.session) {
        throw new Error("verification");
      }
      try {
        // Terapkan kebijakan password Supabase, lalu cabut seluruh sesi lama.
        await rpc("revoke_password_reset_sessions", { p_user: userId });
        const updated = await recovery.auth.updateUser({ password });
        if (updated.error) throw new Error("password-policy");
        const signedOut = await admin.auth.admin.signOut(
          data.session.access_token,
          "global",
        );
        if (signedOut.error) throw new Error("signout");
        await rpc("revoke_password_reset_sessions", { p_user: userId });
      } finally {
        await recovery.auth.signOut({ scope: "local" });
      }
    },
  };
}
