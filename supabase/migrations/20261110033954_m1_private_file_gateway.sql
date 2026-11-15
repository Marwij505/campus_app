-- Direct reads/signing/transforms can outlive RLS access in the Storage CDN.
-- File bytes now pass through private-file, with fresh owner/session checks.
-- SELECT remains available solely for owner deletion (including upload cleanup).
alter policy document_read on storage.objects using (
  bucket_id='student-documents'
  and (storage.foldername(name))[1]=(select auth.uid())::text
  and (select private.profile_session_valid())
  and storage.allow_any_operation(array['object.delete','object.delete_many'])
);
alter policy avatar_read on storage.objects using (
  bucket_id='student-avatars'
  and (storage.foldername(name))[1]=(select auth.uid())::text
  and (select private.profile_session_valid())
  and storage.allow_any_operation(array['object.delete','object.delete_many'])
);
