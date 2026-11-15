// PostgreSQL WASM sementara; tidak memakai URL, key, atau data cloud.
// deno test --allow-read --allow-env tool/m1_biodata_sql_test.ts
import { PGlite } from "npm:@electric-sql/pglite@0.5.15";

Deno.test("M1 RPC: SQL nyata, konflik dua versi, rollback, RLS, dan sesi", async () => {
  const db = await PGlite.create();
  let checks = 0;
  const assert = (ok: boolean, label: string) => {
    if (!ok) throw new Error(label);
    checks++;
  };
  async function denied(action: () => Promise<unknown>, code: string) {
    try {
      await action();
    } catch (error) {
      assert(
        (error as { code: string }).code === code,
        `Expected SQLSTATE ${code}`,
      );
      return;
    }
    throw new Error(`Expected rejection ${code}`);
  }
  const owner = "11111111-1111-4111-8111-111111111111";
  const other = "33333333-3333-4333-8333-333333333333";
  const session = "22222222-2222-4222-8222-222222222222";
  const otherSession = "44444444-4444-4444-8444-444444444444";
  type Snapshot = {
    updated_at?: string;
    _profile_version: string;
    phone?: string;
    user_id?: string;
  };
  const snapshot = async () =>
    (await db.query<{ value: Snapshot | null }>(
      "select public.load_student_biodata() as value",
    )).rows[0].value;
  const save = async (
    s: Snapshot,
    values: Record<string, unknown> = { phone: "+6281111111111" },
  ) =>
    (await db.query<{ value: Snapshot }>(
      "select public.save_student_biodata($1::jsonb,$2::timestamptz,$3::timestamptz) as value",
      [JSON.stringify(values), s._profile_version, s.updated_at ?? null],
    )).rows[0].value;
  async function login(id = owner, sid = session) {
    await db.exec("reset role");
    await db.query("select set_config('request.jwt.claims',$1,false)", [
      JSON.stringify({ sub: id, session_id: sid, role: "authenticated" }),
    ]);
    await db.exec("set role authenticated");
  }
  try {
    // Hanya infrastruktur Supabase Auth/Storage yang ditiru; tabel aplikasi,
    // grants, trigger, dan RLS dibaca langsung dari migrasi repository.
    await db.exec(`
      create role anon; create role authenticated; create role service_role;
      create schema auth; create schema storage;
      create table auth.users(id uuid primary key, email text);
      create table auth.sessions(id uuid primary key,user_id uuid references auth.users,created_at timestamptz,updated_at timestamptz);
      create function auth.jwt() returns jsonb language sql stable as $$ select nullif(current_setting('request.jwt.claims',true),'')::jsonb $$;
      create function auth.uid() returns uuid language sql stable as $$ select (auth.jwt()->>'sub')::uuid $$;
      grant usage on schema auth to authenticated,anon;
      create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
      create table storage.objects(id uuid default gen_random_uuid(),bucket_id text,name text);
      alter table storage.objects enable row level security;
      create function storage.foldername(text) returns text[] language sql immutable as $$ select string_to_array($1,'/') $$;
      create function storage.allow_any_operation(text[]) returns boolean language sql stable as $$ select replace(current_setting('storage.operation',true),'storage.','')=any($1) $$;
      grant usage on schema storage to authenticated;
      grant select,insert,delete on storage.objects to authenticated;
    `);
    for (
      const migration of [
        "20261030080557_student_profiles.sql",
        "20261031082535_session_rpc_boundaries.sql",
        "20261101020002_student_biodata_sections.sql",
        "20261109204541_m1_biodata_profile_transaction.sql",
        "20261110032150_m1_biodata_conflict_http409.sql",
        "20261110033954_m1_private_file_gateway.sql",
      ]
    ) {
      await db.exec(
        await Deno.readTextFile(
          new URL(`../supabase/migrations/${migration}`, import.meta.url),
        ),
      );
    }
    for (
      const [id, sid, nim] of [[owner, session, "9911111111"], [
        other,
        otherSession,
        "9933333333",
      ]]
    ) {
      await db.query("insert into auth.users(id) values($1)", [id]);
      await db.query(
        "insert into public.profiles(id,full_name,is_enabled) values($1,'Fixture M1',true)",
        [id],
      );
      await db.query(
        "insert into public.students(user_id,nim,university,faculty,program) values($1,$2,'Fixture','Fixture','Fixture')",
        [id, nim],
      );
      await db.query(
        "insert into auth.sessions(id,user_id,created_at,updated_at) values($1,$2,now(),now())",
        [sid, id],
      );
      await db.query("select public.register_profile_session($1,$2)", [
        sid,
        id,
      ]);
    }
    await login();
    await db.exec(
      `reset role; insert into storage.objects(bucket_id,name) values ('student-documents','${owner}/fixture.pdf'),('student-avatars','${owner}/fixture.png');`,
    );
    await login();
    for (
      const operation of [
        "object.get_authenticated",
        "object.sign",
        "object.sign_many",
        "render.image_authenticated",
        "s3.object.get",
        "object.list",
        "",
      ]
    ) {
      await db.query("select set_config('storage.operation',$1,false)", [
        operation,
      ]);
      assert(
        (await db.query("select * from storage.objects")).rows.length === 0,
        `direct read denied: ${operation}`,
      );
    }
    await db.exec(
      "select set_config('storage.operation','object.delete_many',false)",
    );
    assert(
      (await db.query("select * from storage.objects")).rows.length === 2,
      "owner cleanup can see both buckets",
    );
    await login(other, otherSession);
    assert(
      (await db.query("select * from storage.objects")).rows.length === 0,
      "foreign cleanup cannot see owner objects",
    );
    await login();
    const absent = (await snapshot())!;
    assert(absent.updated_at === undefined, "initial row absent");
    await db.exec(
      "update public.profiles set phone='+6282222222222' where id=auth.uid()",
    );
    await denied(() => save(absent), "PT409");
    let current = (await snapshot())!;
    assert(
      current.phone === "+6282222222222",
      "load uses current canonical phone",
    );
    current = await save(current);
    assert(current.phone === "+6281111111111", "insert and sync");
    const stale = current;
    await db.exec(
      "update public.profiles set phone='+6282222222222' where id=auth.uid()",
    );
    await denied(() => save(stale), "PT409");
    current = (await snapshot())!;
    const before = current._profile_version;
    current = await save(current, { phone: "+6283333333333" });
    const oldProfile = await db.query(
      "update public.profiles set phone='+6284444444444' where id=auth.uid() and updated_at=$1::timestamptz returning id",
      [before],
    );
    assert(
      oldProfile.rows.length === 0,
      "biodata commit invalidates old profile version",
    );
    await denied(() => save({ ...current, updated_at: undefined }), "PT409");
    await denied(
      () => save({ ...current, updated_at: "2000-01-01T00:00:00Z" }),
      "PT409",
    );
    await denied(() => save(current, { user_id: other }), "22023");
    await denied(() => save(current, { role: "admin" }), "22023");
    await denied(() => save(current, { phone: "invalid" }), "23514");
    assert(
      (await snapshot())!.phone === current.phone,
      "constraint rejection preserves both tables",
    );
    // Kegagalan setelah trigger sync harus membatalkan perubahan profil juga.
    await db.exec(`reset role;
      create function private.m1_fail() returns trigger language plpgsql as $$ begin raise exception using errcode='23514',message='test rollback'; end $$;
      create trigger zz_m1_fail after update on public.student_biodata for each row execute function private.m1_fail();`);
    await login();
    await denied(() => save(current, { phone: "+6285555555555" }), "23514");
    assert(
      (await snapshot())!.phone === current.phone,
      "trigger failure rolls back profile and biodata",
    );
    await db.exec(
      "reset role; drop trigger zz_m1_fail on public.student_biodata",
    );
    await login(other, otherSession);
    await denied(() => save(current), "PT409");
    assert(
      (await db.query("select * from public.student_biodata")).rows.length ===
        0,
      "foreign rows hidden by RLS",
    );
    await db.exec("reset role; set role anon");
    await denied(snapshot, "42501");
    await denied(() => save(current), "42501");
    await login();
    for (
      const update of [
        `update private.app_sessions set expires_at=now()-interval '1 second' where session_id='${session}'`,
        `update private.app_sessions set expires_at=now()+interval '30 minutes',revoked_at=now() where session_id='${session}'`,
        `update private.app_sessions set revoked_at=null where session_id='${session}'; update public.profiles set is_enabled=false where id='${owner}'`,
      ]
    ) {
      await db.exec(`reset role; ${update}`);
      await login();
      assert(await snapshot() === null, "expired/revoked/disabled read denied");
      await denied(() => save(current), "PT409");
    }
    console.log(
      `PASS: ${checks} SQL assertions; Auth/Storage infrastructure simulated, no cloud; concurrent connections NOT RUN.`,
    );
  } finally {
    await db.close();
  }
});
