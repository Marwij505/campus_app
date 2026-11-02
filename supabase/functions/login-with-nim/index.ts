// Login NIM dipetakan secara privat. Password hanya diperiksa oleh Supabase Auth.
import { createClient } from "npm:@supabase/supabase-js@2.99.2";
const headers = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Cache-Control": "no-store" };
const reply = (status: number, data: unknown) => new Response(JSON.stringify(data), { status, headers: { ...headers, "Content-Type": "application/json" } });
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers });
  if (req.method !== "POST") return reply(405, { message: "Metode tidak tersedia." });
  try {
    const raw = await req.text();
    if (raw.length > 4096) return reply(400, { message: "Masukan terlalu panjang." });
    const { nim, password } = JSON.parse(raw);
    if (typeof nim !== "string" || !/^[0-9]{8,20}$/.test(nim) || typeof password !== "string" || password.length < 1 || password.length > 256)
      return reply(401, { message: "NIM atau password salah." });
    const url = Deno.env.get("SUPABASE_URL")!;
    const secret = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(url, secret, { auth: { persistSession: false, autoRefreshToken: false } });
    // Hash menjaga identitas/IP tidak tersimpan sebagai teks pada pencatat batas.
    async function allowed(value: string, limit: number) {
      const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(secret + value));
      const key = Array.from(new Uint8Array(digest), x => x.toString(16).padStart(2, "0")).join("");
      const { data, error } = await admin.rpc("consume_login_attempt", { p_key: key, p_limit: limit });
      if (error) throw error;
      return data === true;
    }
    const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
    if (!(await allowed("ip:" + ip, 40)) || !(await allowed("nim:" + nim, 8)))
      return reply(429, { message: "Terlalu banyak percobaan. Coba lagi setelah 15 menit." });
    const { data: email, error: lookupError } = await admin.rpc("resolve_student_login", { p_nim: nim });
    if (lookupError) throw lookupError;
    const auth = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, { auth: { persistSession: false, autoRefreshToken: false } });
    // Identitas tidak ditemukan tetap menempuh pemeriksaan Auth agar pesan seragam.
    const { data, error } = await auth.auth.signInWithPassword({ email: email ?? "unregistered@invalid.invalid", password });
    if (error || !email || !data.session) return reply(401, { message: "NIM atau password salah." });
    const payload = JSON.parse(atob(data.session.access_token.split(".")[1].replace(/-/g,"+").replace(/_/g,"/")));
    const { data: timing, error: timingError } = await admin.rpc("register_profile_session", { p_session: payload.session_id, p_user: data.user.id });
    if (timingError) { await auth.auth.signOut(); throw timingError; }
    return reply(200, { refresh_token: data.session.refresh_token, ...timing });
  } catch {
    // Token, password, dan pesan internal database tidak masuk log atau respons.
    return reply(503, { message: "Layanan login belum dapat dihubungi. Coba lagi." });
  }
});
