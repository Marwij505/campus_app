// Opt-in development probe. Never redirect protocol output to a log: setup
// contains ephemeral bcrypt hashes. Passwords/JWTs never leave process memory.
// A trusted controller executes setup/register SQL, then creates the named
// marker files. It must execute cleanup SQL even if this process fails.
import { hash } from "npm:bcryptjs@3.0.3";

if (!Deno.args.includes("--development-authorized")) {
  throw new Error("Explicit development authorization required");
}
const config = await Deno.readTextFile("lib/core/config/supabase_config.dart");
const base = config.match(/defaultValue: '(https:\/\/[^']+)'/)![1];
const key = config.match(/defaultValue: '(sb_publishable_[^']+)'/)![1];
if (base !== "https://taqmosufhapstehgeonz.supabase.co") {
  throw new Error("Unexpected development target");
}
const recovery = Deno.args.find((x) => x.startsWith("--recover-run="))?.split(
  "=",
)[1];
const recoveredIds = Deno.args.find((x) => x.startsWith("--recover-ids="))
  ?.split("=")[1].split(",");
if (
  recovery &&
  (!/^[a-f0-9-]{36}$/.test(recovery) || recoveredIds?.length !== 2 ||
    recoveredIds.some((id) => !/^[a-f0-9-]{36}$/.test(id)))
) throw new Error("Invalid recovery identity");
const run = recovery ?? crypto.randomUUID();
const marker = `build/m1-cloud-${run}-${crypto.randomUUID()}`;
const users = [0, 1].map((i) => ({
  id: recoveredIds?.[i] ?? crypto.randomUUID(),
  email: `m1-${run}-${i}@example.invalid`,
  password: `M1!${crypto.randomUUID()}aA9`,
  nim: `99${Date.now()}${i}`,
  token: "",
}));
const quote = (value: string) => `'${value.replaceAll("'", "''")}'`;
const ids = users.map((u) => quote(u.id)).join(",");
const cleanup =
  `begin; delete from auth.users where id in (${ids}) and email like 'm1-${run}-%@example.invalid'; commit;`;
