-- User-authorized six-digit staff demo NIP; existing NIM/NIDN remain valid.
alter table private.m2_staff_identities
 drop constraint m2_staff_identities_login_id_check,
 add constraint m2_staff_identities_login_id_check
 check(login_id ~ '^[0-9]{6,20}$');
