export interface FileDependencies {
  user(token: string): Promise<string | null>;
  authorized(token: string, bucket: string, path: string): Promise<boolean>;
  download(bucket: string, path: string): Promise<Blob | null>;
  active(token: string): Promise<boolean>;
}
const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "private, no-store, max-age=0",
  "X-Content-Type-Options": "nosniff",
};
const reply = (status: number) =>
  new Response(
    JSON.stringify({ message: "Berkas tidak tersedia atau sesi berakhir." }),
    { status, headers: { ...headers, "Content-Type": "application/json" } },
  );
export function createHandler(deps: FileDependencies) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return new Response(null, { headers });
    if (req.method !== "POST") return reply(405);
    const token = req.headers.get("Authorization")?.match(/^Bearer (\S+)$/i)
      ?.[1];
    if (!token) return reply(401);
    try {
      // Bound input before collecting a complete request body.
      const reader = req.body?.getReader();
      if (!reader) return reply(400);
      const chunks: Uint8Array[] = [];
      let size = 0;
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        size += value.length;
        if (size > 4096) {
          await reader.cancel();
          return reply(400);
        }
        chunks.push(value);
      }
      let input: { bucket?: unknown; path?: unknown };
      try {
        const bytes = new Uint8Array(size);
        let offset = 0;
        for (const chunk of chunks) {
          bytes.set(chunk, offset);
          offset += chunk.length;
        }
        input = JSON.parse(new TextDecoder().decode(bytes));
      } catch {
        return reply(400);
      }
      const { bucket, path } = input ?? {};
      if (
        (bucket !== "student-documents" && bucket !== "student-avatars") ||
        typeof path !== "string" || path.length > 300 ||
        !/^[a-f0-9-]{36}\/[A-Za-z0-9_.-]+$/.test(path) || path.includes("..")
      ) return reply(400);
      // getUser validates the signature/server identity, not merely JWT decoding.
      const owner = await deps.user(token);
      if (!owner) return reply(401);
      if (
        path.split("/")[0] !== owner ||
        !await deps.authorized(token, bucket, path)
      ) return reply(403);
      const blob = await deps.download(bucket, path);
      const limit = bucket === "student-documents" ? 524288 : 2097152;
      if (!blob || blob.size > limit) return reply(404);
      const bytes = await blob.arrayBuffer();
      // Reject expiry/revocation during the Storage fetch, before releasing bytes.
      if (!await deps.active(token)) return reply(403);
      return new Response(bytes, {
        headers: { ...headers, "Content-Type": "application/octet-stream" },
      });
    } catch {
      // Never expose JWTs, upstream response bodies, paths, or database details.
      return reply(503);
    }
  };
}
