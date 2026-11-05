-- Storage buckets (one per purpose) and Realtime.
--
-- Every object path starts with the owner's user id: {uid}/{file}.jpg
-- The app compresses to JPEG first, so buckets accept only image/jpeg.
--
--   work-photos     public read. Worker gallery, which exists to be seen.
--   job-photos      private. Signed URLs for the customer and matching workers.
--   cnic-documents  private. Upload only: no client can read or delete these.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('work-photos', 'work-photos', true, 2097152, array['image/jpeg']),
  ('job-photos', 'job-photos', false, 2097152, array['image/jpeg']),
  ('cnic-documents', 'cnic-documents', false, 3145728, array['image/jpeg'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- work-photos. The SELECT policy is needed because Storage must see an object to
-- delete it; public reads go through the public URL and do not use this policy.
create policy "work-photos: upload own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'work-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "work-photos: read own" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'work-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "work-photos: delete own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'work-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- job-photos
create policy "job-photos: upload own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'job-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Readable by anyone who can see a job that references the file. That lookup goes
-- through job_requests RLS, so visibility follows the job.
create policy "job-photos: read own or via visible job" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'job-photos'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or exists (select 1 from public.job_requests j where name = any (j.photo_paths))
    )
  );

create policy "job-photos: delete own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'job-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- cnic-documents: upload only. Reviewers use the dashboard.
create policy "cnic-documents: upload own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'cnic-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Live "Interested Workers" list. Delivery respects the RLS policies above.
alter publication supabase_realtime add table public.job_interests;
