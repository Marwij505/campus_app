// Ephemeral PostgreSQL WASM; no cloud URL, account, or database is modified.
import { PGlite } from "npm:@electric-sql/pglite@0.5.15";

Deno.test("M2: PostgreSQL workflow, deadlines, accounting, KRS and RLS", async () => {
  const db = await PGlite.create();
  let checks = 0;
  const assert = (value: unknown, label: string) => {
    if (!value) throw new Error(label);
    checks++;
  };
  const owner = "11111111-1111-4111-8111-111111111111";
  const other = "22222222-2222-4222-8222-222222222222";
  const staff = "33333333-3333-4333-8333-333333333333";
  const sid = (id: string) => id.replace(/-4/, "-5");
  async function login(id = owner) {
    await db.exec("reset role");
    await db.query("select set_config('request.jwt.claims',$1,false)", [
      JSON.stringify({ sub: id, session_id: sid(id), role: "authenticated" }),
    ]);
    await db.exec("set role authenticated");
  }
  async function admin(sql: string, params: unknown[] = []) {
    await db.exec("reset role");
    return await db.query<Record<string, unknown>>(sql, params);
  }
  // JSON is the exact PostgREST RPC contract consumed by Flutter.
  // deno-lint-ignore no-explicit-any
  async function snapshot(period: string | null = "2026-1"): Promise<any> {
    return (await db.query<{ v: unknown }>("select public.m2_snapshot($1) v", [
      period,
    ])).rows[0].v;
  }
  async function command(
    action: string,
    data: Record<string, unknown> = {},
    period = "2026-2",
    // deno-lint-ignore no-explicit-any
  ): Promise<any> {
    const value = (await db.query<{ v: { error?: string } }>(
      "select public.m2_command($1,$2,$3) v",
      [action, period, JSON.stringify(data)],
    )).rows[0].v;
    if (value.error?.startsWith("SQL:")) throw new Error(value.error);
    return value;
  }
  async function clock(time: string, id = owner, period = "2026-2") {
    await admin(
      "update public.m2_registrations set demo_now=$1 where user_id=$2 and period_id=$3",
      [time, id, period],
    );
    await login(id);
  }
  async function denied(sql: string) {
    try {
      await db.exec(sql);
    } catch (e) {
      assert((e as { code: string }).code === "42501", "permission denial");
      return;
    }
    throw new Error("Expected access denial");
  }
  try {
    // Reuse the exact M1 infrastructure fixture; application migrations are real.
    const baseline = await Deno.readTextFile(
      new URL("m1_biodata_sql_test.ts", import.meta.url),
    );
    const infrastructure = baseline.match(/await db\.exec\(`([\s\S]*?)`\);/)!;
    await db.exec(infrastructure[1]);
    await db.exec(
      `alter table auth.users add column email_confirmed_at timestamptz default now(), add column deleted_at timestamptz, add column banned_until timestamptz;
      create table auth.mfa_factors(id uuid default gen_random_uuid(),user_id uuid references auth.users,status text);`,
    );
    const migrations = [
      "20261030080557_student_profiles.sql",
      "20261031082535_session_rpc_boundaries.sql",
      "20261101020002_student_biodata_sections.sql",
      "20261102071019_password_reset_otp.sql",
      "20261109204541_m1_biodata_profile_transaction.sql",
      "20261110032150_m1_biodata_conflict_http409.sql",
      "20261110033954_m1_private_file_gateway.sql",
      "20261117054431_m2_academic_workflow.sql",
      "20261117054456_m2_demo_seed_helper.sql",
      "20261117054854_m2_query_indexes.sql",
      "20261117105927_m2_staff_context.sql",
      "20261117111936_m2_demo_staff_email_guard.sql",
      "20261118033204_m2_staff_short_nip.sql",
    ];
    for (const name of migrations) {
      await db.exec(
        (await Deno.readTextFile(
          new URL(`../supabase/migrations/${name}`, import.meta.url),
        )).replace(
          "'Data tidak valid atau operasi gagal'",
          "'SQL:'||sqlstate||':'||sqlerrm",
        ),
      );
    }
    await db.exec(
      await Deno.readTextFile(
        new URL("../supabase/seed_m2.sql", import.meta.url),
      ),
    );
    for (const [i, id] of [owner, other, staff].entries()) {
      await db.query("insert into auth.users(id) values($1)", [id]);
      await db.query(
        "insert into public.profiles(id,full_name,is_enabled) values($1,'M2 isolated fixture',true)",
        [id],
      );
      await db.query(
        "insert into public.students(user_id,nim,university,faculty,program) values($1,$2,'Test','Test','Teknik Informatika')",
        [id, `99999990${i}`],
      );
      await db.query(
        "insert into auth.sessions(id,user_id,created_at,updated_at) values($1,$2,now(),now())",
        [sid(id), id],
      );
      await db.query("select public.register_profile_session($1,$2)", [
        sid(id),
        id,
      ]);
      await db.query("select private.m2_seed_dante($1,'MKU102')", [id]);
    }
    await db.query(
      "insert into private.m2_staff select $1,unnest(array['academic','validator','finance','reconcile'])",
      [staff],
    );
    await login();
    let s = await snapshot();
    assert(
      s.registration.semester === 1 && s.registration.entry_year === 2026 &&
        s.registration.curriculum === "2026",
      "Dante context",
    );
    assert(
      s.krs.status === "approved" && s.krs_items.length === 7,
      "approved 7-course snapshot",
    );
    assert(s.equivalences.length === 0, "no equivalences");
    assert(
      s.events.filter((
        e: { kind: string; meeting: number; realization: string },
      ) => e.kind === "class" && e.meeting <= 7 && e.realization).length === 49,
      "49 realized meetings separate from attendance",
    );
    assert(
      s.events.find((e: { starts_at: string }) =>
        new Date(e.starts_at) > new Date(s.server_now)
      ).meeting === 8,
      "next meeting 8",
    );
    assert(
      s.courses.filter((c: { code: string }) =>
        ["CSF101", "CSF102", "CSF103", "CSF104", "MKU102", "MKU107", "MKU111"]
          .includes(c.code)
      ).reduce((n: number, c: { credits: number }) => n + c.credits, 0) === 19,
      "verified 19 SKS",
    );
    assert(s.invoices[0].paid === 17500000, "paid snapshot");
    await admin("select private.m2_seed_dante($1,'MKU102')", [owner]);
    await login();
    assert((await snapshot()).invoices.length === 1, "seed rerun idempotent");
    await admin(
      "update public.m2_registrations set demo_now='2026-09-03 09:00+07' where user_id=$1 and period_id='2026-1'",
      [owner],
    );
    await admin(
      "update public.m2_krs set status='draft' where user_id=$1 and period_id='2026-1'",
      [owner],
    );
    await login();
    assert(
      !(await command("save_krs", {
        version: 1,
        offering_ids: ["2026-1-regular-MKU101", "2026-1-regular-MKU102"],
      }, "2026-1")).ok,
      "one religion alternative only",
    );
    assert(
      (await snapshot()).events.length === 0,
      "unapproved KRS hides personal events",
    );
    await admin(
      "update public.m2_krs set status='approved' where user_id=$1 and period_id='2026-1'",
      [owner],
    );
    await login();
    assert(
      (await snapshot()).events.every((e: { realization: string | null }) =>
        e.realization === null
      ),
      "future realization hidden when demo clock rewound",
    );
    await clock("2026-11-15T12:00:00+07:00", owner, "2026-1");
    await denied("update public.m2_registrations set status='active'");
    await denied("select private.m2_seed_dante(auth.uid(),'MKU102')");
    try {
      await command("verify_payment", {});
      throw new Error("student approved");
    } catch (e) {
      assert(
        (e as { code: string }).code === "42501",
        "student cannot approve",
      );
    }
    await login(other);
    assert(
      (await db.query("select * from public.m2_krs where user_id=$1", [owner]))
        .rows.length === 0,
      "foreign KRS hidden",
    );
    assert(
      (await db.query(
        "select * from public.m2_notifications where user_id=$1",
        [owner],
      )).rows.length === 0,
      "foreign notices hidden",
    );
    await db.exec("reset role; set role anon");
    await denied("select public.m2_snapshot(null)");
    await login();
    await clock("2027-01-17T23:59:59+07:00", owner, "2026-1");
    assert(
      (await snapshot()).stage === "Semester aktif",
      "before semester end",
    );
    await clock("2027-01-18T00:00:00+07:00", owner, "2026-1");
    assert(
      (await snapshot()).stage === "Libur semester",
      "exclusive semester end",
    );
    await clock("2027-01-18T00:00:01+07:00", owner, "2026-1");
    assert((await snapshot()).events.length > 0, "history retained after end");
    // Month arithmetic includes leap years and preserves Jakarta wall time.
    const dates = await admin(
      "select private.m2_month('2027-01-31 15:30+07',1) a, private.m2_month('2028-01-31 15:30+07',1) b",
    );
    assert(
      new Date(dates.rows[0].a as string).toISOString() ===
        "2027-02-28T08:30:00.000Z",
      "end-of-month clamp",
    );
    assert(
      new Date(dates.rows[0].b as string).toISOString() ===
        "2028-02-29T08:30:00.000Z",
      "leap-year clamp",
    );
    await clock("2027-01-18T23:59:59+07:00");
    assert(
      !(await command("register", { track: "regular" })).ok,
      "registration closed before opening",
    );
    await clock("2027-01-19T09:00:00+07:00");
    s = await snapshot("2026-2");
    assert(
      new Date(s.registration.first_due).toISOString() ===
        "2027-02-19T02:00:00.000Z",
      "one month from personal publication",
    );
    const deadline = s.registration.first_due;
    assert(
      (await command("register", { track: "regular" })).ok,
      "regular registration",
    );
    assert(
      !(await command("save_krs", {
        version: 0,
        offering_ids: ["2026-2-regular-CIE201"],
      })).ok,
      "unpaid blocks KRS",
    );
    for (const count of [1, 3, 6]) {
      assert((await command("plan", { count })).ok, `plan ${count}`);
      s = await snapshot("2026-2");
      const inv = s.invoices.find((v: { cancelled: boolean }) => !v.cancelled);
      assert(
        inv.installments.length === count &&
          inv.installments.reduce(
              (n: number, v: { amount: number }) => n + v.amount,
              0,
            ) === inv.principal,
        `sum ${count}`,
      );
      const number = s.invoices.length;
      await command("plan", { count });
      assert(
        (await snapshot("2026-2")).invoices.length === number,
        "duplicate plan",
      );
    }
    s = await snapshot("2026-2");
    let inv = s.invoices.find((v: { cancelled: boolean }) => !v.cancelled);
    let first = inv.installments[0];
    const key = crypto.randomUUID();
    const created = await command("create_payment", {
      installment_id: first.id,
      channel: "qris",
      request_key: key,
    });
    assert(created.ok, "qris created");
    assert(
      (await command("create_payment", {
        installment_id: first.id,
        channel: "qris",
        request_key: key,
      })).payment_id === created.payment_id,
      "retry same payment",
    );
    assert(
      !(await command("plan", { count: 3 })).ok,
      "pending transaction locks scheme",
    );
    assert(
      (await command("fail_payment", { id: created.payment_id })).ok,
      "qris failure",
    );
    const expired = await command("create_payment", {
      installment_id: first.id,
      channel: "qris",
      request_key: crypto.randomUUID(),
    });
    await clock("2027-01-19T10:00:00+07:00");
    assert(
      (await snapshot("2026-2")).payments.find((p: { id: string }) =>
        p.id === expired.payment_id
      ).status === "expired",
      "qris expires on read",
    );
    const bca = await command("create_payment", {
      installment_id: first.id,
      channel: "bca",
      request_key: crypto.randomUUID(),
    });
    assert(
      (await command("submit_evidence", {
        id: bca.payment_id,
        reference: "SIM-BANK-001",
      })).ok,
      "BCA pending evidence",
    );
    assert(
      (await snapshot("2026-2")).registration.status === "inactive",
      "evidence never activates",
    );
    const paidAt = "2027-01-19T10:05:00+07:00";
    await clock("2027-01-19T10:10:00+07:00");
    await login(staff);
    const verify = {
      student_id: owner,
      id: bca.payment_id,
      amount: first.amount,
      currency: "IDR",
      reference: bca.payment_id,
      bank_reference: "SIM-BANK-001",
      paid_at: paidAt,
      decision: "approved",
      reason: "Mutasi simulasi cocok",
    };
    assert(
      !(await command("verify_payment", {
        ...verify,
        amount: first.amount + 1,
      })).ok,
      "mismatched amount",
    );
    assert((await command("verify_payment", verify)).ok, "verified BCA");
    assert((await command("verify_payment", verify)).ok, "callback idempotent");
    await login();
    s = await snapshot("2026-2");
    inv = s.invoices.find((v: { cancelled: boolean }) => !v.cancelled);
    assert(
      s.registration.status === "active" && inv.paid === first.amount &&
        inv.paid < inv.principal,
      "first of six activates without claiming paid in full",
    );
    assert(!(await command("plan", { count: 1 })).ok, "paid scheme locked");
    const ids = [
      "CIE201",
      "CIE202",
      "CSF201",
      "CSF202",
      "MKU108",
      "MKU109",
      "MKU201",
    ].map((c) => `2026-2-regular-${c}`);
    assert(
      !(await command("save_krs", {
        version: 0,
        offering_ids: [ids[0], ids[0]],
      })).ok,
      "duplicate classes",
    );
    assert(
      !(await command("save_krs", {
        version: 0,
        offering_ids: ["2026-2-employee-CIE201"],
      })).ok,
      "wrong track",
    );
    assert(
      !(await command("save_krs", {
        version: 0,
        offering_ids: ["2026-1-regular-CSF101"],
      })).ok,
      "wrong period",
    );
    assert(
      (await command("save_krs", { version: 0, offering_ids: ids })).ok,
      "save valid draft",
    );
    assert(
      (await snapshot("2026-2")).events.length === 0,
      "draft has no personal schedule",
    );
    assert(
      !(await command("save_krs", { version: 0, offering_ids: ids })).ok,
      "stale revision",
    );
    assert((await command("submit_krs", { version: 1 })).ok, "submit KRS");
    await login(staff);
    assert(
      (await command("decide_krs", {
        student_id: owner,
        version: 2,
        decision: "revision",
        reason: "Tinjau pilihan",
      })).ok,
      "return for revision",
    );
    await login();
    assert(
      (await command("save_krs", { version: 3, offering_ids: ids })).ok,
      "edit revision",
    );
    assert((await command("submit_krs", { version: 4 })).ok, "resubmit");
    await login(staff);
    assert(
      (await command("decide_krs", {
        student_id: owner,
        version: 5,
        decision: "approved",
        reason: "KRS demo sesuai",
      })).ok,
      "approve KRS",
    );
    await login();
    assert(
      (await snapshot("2026-2")).events.length === 98,
      "approved schedule comes from KRS",
    );
    s = await snapshot("2026-2");
    const notice = s.notifications[0];
    await command("read_notification", { id: notice.id }, notice.period_id);
    await login();
    assert(
      (await snapshot("2026-2")).notifications.find((v: { id: string }) =>
        v.id === notice.id
      ).read_at,
      "read persists across session reload",
    );
    const notices = (await snapshot("2026-2")).notifications.length;
    assert(
      (await snapshot("2026-2")).notifications.length === notices,
      "refresh deduplicates notifications",
    );
    // Competing channels: single allocation; extra payment requires reconciliation.
    first = inv.installments[1];
    const a = await command("create_payment", {
      installment_id: first.id,
      channel: "qris",
      request_key: crypto.randomUUID(),
    });
    const b = await command("create_payment", {
      installment_id: first.id,
      channel: "bca",
      request_key: crypto.randomUUID(),
    });
    await login(staff);
    const evidence = {
      ...verify,
      amount: first.amount,
      paid_at: "2027-01-19T10:10:00+07:00",
    };
    assert(
      (await command("verify_payment", {
        ...evidence,
        id: a.payment_id,
        reference: a.payment_id,
        bank_reference: "SIM-2A",
      })).ok,
      "second qris payment",
    );
    assert(
      !(await command("verify_payment", {
        ...evidence,
        id: b.payment_id,
        reference: b.payment_id,
        bank_reference: "SIM-2A",
      })).ok,
      "one bank mutation cannot pay twice",
    );
    assert(
      (await command("verify_payment", {
        ...evidence,
        id: b.payment_id,
        reference: b.payment_id,
        bank_reference: "SIM-2B",
      })).ok,
      "excess payment retained",
    );
    await login();
    s = await snapshot("2026-2");
    assert(
      s.payments.find((p: { id: string }) => p.id === b.payment_id).status ===
        "reconcile",
      "double-channel reconciliation",
    );
    assert(
      s.invoices.find((v: { cancelled: boolean }) => !v.cancelled).paid ===
        first.amount * 2,
      "no duplicate allocation",
    );
    await clock("2027-05-20T12:00:00+07:00");
    s = await snapshot("2026-2");
    assert(
      s.registration.status === "active" && s.krs.status === "approved",
      "later arrears do not cancel active KRS",
    );
    assert(
      s.notifications.some((n: { title: string }) =>
        n.title === "Pembayaran tertunggak"
      ),
      "arrears notice",
    );
    assert(s.registration.first_due === deadline, "notice deadline immutable");
    assert(
      !(await command("save_krs", { version: 6, offering_ids: ids })).ok,
      "closed KRS cannot edit",
    );
    // Separate student: voluntary leave, rejection, employee route, deadline.
    await clock("2027-01-19T09:00:00+07:00", other);
    assert(
      (await command("request_leave", { reason: "Keperluan fixture" })).ok,
      "request leave",
    );
    s = await snapshot("2026-2");
    assert(
      s.invoices.length === 0 && s.events.length === 0,
      "leave creates no tuition or schedule",
    );
    const leaveId = s.leave_requests[0].id;
    assert(
      !(await command("register", { track: "employee" })).ok,
      "pending leave blocks route",
    );
    await login(staff);
    assert(
      (await command("decide_leave", {
        student_id: other,
        id: leaveId,
        decision: "rejected",
        reason: "Fixture penolakan",
      })).ok,
      "reject leave",
    );
    await login(other);
    assert(
      (await command("register", { track: "employee" })).ok,
      "employee after rejection",
    );
    assert(
      (await command("plan", { count: 3 })).ok,
      "employee three installments",
    );
    s = await snapshot("2026-2");
    inv = s.invoices[0];
    assert(
      inv.principal === 17500000 &&
        s.offerings.every((o: { track: string }) => o.track === "employee"),
      "employee pricing and offerings",
    );
    const late = await command("create_payment", {
      installment_id: inv.installments[0].id,
      channel: "bca",
      request_key: crypto.randomUUID(),
    });
    await command("submit_evidence", {
      id: late.payment_id,
      reference: "SIM-LATE-CONFIRM",
    });
    await clock("2027-02-19T08:59:59+07:00", other);
    assert(
      (await snapshot("2026-2")).registration.status === "inactive",
      "just before deadline",
    );
    await clock("2027-02-19T09:00:00+07:00", other);
    assert(
      !(await command("create_payment", {
        installment_id: inv.installments[0].id,
        channel: "bca",
        request_key: crypto.randomUUID(),
      })).ok,
      "exact deadline blocks even without scheduled task",
    );
    s = await snapshot("2026-2");
    assert(
      s.registration.status === "auto_leave",
      "auto-leave persisted despite rejected command",
    );
    await clock("2027-02-19T09:00:01+07:00", other);
    assert(
      (await snapshot("2026-2")).notifications.filter((
        n: { event_key: string },
      ) => n.event_key === "auto-leave").length === 1,
      "auto leave once",
    );
    await login(staff);
    const delayed = {
      student_id: other,
      id: late.payment_id,
      reference: late.payment_id,
      bank_reference: "SIM-LATE-CONFIRM",
      paid_at: "2027-01-19T09:01:00+07:00",
      amount: inv.installments[0].amount,
      currency: "IDR",
      decision: "approved",
      reason: "Konfirmasi bank simulasi tertunda",
    };
    assert(
      (await command("verify_payment", delayed)).ok,
      "late trusted confirmation",
    );
    await login(other);
    assert(
      (await snapshot("2026-2")).registration.status === "auto_leave",
      "verification alone cannot override cuti",
    );
    await login(staff);
    assert(
      (await command("reconcile", delayed)).ok,
      "authorized reconciliation",
    );
    await login(other);
    assert(
      (await snapshot("2026-2")).registration.status === "active",
      "on-time payment restores activation",
    );
    // Constraint validations exercise the actual SQL, not a UI validator copy.
    await clock("2027-01-20T09:00:00+07:00", other);
    const employeeIds = ["CIE201", "CIE202"].map((c) => `2026-2-employee-${c}`);
    await admin("update public.m2_periods set max_credits=2 where id='2026-2'");
    await login(other);
    assert(
      !(await command("save_krs", { version: 0, offering_ids: employeeIds }))
        .ok,
      "credit limit",
    );
    await admin(
      "update public.m2_periods set max_credits=24 where id='2026-2'",
    );
    await admin(
      "update public.m2_courses set prerequisites=array['CSF101'] where code='CIE201'",
    );
    await login(other);
    assert(
      !(await command("save_krs", { version: 0, offering_ids: employeeIds }))
        .ok,
      "unmet prerequisite",
    );
    await admin(
      "update public.m2_courses set prerequisites='{}' where code='CIE201'",
    );
    await admin(
      "insert into public.m2_slots values('collision','2026-2-employee-CIE202',1,'18:30','19:30','Praktikum')",
    );
    await login(other);
    assert(
      !(await command("save_krs", { version: 0, offering_ids: employeeIds }))
        .ok,
      "practical slot collision",
    );
    await admin("delete from public.m2_slots where id='collision'");
    await login(other);
    assert(
      (await command("save_krs", { version: 0, offering_ids: employeeIds })).ok,
      "valid after constraints restored",
    );
    // Schedule changes and cancellation use latest revision in all snapshots.
    await clock("2027-02-08T09:30:00+07:00", owner);
    await login(staff);
    const eventChange = {
      student_id: owner,
      id: ids[0] + "-m1",
      revision: 1,
      starts_at: "2027-02-08T10:00:00+07:00",
      ends_at: "2027-02-08T12:00:00+07:00",
      room: "Ruang Demo Baru",
      mode: "Tatap muka",
      reason: "Perubahan jadwal fixture",
    };
    assert(
      (await command("publish_event", eventChange)).ok,
      "publish changed schedule",
    );
    assert(
      !(await command("publish_event", eventChange)).ok,
      "stale event revision rejected",
    );
    await login();
    s = await snapshot("2026-2");
    assert(
      s.events.find((e: { id: string }) => e.id === eventChange.id).room ===
        "Ruang Demo Baru",
      "snapshot reads revised room",
    );
    assert(
      s.notifications.some((n: { event_key: string }) =>
        n.event_key === `event:${eventChange.id}:2`
      ),
      "reminder uses new revision/time",
    );
    await login(staff);
    assert(
      (await command("publish_event", {
        ...eventChange,
        revision: 2,
        cancelled: true,
      })).ok,
      "cancel schedule",
    );
    await login();
    assert(
      (await snapshot("2026-2")).events.find((e: { id: string }) =>
        e.id === eventChange.id
      ).cancelled,
      "cancellation remains explicit",
    );
    const finance = (await db.query<{ v: { amount: number; paid: number }[] }>(
      "select public.m2_finance() v",
    )).rows[0].v;
    assert(
      finance.some((v) => v.paid === 5833334),
      "finance projection shares allocations",
    );
    await denied(`select public.m2_review('${other}','2026-2')`);
    // Complete payment tests per plan, including remainder distribution.
    const newFixture = async (n: number) => {
      const id = `55555555-5555-4555-8555-${n.toString().padStart(12, "0")}`;
      await admin("insert into auth.users(id) values($1)", [id]);
      await admin(
        "insert into public.profiles(id,full_name,is_enabled) values($1,'M2 extra fixture',true)",
        [id],
      );
      await admin(
        "insert into public.students(user_id,nim,university,faculty,program) values($1,$2,'Test','Test','Teknik Informatika')",
        [id, `99999${n.toString().padStart(5, "0")}`],
      );
      await admin(
        "insert into auth.sessions(id,user_id,created_at,updated_at) values($1,$2,now(),now())",
        [sid(id), id],
      );
      await admin("select public.register_profile_session($1,$2)", [
        sid(id),
        id,
      ]);
      await admin("select private.m2_seed_dante($1,'MKU102')", [id]);
      await clock("2027-01-19T09:00:00+07:00", id);
      return id;
    };
    const tuitionRows = await admin(
      "select n,private.m2_tuition('Teknik Informatika',n) fee from generate_series(1,12) n",
    );
    assert(
      tuitionRows.rows.slice(0, 8).reduce(
        (sum, r) => sum + Number(r.fee),
        0,
      ) === 140000000,
      "eight semesters total 140 million",
    );
    assert(
      tuitionRows.rows.slice(8).every((r) => Number(r.fee) === 10000000),
      "semester nine onward 10 million",
    );
    for (const count of [1, 3, 6]) {
      const id = await newFixture(count);
      await command("register", { track: "regular" });
      const preview = await command("preview_plan", { count });
      assert(
        preview.principal === 17500000 && preview.installments.length === count,
        "server plan preview",
      );
      assert(
        (await snapshot("2026-2")).invoices.length === 0,
        "preview never writes invoice",
      );
      await command("plan", { count });
      s = await snapshot("2026-2");
      const invoice = s.invoices[0];
      assert(
        invoice.installments.reduce(
          (sum: number, v: { amount: number }) => sum + v.amount,
          0,
        ) === 17500000,
        `remainder sum ${count}`,
      );
      for (const installment of invoice.installments) {
        const channel =
          installment.ordinal === 1 && installment.amount <= 10000000
            ? "qris"
            : "bca";
        if (installment.amount > 10000000) {
          assert(
            !(await command("create_payment", {
              installment_id: installment.id,
              channel: "qris",
              request_key: crypto.randomUUID(),
            })).ok,
            "full tuition exceeds QRIS limit; use BCA",
          );
        }
        let payment = await command("create_payment", {
          installment_id: installment.id,
          channel,
          request_key: crypto.randomUUID(),
        });
        assert(payment.ok, `create ${count}/${installment.ordinal}`);
        if (channel === "bca") {
          await command("submit_evidence", {
            id: payment.payment_id,
            reference: `SIM-${count}-${installment.ordinal}`,
          });
        }
        if (count === 1) {
          await login(staff);
          assert(
            (await command("verify_payment", {
              student_id: id,
              id: payment.payment_id,
              decision: "rejected",
              reason: "Bukti simulasi ditolak",
            })).ok,
            "BCA rejection recorded",
          );
          await login(id);
          assert(
            (await snapshot("2026-2")).registration.status === "inactive",
            "rejected payment does not activate",
          );
          payment = await command("create_payment", {
            installment_id: installment.id,
            channel,
            request_key: crypto.randomUUID(),
          });
          await command("submit_evidence", {
            id: payment.payment_id,
            reference: "SIM-CORRECTED",
          });
        }
        await login(staff);
        const evidence = {
          student_id: id,
          id: payment.payment_id,
          reference: payment.payment_id,
          amount: installment.amount,
          currency: "IDR",
          bank_reference: `SIM-PLAN-${count}-${installment.ordinal}`,
          paid_at: "2027-01-19T09:00:00+07:00",
          decision: "approved",
          reason: "Konfirmasi simulator valid",
        };
        assert(
          (await command("verify_payment", evidence)).ok,
          `verified ${count}/${installment.ordinal}`,
        );
        await login(id);
        s = await snapshot("2026-2");
        assert(s.registration.status === "active", `activation plan ${count}`);
        assert(
          (s.invoices[0].paid === s.invoices[0].principal) ===
            (installment.ordinal === count),
          `full paid only at final installment ${count}`,
        );
      }
      assert(
        s.notifications.filter((n: { event_key: string }) =>
          n.event_key === `settled:${invoice.id}`
        ).length === 1,
        `one settled notification ${count}`,
      );
      await clock("2027-08-01T09:00:00+07:00", id);
      assert(
        !(await snapshot("2026-2")).notifications.some((
          n: { event_key: string },
        ) => n.event_key.startsWith("overdue:")),
        "no reminders for settled invoices",
      );
    }
    const leaveUser = await newFixture(10);
    await command("request_leave", { reason: "Cuti fixture disetujui" });
    s = await snapshot("2026-2");
    await login(staff);
    await command("decide_leave", {
      student_id: leaveUser,
      id: s.leave_requests[0].id,
      decision: "approved",
      reason: "Syarat demo terpenuhi",
    });
    await clock("2027-04-01T09:00:00+07:00", leaveUser);
    s = await snapshot("2026-2");
    assert(
      s.registration.status === "leave_approved" && s.invoices.length === 0,
      "approved voluntary leave survives deadline",
    );
    assert(
      (await snapshot("2026-1")).krs.status === "approved",
      "leave does not erase previous KRS",
    );
    // Actually late payment: allocated only by reconciliation; never self-activates.
    for (const onTime of [true, false]) {
      const id = await newFixture(onTime ? 11 : 12);
      await command("register", { track: "regular" });
      await command("plan", { count: 1 });
      s = await snapshot("2026-2");
      const installment = s.invoices[0].installments[0];
      await clock("2027-02-19T08:59:00+07:00", id);
      const payment = await command("create_payment", {
        installment_id: installment.id,
        channel: "bca",
        request_key: crypto.randomUUID(),
      });
      await command("submit_evidence", {
        id: payment.payment_id,
        reference: "SIM-LATE",
      });
      await clock("2027-03-02T09:00:00+07:00", id);
      await snapshot("2026-2");
      await login(staff);
      const evidence = {
        student_id: id,
        id: payment.payment_id,
        reference: payment.payment_id,
        amount: installment.amount,
        currency: "IDR",
        bank_reference: `SIM-ACTUAL-LATE-${onTime}`,
        paid_at: onTime
          ? "2027-02-19T08:59:59+07:00"
          : "2027-02-19T09:00:00+07:00",
        decision: "approved",
        reason: "Rekonsiliasi fixture",
      };
      await command("verify_payment", evidence);
      assert(
        (await command("reconcile", evidence)).ok,
        "late verification reconciled",
      );
      await login(id);
      s = await snapshot("2026-2");
      assert(
        s.registration.status === (onTime ? "active" : "auto_leave"),
        "actual payment timestamp determines restoration",
      );
      assert(
        !(await command("save_krs", { version: 0, offering_ids: ids })).ok,
        "reconciliation never reopens closed KRS",
      );
    }
    await admin(
      "update private.app_sessions set revoked_at=now() where user_id=$1",
      [other],
    );
    await login(other);
    await denied("select public.m2_snapshot(null)");
    await admin(
      "update private.app_sessions set expires_at=now()-interval '1 second' where user_id=$1",
      [owner],
    );
    await login();
    await denied("select public.m2_snapshot(null)");
    // A genuine lecturer has no students row or personal enrollment.
    const lecturer = "44444444-4444-4444-8444-444444444444";
    await admin(
      "insert into auth.users(id,email) values($1,'lecturer@example.test')",
      [lecturer],
    );
    await admin(
      "insert into public.profiles(id,full_name,role,is_enabled) values($1,'Lecturer fixture','lecturer',true)",
      [lecturer],
    );
    await admin(
      "insert into private.m2_staff_identities values($1,'0221028503')",
      [lecturer],
    );
    await admin(
      "insert into private.m2_staff select $1,unnest(array['academic','validator'])",
      [lecturer],
    );
    await admin(
      "insert into auth.sessions(id,user_id,created_at,updated_at) values($1,$2,now(),now())",
      [sid(lecturer), lecturer],
    );
    await admin("select public.register_profile_session($1,$2)", [
      sid(lecturer),
      lecturer,
    ]);
    const resolved = await admin(
      "select public.resolve_student_login('0221028503') as email",
    );
    assert(
      resolved.rows[0].email === "lecturer@example.test",
      "NIDN resolves only enabled staff",
    );
    await admin("update private.m2_staff_identities set login_id='112233' where user_id=$1", [lecturer]);
    const shortNip = await admin("select public.resolve_student_login('112233') as email");
    assert(shortNip.rows[0].email === "lecturer@example.test", "six-digit NIP resolves authorized staff");
    let invalidNip = false;
    try { await admin("update private.m2_staff_identities set login_id='12345' where user_id=$1", [lecturer]); }
    catch (e) { invalidNip = (e as {code: string}).code === '23514'; }
    assert(invalidNip, "shorter NIP rejected by constraint");
    await admin("update private.m2_staff_identities set login_id='0221028503' where user_id=$1", [lecturer]);
    await login(lecturer);
    const identity = (await db.query<{ v: { login_id: string } }>(
      "select public.m2_staff_identity() v",
    )).rows[0].v;
    assert(
      identity.login_id === "0221028503",
      "staff identity from private RPC",
    );
    s = await snapshot(null);
    assert(
      s.staff && s.periods.length === 2 &&
        Object.keys(s.registration).length === 0,
      "staff context needs no enrollment",
    );
    assert(
      s.permissions.includes("validator") && !s.permissions.includes("finance"),
      "academic permissions exclude finance",
    );
    assert(
      (await db.query("select * from public.students")).rows.length === 0,
      "staff cannot read student table directly",
    );
    await denied(
      `select public.m2_command('verify_payment','2026-1','{"student_id":"${owner}"}')`,
    );
    await denied(`select private.m2_student_snapshot('2026-1')`);
    const review = (await db.query<{ v: { payments: unknown[] } }>(
      "select public.m2_review($1,$2) v",
      [owner, "2026-1"],
    )).rows[0].v;
    assert(
      review.payments.length === 0,
      "academic review excludes financial transactions",
    );
    const byNim = (await db.query<{ v: { student: { user_id: string } } }>(
      "select public.m2_review_student('999999900','2026-1') v",
    )).rows[0].v;
    assert(
      byNim.student.user_id === owner,
      "staff lookup uses NIM and returns the reviewed owner",
    );
    await admin(
      "update private.m2_staff_identities set email_delivery_enabled=false where user_id=$1",
      [lecturer],
    );
    const dummyRecovery = await admin(
      "select public.issue_password_reset('lecturer@example.test',repeat('a',64),repeat('f',64),gen_random_uuid()) v",
    );
    assert(
      (dummyRecovery.rows[0].v as { user_id: string | null }).user_id === null,
      "dummy email never produces a recovery recipient",
    );
    await admin(
      "update private.m2_staff_identities set email_delivery_enabled=true where user_id=$1",
      [lecturer],
    );
    const realRecovery = await admin(
      "select public.issue_password_reset('lecturer@example.test',repeat('b',64),repeat('f',64),gen_random_uuid()) v",
    );
    assert(
      (realRecovery.rows[0].v as { user_id: string | null }).user_id ===
        lecturer,
      "explicit email-enabled staff can recover",
    );
    await admin(
      "update auth.users set email='student@example.test' where id=$1",
      [owner],
    );
    const studentRecovery = await admin(
      "select public.issue_password_reset('student@example.test',repeat('c',64),repeat('f',64),gen_random_uuid()) v",
    );
    assert(
      (studentRecovery.rows[0].v as { user_id: string | null }).user_id ===
        owner,
      "M1 student email recovery preserved",
    );
    await admin(
      "insert into auth.mfa_factors(user_id,status) values($1,'verified')",
      [owner],
    );
    const mfaRecovery = await admin(
      "select public.issue_password_reset('student@example.test',repeat('d',64),repeat('f',64),gen_random_uuid()) v",
    );
    assert(
      (mfaRecovery.rows[0].v as { user_id: string | null }).user_id === null,
      "M1 MFA bypass prevention preserved",
    );
    await admin("delete from private.m2_staff where user_id=$1", [lecturer]);
    const disabledLogin = await admin(
      "select public.resolve_student_login('0221028503') as email",
    );
    assert(
      disabledLogin.rows[0].email === null,
      "revoked staff permissions disable NIDN login",
    );
    console.log(
      `M2 PostgreSQL: ${checks} assertions passed; concurrency is serialized in one WASM connection, not a live multi-connection test.`,
    );
  } finally {
    await db.close();
  }
});
