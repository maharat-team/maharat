-- Row Level Security and privileges.
--
-- RLS decides which rows a user reaches; column grants decide which fields they
-- can write. Supabase grants ALL to anon/authenticated by default, so those
-- defaults are removed and each table states exactly what it allows.
-- anon gets nothing: the app requires sign-in before any data is shown.

revoke all on all tables in schema public from anon, authenticated;
revoke all on all routines in schema public from public, anon, authenticated;
revoke all on all routines in schema private from public, anon, authenticated;

grant execute on function public.submit_worker_application(
  text, text, text, integer, integer, text[], text, text, text, text
) to authenticated;

alter table public.profiles enable row level security;
alter table public.workers enable row level security;
alter table public.worker_photos enable row level security;
alter table public.cnic_verifications enable row level security;
alter table public.job_requests enable row level security;
alter table public.job_interests enable row level security;
alter table public.reviews enable row level security;

-- Policy helpers. SECURITY DEFINER keeps these lookups from re-entering RLS.

create function private.approved_worker_trade()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select trade from public.workers
  where id = auth.uid() and verification_status = 'approved';
$$;

create function private.can_express_interest(p_job_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.job_requests j
    join public.workers w on w.id = auth.uid()
    where j.id = p_job_id
      and j.status = 'active'
      and j.customer_id <> w.id
      and j.trade = w.trade
      and w.verification_status = 'approved'
  );
$$;

grant execute on function private.approved_worker_trade() to authenticated;
grant execute on function private.can_express_interest(uuid) to authenticated;

-- profiles: private to their owner.
grant select on public.profiles to authenticated;
grant update (full_name, phone, language, active_role, neighbourhood)
  on public.profiles to authenticated;

create policy "profiles: read own" on public.profiles
  for select to authenticated
  using (id = (select auth.uid()));

create policy "profiles: update own" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- workers: approved workers form the public directory. Rows are created only by
-- submit_worker_application. Ratings and verification are not client-writable.
grant select on public.workers to authenticated;
grant update (phone, bio, experience_years, visit_fee, neighbourhood, service_areas, is_available_today)
  on public.workers to authenticated;

create policy "workers: read approved or own" on public.workers
  for select to authenticated
  using (verification_status = 'approved' or id = (select auth.uid()));

create policy "workers: update own" on public.workers
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- worker_photos
grant select, delete on public.worker_photos to authenticated;
grant insert (worker_id, storage_path) on public.worker_photos to authenticated;

create policy "worker_photos: read approved or own" on public.worker_photos
  for select to authenticated
  using (
    worker_id = (select auth.uid())
    or exists (
      select 1 from public.workers w
      where w.id = worker_id and w.verification_status = 'approved'
    )
  );

create policy "worker_photos: insert own" on public.worker_photos
  for insert to authenticated
  with check (worker_id = (select auth.uid()));

create policy "worker_photos: delete own" on public.worker_photos
  for delete to authenticated
  using (worker_id = (select auth.uid()));

-- cnic_verifications: a worker sees only their status. The CNIC number and file
-- paths are not granted to any client role.
grant select (worker_id, status, rejection_reason, submitted_at, reviewed_at)
  on public.cnic_verifications to authenticated;

create policy "cnic: read own status" on public.cnic_verifications
  for select to authenticated
  using (worker_id = (select auth.uid()));

-- job_requests
grant select on public.job_requests to authenticated;
grant insert (trade, description, location, urgency, photo_paths)
  on public.job_requests to authenticated;
grant update (status, assigned_worker_id) on public.job_requests to authenticated;

create policy "jobs: read own, assigned, or open in trade" on public.job_requests
  for select to authenticated
  using (
    customer_id = (select auth.uid())
    or assigned_worker_id = (select auth.uid())
    or (status = 'active' and trade = (select private.approved_worker_trade()))
  );

create policy "jobs: insert own" on public.job_requests
  for insert to authenticated
  with check (customer_id = (select auth.uid()));

create policy "jobs: update own" on public.job_requests
  for update to authenticated
  using (customer_id = (select auth.uid()))
  with check (customer_id = (select auth.uid()));

-- job_interests
grant select on public.job_interests to authenticated;
grant insert (job_id, worker_id) on public.job_interests to authenticated;

create policy "interests: read own or on own job" on public.job_interests
  for select to authenticated
  using (
    worker_id = (select auth.uid())
    or exists (
      select 1 from public.job_requests j
      where j.id = job_id and j.customer_id = (select auth.uid())
    )
  );

create policy "interests: approved worker on open job" on public.job_interests
  for insert to authenticated
  with check (
    worker_id = (select auth.uid())
    and private.can_express_interest(job_id)
  );

-- reviews: public to signed-in users; written once by the customer whose
-- completed job this worker was assigned to. No edits or deletes.
grant select on public.reviews to authenticated;
grant insert (job_id, worker_id, rating, comment, tags) on public.reviews to authenticated;

create policy "reviews: read" on public.reviews
  for select to authenticated
  using (true);

create policy "reviews: customer of completed job" on public.reviews
  for insert to authenticated
  with check (
    customer_id = (select auth.uid())
    and exists (
      select 1 from public.job_requests j
      where j.id = job_id
        and j.customer_id = (select auth.uid())
        and j.status = 'completed'
        and j.assigned_worker_id = worker_id
    )
  );
