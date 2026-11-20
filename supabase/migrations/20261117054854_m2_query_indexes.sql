-- Cover foreign-key lookups used by RLS, KRS scheduling, and staff decisions.
create index m2_equivalences_target on public.m2_equivalences(target_course);
create index m2_krs_decider on public.m2_krs(decided_by);
create index m2_krs_items_offering on public.m2_krs_items(offering_id);
create index m2_leave_decider on public.m2_leave_requests(decided_by);
create index m2_offerings_course on public.m2_offerings(course_code);
create index m2_payments_verifier on public.m2_payments(verified_by);
create index m2_registrations_period on public.m2_registrations(period_id);
create index m2_slots_offering on public.m2_slots(offering_id);