const checks: string[] = [];
function check(ok: unknown, label: string) {
  if (!ok) throw new Error(label);
  checks.push(label);
  if (checks.length % 10 === 0) {
    protocol({ stage: "progress", assertions: checks.length, label });
  }
}
function protocol(value: unknown) {
  console.log(JSON.stringify(value));
}
async function gate(stage: string) {
  const until = Date.now() + 15 * 60_000;
  while (Date.now() < until) {
    try {
      await Deno.stat(`${marker}-${stage}`);
      return;
    } catch (e) {
      if (!(e instanceof Deno.errors.NotFound)) throw e;
    }
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  throw new Error(`Controller timeout: ${stage}`);
}
// This probe inspects heterogeneous Auth/PostgREST/Storage wire responses.
// deno-lint-ignore no-explicit-any
type Json = Record<string, any>;
async function request(
  path: string,
  user?: typeof users[number],
  method = "GET",
  body?: unknown,
  headers: Record<string, string> = {},
) {
  const response = await fetch(base + path, {
    method,
    headers: {
      apikey: key,
      ...(user ? { Authorization: `Bearer ${user.token}` } : {}),
      ...(body === undefined ? {} : { "Content-Type": "application/json" }),
      ...headers,
    },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(60_000),
  });
  const raw = await response.text();
  let data: Json;
  try {
    data = JSON.parse(raw);
  } catch {
    data = { raw };
  }
  return {
    ok: response.ok,
    status: response.status,
    data,
    cache: {
      control: response.headers.get("cache-control"),
      status: response.headers.get("cf-cache-status"),
      age: response.headers.get("age"),
    },
  };
}
async function load(user = users[0]) {
  const r = await request(
    "/rest/v1/rpc/load_student_biodata",
    user,
    "POST",
    {},
  );
  check(r.ok && r.data?._profile_version, "RPC snapshot accessible");
  return r.data;
}
const save = (snapshot: Json, phone: string, user = users[0], extra = {}) =>
  request("/rest/v1/rpc/save_student_biodata", user, "POST", {
    p_values: { phone, ...extra },
    p_expected_profile_version: snapshot._profile_version,
    p_expected_biodata_version: snapshot.updated_at ?? null,
  });
const profile = (snapshot: Json, phone: string) =>
  request(
    `/rest/v1/profiles?id=eq.${users[0].id}&updated_at=eq.${
      encodeURIComponent(snapshot._profile_version)
    }`,
    users[0],
    "PATCH",
    { phone },
    { Prefer: "return=representation" },
  );
const docPath = `${users[0].id}/m1-${run}.pdf`;
let uploaded = false;
let avatarUploaded = false;
const avatarPath = `${users[0].id}/m1-${run}.png`;
const file = (u = users[0], bucket = "student-documents", path = docPath) =>
  request("/functions/v1/private-file", u, "POST", { bucket, path });
try {
  let sql = "begin;\n";
  for (const u of users) {
    const digest = await hash(u.password, 10);
    if (recovery) {
      sql += `update auth.users set encrypted_password=${
        quote(digest)
      } where id=${quote(u.id)} and email=${quote(u.email)};`;
      continue;
    }
    sql +=
      `insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,confirmation_token,recovery_token,email_change_token_new,email_change,raw_app_meta_data,raw_user_meta_data,created_at,updated_at) values ('00000000-0000-0000-0000-000000000000',${
        quote(u.id)
      },'authenticated','authenticated',${quote(u.email)},${
        quote(digest)
      },now(),'','','','','{"provider":"email","providers":["email"]}','{}',now(),now());\n`;
    sql +=
      `insert into auth.identities(provider_id,user_id,identity_data,provider,created_at,updated_at) values (${
        quote(u.id)
      },${quote(u.id)},jsonb_build_object('sub',${quote(u.id)},'email',${
        quote(u.email)
      },'email_verified',true),'email',now(),now());\n`;
    sql += `insert into public.profiles(id,full_name,is_enabled) values (${
      quote(u.id)
    },'M1 temporary fixture',true);\n`;
    sql +=
      `insert into public.students(user_id,nim,university,faculty,program) values (${
        quote(u.id)
      },${quote(u.nim)},'Fixture','Fixture','Fixture');\n`;
  }
  protocol({
    stage: "setup",
    run,
    marker,
    users: users.map((u) => u.id),
    sql: sql + "commit;",
    cleanup,
  });
  await gate("setup");
  let register = "begin;";
  for (const u of users) {
    const r = await request(
      "/auth/v1/token?grant_type=password",
      undefined,
      "POST",
      { email: u.email, password: u.password },
    );
    check(
      r.ok && r.data.access_token,
      `Fixture authentication ${users.indexOf(u) + 1}`,
    );
    u.token = r.data.access_token;
    const jwt = JSON.parse(
      atob(u.token.split(".")[1].replaceAll("-", "+").replaceAll("_", "/")),
    );
    check(
      jwt.sub === u.id && /^[\da-f-]{36}$/.test(jwt.session_id),
      "Fixture JWT owner/session",
    );
    register += `select public.register_profile_session(${
      quote(jwt.session_id)
    },${quote(u.id)});`;
  }
  protocol({ stage: "register", sql: register + "commit;" });
  await gate("register");
  if (recovery) {
    uploaded = true;
  } else {
    const [a, b] = users;
    let s = await load();
    check(!s.updated_at, "Initially absent biodata");
    let r = await save(s, "+6281111111111");
    check(r.ok && r.data.user_id === a.id, "RPC inserts owner biodata");
    s = await load();
    r = await save(s, "+6282222222222");
    check(
      r.ok && r.data._profile_version !== s._profile_version,
      "RPC updates both versions",
    );
    r = await save(s, "+6283333333333");
    check(
      r.status === 409 && r.data.code === "PT409",
      "Stale biodata rejected",
    );
    s = await load();
    r = await profile(s, "+6283333333333");
    check(r.ok && r.data.length === 1, "Profile conditional update");
    r = await save(s, "+6284444444444");
    check(r.status === 409, "Profile commit invalidates stale Biodata");
    s = await load();
    check(
      s.phone === "+6283333333333",
      "Snapshot reads canonical profile phone",
    );
    r = await save(s, "+6285555555555");
    check(r.ok, "Biodata save after reload");
    r = await profile(s, "+6286666666666");
    check(
      r.ok && r.data.length === 0,
      "Biodata commit invalidates stale profile",
    );
    for (let i = 0; i < 4; i++) {
      s = await load();
      const phones = [`+62811${i}1111111`, `+62822${i}2222222`];
      const results = await Promise.all(phones.map((p) => save(s, p)));
      check(
        results.filter((x) => x.ok).length === 1 &&
          results.filter((x) => x.status === 409).length === 1,
        `Parallel RPC race ${i + 1}: one commit, one conflict`,
      );
      const winner = results.findIndex((x) => x.ok);
      check(
        (await load()).phone === phones[winner],
        `Parallel RPC race ${i + 1}: winner persisted`,
      );
      s = await load();
      const [pr, br] = await Promise.all([
        profile(s, phones[0]),
        save(s, phones[1]),
      ]);
      const pw = pr.ok && pr.data.length === 1;
      check(
        (pw && br.status === 409) || (pr.ok && pr.data.length === 0 && br.ok),
        `Parallel profile/Biodata race ${i + 1}: one commit`,
      );
      check(
        (await load()).phone === phones[pw ? 0 : 1],
        `Parallel profile/Biodata race ${i + 1}: winner persisted`,
      );
    }
    s = await load();
    r = await save(s, "invalid");
    check(
      r.status === 400 && r.data.code === "23514",
      "Constraint failure rejected",
    );
    check(
      JSON.stringify(await load()) === JSON.stringify(s),
      "Constraint failure leaves snapshot unchanged",
    );
    r = await save(s, "+6281111111111", a, { user_id: b.id });
    check(
      r.status === 400 && r.data.code === "22023",
      "RPC rejects forged owner",
    );
    r = await save(s, "+6281111111111", a, { role: "bap" });
    check(r.status === 400, "RPC rejects official field");
    r = await request(
      "/rest/v1/rpc/load_student_biodata",
      undefined,
      "POST",
      {},
    );
    check(!r.ok, "Anonymous RPC denied");
    for (const table of ["profiles", "student_biodata", "students"]) {
      r = await request(
        `/rest/v1/${table}?${
          table === "profiles" ? "id" : "user_id"
        }=eq.${a.id}&select=*`,
        b,
      );
      check(r.ok && r.data.length === 0, `Foreign ${table} hidden`);
    }
    const bytes = new TextEncoder().encode(
      "%PDF-1.4\n% M1 synthetic fixture only\n%%EOF\n",
    );
    const upload = await fetch(
      `${base}/storage/v1/object/student-documents/${docPath}`,
      {
        method: "POST",
        headers: {
          apikey: key,
          Authorization: `Bearer ${a.token}`,
          "Content-Type": "application/pdf",
          "Cache-Control": "max-age=0, no-store",
        },
        body: bytes,
        signal: AbortSignal.timeout(60_000),
      },
    );
    uploaded = upload.ok;
    check(uploaded, "Owner document upload");
    await upload.body?.cancel();
    r = await request("/rest/v1/student_documents", a, "POST", {
      user_id: a.id,
      kind: "diploma",
      path: docPath,
      file_name: "m1-fixture.pdf",
      mime_type: "application/pdf",
      size_bytes: bytes.length,
    });
    check(r.ok, "Owner document metadata insert");
    r = await file(a);
    check(
      r.ok && r.data.raw === new TextDecoder().decode(bytes),
      "Owner downloads exact bytes",
    );
    r = await file(b);
    check(!r.ok, "Foreign document download denied");
    r = await request(
      `/storage/v1/object/sign/student-documents/${docPath}`,
      b,
      "POST",
      { expiresIn: 60 },
    );
    check(!r.ok, "Foreign signed URL denied");
    r = await request(`/storage/v1/object/public/student-documents/${docPath}`);
    check(!r.ok, "Anonymous public document URL denied");
    r = await request(`/rest/v1/student_documents?user_id=eq.${a.id}`, b);
    check(r.ok && r.data.length === 0, "Foreign document metadata hidden");
    r = await request(
      `/rest/v1/student_documents?user_id=eq.${a.id}`,
      b,
      "PATCH",
      { file_name: "forged.pdf" },
      { Prefer: "return=representation" },
    );
    check(
      r.ok && r.data.length === 0,
      "Foreign metadata update affects zero rows",
    );
    r = await request(
      `/rest/v1/student_documents?user_id=eq.${a.id}`,
      b,
      "DELETE",
      undefined,
      { Prefer: "return=representation" },
    );
    check(
      r.ok && r.data.length === 0,
      "Foreign metadata delete affects zero rows",
    );
    r = await request("/storage/v1/object/student-documents", b, "DELETE", {
      prefixes: [docPath],
    });
    check(
      !r.ok || r.data.length === 0,
      "Foreign storage delete affects zero objects",
    );
    r = await file(a);
    check(r.ok, "Owner document survives foreign mutations");
    r = await request("/rest/v1/student_documents", b, "POST", {
      user_id: a.id,
      kind: "passport",
      path: docPath,
      file_name: "forged.pdf",
      mime_type: "application/pdf",
      size_bytes: bytes.length,
    });
    check(!r.ok, "Foreign metadata insert denied");
    const foreignUpload = await fetch(
      `${base}/storage/v1/object/student-documents/${a.id}/foreign-${run}.pdf`,
      {
        method: "POST",
        headers: {
          apikey: key,
          Authorization: `Bearer ${b.token}`,
          "Content-Type": "application/pdf",
          "Cache-Control": "max-age=0, no-store",
        },
        body: bytes,
        signal: AbortSignal.timeout(60_000),
      },
    );
    check(!foreignUpload.ok, "Foreign storage upload denied");
    await foreignUpload.body?.cancel();
    r = await request(`/rest/v1/profiles?id=eq.${a.id}`, a, "PATCH", {
      role: "bap",
    });
    check(!r.ok, "Profile role column is not writable");
    r = await request(`/rest/v1/students?user_id=eq.${a.id}`, a, "PATCH", {
      nim: "9900000000",
    });
    check(!r.ok, "Official student NIM is not writable");
    r = await request(`/rest/v1/student_documents?user_id=eq.${a.id}`);
    check(!r.ok, "Anonymous document metadata denied");
    for (
      const endpoint of [
        `/storage/v1/object/student-documents/${docPath}`,
        `/storage/v1/object/authenticated/student-documents/${docPath}`,
        `/storage/v1/render/image/authenticated/student-documents/${docPath}`,
      ]
    ) {
      r = await request(endpoint, a);
      check(!r.ok, "Direct owner download/transform disabled");
    }
    r = await request(
      `/storage/v1/object/sign/student-documents/${docPath}`,
      a,
      "POST",
      { expiresIn: 60 },
    );
    check(!r.ok, "Owner signed URL disabled");
    r = await request("/functions/v1/private-file", undefined, "POST", {
      bucket: "student-documents",
      path: docPath,
    });
    check(r.status === 401, "Anonymous gateway denied");
    r = await request("/functions/v1/private-file", a, "POST", {
      bucket: "student-documents",
      path: `${a.id}/orphan.pdf`,
    });
    check(!r.ok, "Unreferenced file denied");
    const avatar = await fetch(
      `${base}/storage/v1/object/student-avatars/${avatarPath}`,
      {
        method: "POST",
        headers: {
          apikey: key,
          Authorization: `Bearer ${a.token}`,
          "Content-Type": "image/png",
        },
        body: new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10]),
        signal: AbortSignal.timeout(60000),
      },
    );
    avatarUploaded = avatar.ok;
    check(avatarUploaded, "Owner avatar upload");
    await avatar.body?.cancel();
    r = await request(`/rest/v1/profiles?id=eq.${a.id}`, a, "PATCH", {
      avatar_path: avatarPath,
    });
    check(r.ok, "Owner avatar reference");
    r = await file(a, "student-avatars", avatarPath);
    check(r.ok, "Owner avatar gateway download");
    r = await file(b, "student-avatars", avatarPath);
    check(!r.ok, "Foreign avatar gateway denied");
    r = await request(`/storage/v1/object/student-avatars/${avatarPath}`, a);
    check(!r.ok, "Direct avatar download disabled");
    protocol({
      stage: "expire",
      sql:
        `update private.app_sessions set expires_at=now()-interval '1 second' where user_id=${
          quote(a.id)
        };`,
    });
    await gate("expire");
    r = await file(a);
    protocol({ stage: "expiry_cache", http: r.status, cache: r.cache });
    check(!r.ok, "Expired app session cannot download document with valid JWT");
    r = await file(a, "student-avatars", avatarPath);
    check(!r.ok, "Expired app session cannot download avatar");
    r = await request(`/rest/v1/student_documents?user_id=eq.${a.id}`, a);
    check(
      r.ok && r.data.length === 0,
      "Expired app session cannot read metadata",
    );
    r = await save(s, "+6281111111111");
    check(!r.ok, "Expired app session cannot save Biodata");
    protocol({
      stage: "restore_expiry",
      sql:
        `update private.app_sessions set expires_at=started_at+interval '30 minutes' where user_id=${
          quote(a.id)
        };`,
    });
    await gate("restore_expiry");
    r = await file(a);
    check(r.ok, "Restored fixture session reads document");
    r = await request("/rest/v1/rpc/revoke_profile_session", a, "POST", {});
    check(r.ok, "Fixture app session revocation");
    r = await file(a);
    check(!r.ok, "Revoked app session cannot download document with valid JWT");
    r = await file(a, "student-avatars", avatarPath);
    check(!r.ok, "Revoked app session cannot download avatar");
    r = await request(`/rest/v1/student_documents?user_id=eq.${a.id}`, a);
    check(
      r.ok && r.data.length === 0,
      "Revoked app session cannot read metadata",
    );
    protocol({
      stage: "restore_cleanup",
      sql: `update private.app_sessions set revoked_at=null where user_id=${
        quote(a.id)
      };`,
    });
    await gate("restore_cleanup");
    protocol({ stage: "passed", assertions: checks.length, checks });
  }
} catch (e) {
  // Only our assertion labels are safe; network/Auth response bodies stay private.
  protocol({
    stage: "failed",
    assertions: checks.length,
    label: e instanceof Error
      ? e.message.replace(/https?:\/\/\S+/g, "[url]")
      : "Unknown failure",
  });
  Deno.exitCode = 1;
} finally {
  if (uploaded || avatarUploaded) {
    protocol({
      stage: "cleanup_session",
      sql:
        `update private.app_sessions set revoked_at=null, expires_at=now()+interval '2 minutes' where user_id=${
          quote(users[0].id)
        };`,
    });
    await gate("cleanup_session");
    for (
      const [bucket, path, present] of [[
        "student-documents",
        docPath,
        uploaded,
      ], ["student-avatars", avatarPath, avatarUploaded]] as const
    ) {
      if (!present) continue;
      const r = await request(
        `/storage/v1/object/${bucket}`,
        users[0],
        "DELETE",
        { prefixes: [path] },
      );
      protocol({
        stage: "storage_cleanup",
        bucket,
        success: r.ok && r.data.length === 1,
      });
    }
  }
  protocol({
    stage: "cleanup_required",
    sql: cleanup,
    users: users.map((u) => u.id),
    run,
  });
}
