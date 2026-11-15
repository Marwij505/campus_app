import { createClient } from "npm:@supabase/supabase-js@2.99.2";
import { createHandler } from "./handler.ts";
const url = Deno.env.get("SUPABASE_URL")!;
const options = { auth: { persistSession: false, autoRefreshToken: false } };
const admin = createClient(
  url,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  options,
);
const scoped = (token: string) =>
  createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
    ...options,
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
Deno.serve(createHandler({
  async user(token) {
    const { data, error } = await admin.auth.getUser(token);
    return error ? null : data.user?.id ?? null;
  },
  async authorized(token, bucket, path) {
    // Both tables' SELECT policies check auth.uid + current application session.
    const client = scoped(token);
    const { data, error } = bucket === "student-documents"
      ? await client.from("student_documents").select("path").eq("path", path)
        .maybeSingle()
      : await client.from("profiles").select("avatar_path").eq(
        "avatar_path",
        path,
      ).maybeSingle();
    if (error) throw error;
    return data !== null;
  },
  async download(bucket, path) {
    // Admin only fetches an exact path AFTER owner + RLS authorization.
    const { data, error } = await admin.storage.from(bucket).download(path);
    if (error) throw error;
    return data;
  },
  async active(token) {
    const { data, error } = await scoped(token).rpc("profile_session_status");
    if (error) throw error;
    return data !== null;
  },
}));
