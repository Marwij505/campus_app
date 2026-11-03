// Alphabet 32 karakter menghindari I/O/0/1 yang mudah tertukar saat diketik.
const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
export const emailValid = (value: string) =>
  value.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
export const codeValid = (value: string) =>
  /^[A-Z0-9]{6}$/.test(value) && /[A-Z]/.test(value) && /[0-9]/.test(value);

export function createCode(): string {
  // Rejection sampling memastikan selalu ada huruf DAN angka, tanpa Math.random().
  for (;;) {
    const code = Array.from(
      crypto.getRandomValues(new Uint8Array(6)),
      (byte) => alphabet[byte & 31],
    ).join("");
    if (codeValid(code)) return code;
  }
}

export async function digest(
  secret: string,
  purpose: string,
  value: string,
): Promise<string> {
  // Pemisahan tujuan mencegah hash pembatas IP dipakai sebagai hash kode/email.
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const bytes = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(`${purpose}:${value}`),
  );
  return Array.from(
    new Uint8Array(bytes),
    (b) => b.toString(16).padStart(2, "0"),
  ).join("");
}
