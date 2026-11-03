import { createHandler } from "./handler.ts";
import { createDependencies } from "./services.ts";

// Secrets dibaca oleh server, tidak disertakan pada build Flutter maupun repositori.
Deno.serve(createHandler(createDependencies({
  url: Deno.env.get("SUPABASE_URL") ?? "",
  serviceKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  anonKey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
  resendKey: Deno.env.get("RESEND_API_KEY") ?? "",
  sender: Deno.env.get("RESET_EMAIL_FROM") ?? "",
  secret: Deno.env.get("RESET_OTP_SECRET") ?? "",
})));
