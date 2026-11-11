-- Maharat v2: map locations, automatic face verification, contractors (shops
-- with a team of workers), and account deletion.
--
-- Access rules follow the first migrations: RLS decides rows, column grants
-- decide writable fields, and anything that changes more than one row or
-- another user's data goes through a SECURITY DEFINER function with its own
-- checks.

-- ---------------------------------------------------------------------------
-- 1. Locations
-- ---------------------------------------------------------------------------
-- Coordinates are limited to the Bahawalpur area. Exact points are private:
-- profiles are owner-only, worker base points are rounded (~1 km), and a job's
-- exact pin lives in job_locations, readable only by the people working it.

alter table public.profiles
  add column lat double precision check (lat between 29.0 and 29.8),
  add column lng double precision check (lng between 71.3 and 72.1),
  add column address_details text not null default ''
    check (char_length(address_details) <= 200);

grant update (lat, lng, address_details) on public.profiles to authenticated;

alter table public.workers
  add column base_lat double precision check (base_lat between 29.0 and 29.8),
  add column base_lng double precision check (base_lng between 71.3 and 72.1);

grant update (base_lat, base_lng) on public.workers to authenticated;

create function private.round_worker_base()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.base_lat := round(new.base_lat::numeric, 2)::double precision;
  new.base_lng := round(new.base_lng::numeric, 2)::double precision;
  return new;
end;
$$;

create trigger workers_round_base before insert or update of base_lat, base_lng
  on public.workers
  for each row execute function private.round_worker_base();

-- ---------------------------------------------------------------------------
-- 2. Contractors
-- ---------------------------------------------------------------------------

create type public.order_status as enum ('pending', 'accepted', 'declined');
create type public.member_status as enum ('invited', 'active');

create table public.contractors (
  id uuid primary key references public.profiles (id) on delete cascade,
  business_name text not null check (char_length(btrim(business_name)) between 2 and 80),
  owner_name text not null,
  phone text not null check (phone ~ '^\+92[0-9]{10}$'),
  trades text[] not null check (
    cardinality(trades) > 0
    and trades <@ array['Electrician', 'Plumber', 'Mason', 'Carpenter', 'Painter', 'AC Technician']::text[]
  ),
  bio text not null default '' check (char_length(bio) <= 1000),
  neighbourhood text not null,
  service_areas text[] not null check (cardinality(service_areas) > 0),
  shop_address text not null default '' check (char_length(shop_address) <= 200),
  lat double precision check (lat between 29.0 and 29.8),
  lng double precision check (lng between 71.3 and 72.1),
  shop_photo_path text,
  is_accepting_orders boolean not null default true,
  verification_status public.verification_status not null default 'pending',
  rating_avg numeric(2, 1) not null default 0,
  review_count integer not null default 0,
  completed_jobs_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index contractors_directory_idx on public.contractors (rating_avg desc)
  where verification_status = 'approved';

create trigger contractors_updated_at before update on public.contractors
  for each row execute function private.set_updated_at();

create table public.contractor_verifications (
  contractor_id uuid primary key references public.contractors (id) on delete cascade,
  cnic_number text not null unique check (cnic_number ~ '^[0-9]{5}-[0-9]{7}-[0-9]$'),
  front_path text not null,
  back_path text not null,
  selfie_path text not null,
  status public.verification_status not null default 'pending',
  rejection_reason text,
  rejection_code text,
  face_match_score numeric(5, 2),
  cnic_number_matched boolean,
  face_checked_at timestamptz,
  attempt_count integer not null default 0,
  attempt_window_start timestamptz not null default now(),
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create table public.contractor_members (
  contractor_id uuid not null references public.contractors (id) on delete cascade,
  worker_id uuid not null references public.workers (id) on delete cascade,
  status public.member_status not null default 'invited',
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  primary key (contractor_id, worker_id)
);

create index contractor_members_worker_idx on public.contractor_members (worker_id);

-- Keep the shop's owner name in step with the profile, like workers.full_name.
create or replace function private.sync_worker_name()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.workers set full_name = new.full_name where id = new.id;
  update public.contractors set owner_name = new.full_name where id = new.id;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Automatic face verification (shared by workers and contractors)
-- ---------------------------------------------------------------------------
-- The verify-identity Edge Function compares the CNIC front photo with a live
-- selfie and writes the result with the service role. A score of 80 or more
-- approves the account; anything lower rejects it with a reason the user sees.

alter table public.cnic_verifications
  add column rejection_code text,
  add column face_match_score numeric(5, 2),
  add column cnic_number_matched boolean,
  add column face_checked_at timestamptz,
  add column attempt_count integer not null default 0,
  add column attempt_window_start timestamptz not null default now();

create function private.apply_contractor_decision()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status <> 'pending' then
    new.reviewed_at := now();
  end if;
  update public.contractors set verification_status = new.status where id = new.contractor_id;
  return new;
end;
$$;

create trigger contractor_apply_decision before update of status on public.contractor_verifications
  for each row when (old.status is distinct from new.status)
  execute function private.apply_contractor_decision();

-- Worker application, now with a base location and an attempt limit that
-- keeps face checks (which cost money) from being run in a loop.
drop function public.submit_worker_application(
  text, text, text, integer, integer, text[], text, text, text, text
);

create function public.submit_worker_application(
  p_trade text,
  p_phone text,
  p_bio text,
  p_experience_years integer,
  p_visit_fee integer,
  p_service_areas text[],
  p_cnic_number text,
  p_front_path text,
  p_back_path text,
  p_selfie_path text,
  p_base_lat double precision default null,
  p_base_lng double precision default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  owner_name text;
  current_status public.verification_status;
  v_attempts integer;
  v_window timestamptz;
begin
  if uid is null then
    raise exception 'Please sign in again.';
  end if;

  select full_name into owner_name from public.profiles where id = uid;
  if coalesce(btrim(owner_name), '') = '' then
    raise exception 'Please complete your profile first.';
  end if;

  if p_front_path not like uid::text || '/%'
    or p_back_path not like uid::text || '/%'
    or p_selfie_path not like uid::text || '/%' then
    raise exception 'Invalid document upload.';
  end if;

  select status, attempt_count, attempt_window_start
    into current_status, v_attempts, v_window
  from public.cnic_verifications where worker_id = uid;

  if current_status in ('pending', 'approved') then
    raise exception 'Your application has already been submitted.';
  end if;

  if v_window is null or v_window < now() - interval '1 day' then
    v_attempts := 0;
    v_window := now();
  end if;
  if v_attempts >= 5 then
    raise exception 'Too many attempts today. Please try again tomorrow.';
  end if;

  if exists (
    select 1 from public.cnic_verifications
    where cnic_number = p_cnic_number and worker_id <> uid
  ) then
    raise exception 'This CNIC is already registered.';
  end if;

  insert into public.workers (
    id, full_name, trade, phone, bio, experience_years, visit_fee, neighbourhood,
    service_areas, base_lat, base_lng
  ) values (
    uid, owner_name, p_trade, p_phone, p_bio, p_experience_years, p_visit_fee,
    p_service_areas[1], p_service_areas, p_base_lat, p_base_lng
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    trade = excluded.trade,
    phone = excluded.phone,
    bio = excluded.bio,
    experience_years = excluded.experience_years,
    visit_fee = excluded.visit_fee,
    neighbourhood = excluded.neighbourhood,
    service_areas = excluded.service_areas,
    base_lat = coalesce(excluded.base_lat, public.workers.base_lat),
    base_lng = coalesce(excluded.base_lng, public.workers.base_lng);

  insert into public.cnic_verifications (
    worker_id, cnic_number, front_path, back_path, selfie_path,
    attempt_count, attempt_window_start
  ) values (
    uid, p_cnic_number, p_front_path, p_back_path, p_selfie_path,
    v_attempts + 1, v_window
  )
  on conflict (worker_id) do update set
    cnic_number = excluded.cnic_number,
    front_path = excluded.front_path,
    back_path = excluded.back_path,
    selfie_path = excluded.selfie_path,
    status = 'pending',
    rejection_reason = null,
    rejection_code = null,
    face_match_score = null,
    cnic_number_matched = null,
    face_checked_at = null,
    attempt_count = excluded.attempt_count,
    attempt_window_start = excluded.attempt_window_start,
    submitted_at = now(),
    reviewed_at = null;

  update public.profiles set active_role = 'worker' where id = uid;
end;
$$;

create function public.submit_contractor_application(
  p_business_name text,
  p_phone text,
  p_trades text[],
  p_bio text,
  p_service_areas text[],
  p_shop_address text,
  p_lat double precision,
  p_lng double precision,
  p_shop_photo_path text,
  p_cnic_number text,
  p_front_path text,
  p_back_path text,
  p_selfie_path text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  v_owner text;
  current_status public.verification_status;
  v_attempts integer;
  v_window timestamptz;
begin
  if uid is null then
    raise exception 'Please sign in again.';
  end if;

  select full_name into v_owner from public.profiles where id = uid;
  if coalesce(btrim(v_owner), '') = '' then
    raise exception 'Please complete your profile first.';
  end if;

  if p_front_path not like uid::text || '/%'
    or p_back_path not like uid::text || '/%'
    or p_selfie_path not like uid::text || '/%'
    or (p_shop_photo_path is not null and p_shop_photo_path not like uid::text || '/%') then
    raise exception 'Invalid document upload.';
  end if;

  select status, attempt_count, attempt_window_start
    into current_status, v_attempts, v_window
  from public.contractor_verifications where contractor_id = uid;

  if current_status in ('pending', 'approved') then
    raise exception 'Your application has already been submitted.';
  end if;

  if v_window is null or v_window < now() - interval '1 day' then
    v_attempts := 0;
    v_window := now();
  end if;
  if v_attempts >= 5 then
    raise exception 'Too many attempts today. Please try again tomorrow.';
  end if;

  if exists (
    select 1 from public.contractor_verifications
    where cnic_number = p_cnic_number and contractor_id <> uid
  ) then
    raise exception 'This CNIC is already registered.';
  end if;

  insert into public.contractors (
    id, business_name, owner_name, phone, trades, bio, neighbourhood,
    service_areas, shop_address, lat, lng, shop_photo_path
  ) values (
    uid, btrim(p_business_name), v_owner, p_phone, p_trades, p_bio, p_service_areas[1],
    p_service_areas, p_shop_address, p_lat, p_lng, p_shop_photo_path
  )
  on conflict (id) do update set
    business_name = excluded.business_name,
    owner_name = excluded.owner_name,
    phone = excluded.phone,
    trades = excluded.trades,
    bio = excluded.bio,
    neighbourhood = excluded.neighbourhood,
    service_areas = excluded.service_areas,
    shop_address = excluded.shop_address,
    lat = excluded.lat,
    lng = excluded.lng,
    shop_photo_path = coalesce(excluded.shop_photo_path, public.contractors.shop_photo_path);

  insert into public.contractor_verifications (
    contractor_id, cnic_number, front_path, back_path, selfie_path,
    attempt_count, attempt_window_start
  ) values (
    uid, p_cnic_number, p_front_path, p_back_path, p_selfie_path,
    v_attempts + 1, v_window
  )
  on conflict (contractor_id) do update set
    cnic_number = excluded.cnic_number,
    front_path = excluded.front_path,
    back_path = excluded.back_path,
    selfie_path = excluded.selfie_path,
    status = 'pending',
    rejection_reason = null,
    rejection_code = null,
    face_match_score = null,
    cnic_number_matched = null,
    face_checked_at = null,
    attempt_count = excluded.attempt_count,
    attempt_window_start = excluded.attempt_window_start,
    submitted_at = now(),
    reviewed_at = null;

  update public.profiles set active_role = 'contractor' where id = uid;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Orders to contractors, team assignment, exact job locations
-- ---------------------------------------------------------------------------

alter table public.job_requests
  add column contractor_id uuid references public.contractors (id) on delete set null,
  add column contractor_status public.order_status,
  add column customer_phone text,
  add column approx_lat double precision check (approx_lat between 29.0 and 29.8),
  add column approx_lng double precision check (approx_lng between 71.3 and 72.1);

create index job_requests_contractor_idx on public.job_requests (contractor_id, created_at desc);

create table public.job_assignments (
  job_id uuid not null references public.job_requests (id) on delete cascade,
  worker_id uuid not null references public.workers (id) on delete cascade,
  assigned_at timestamptz not null default now(),
  primary key (job_id, worker_id)
);

create index job_assignments_worker_idx on public.job_assignments (worker_id);

create table public.job_locations (
  job_id uuid primary key references public.job_requests (id) on delete cascade,
  lat double precision not null check (lat between 29.0 and 29.8),
  lng double precision not null check (lng between 71.3 and 72.1),
  address_details text not null default '' check (char_length(address_details) <= 200)
);

-- Job integrity, extended for contractor orders.
create or replace function private.prepare_job_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  owner_name text;
  owner_phone text;
begin
  select full_name, phone into owner_name, owner_phone
  from public.profiles where id = new.customer_id;
  if coalesce(btrim(owner_name), '') = '' then
    raise exception 'Please complete your profile before posting a job.';
  end if;
  if exists (
    select 1 from unnest(new.photo_paths) as path
    where path not like new.customer_id::text || '/%'
  ) then
    raise exception 'Invalid photo attachment.';
  end if;

  new.customer_name := owner_name;
  new.approx_lat := round(new.approx_lat::numeric, 2)::double precision;
  new.approx_lng := round(new.approx_lng::numeric, 2)::double precision;

  if new.contractor_id is not null then
    if new.contractor_id = new.customer_id then
      raise exception 'You cannot send an order to your own shop.';
    end if;
    if not exists (
      select 1 from public.contractors c
      where c.id = new.contractor_id
        and c.verification_status = 'approved'
        and c.is_accepting_orders
    ) then
      raise exception 'This contractor is not taking orders right now.';
    end if;
    new.contractor_status := 'pending';
    -- Only the chosen contractor and their assigned workers can read this job,
    -- and they need a number to call.
    new.customer_phone := owner_phone;
  else
    new.contractor_status := null;
    new.customer_phone := null;
  end if;
  return new;
end;
$$;

create or replace function private.guard_job_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user <> 'authenticated' then
    return new;
  end if;

  if old.status <> 'active' then
    raise exception 'This job is already finished.';
  end if;

  if new.status = 'completed' then
    if old.contractor_id is not null then
      if old.contractor_status is distinct from 'accepted' or not exists (
        select 1 from public.job_assignments a where a.job_id = new.id
      ) then
        raise exception 'The contractor has not assigned a worker to this job yet.';
      end if;
      new.assigned_worker_id := null;
    elsif new.assigned_worker_id is null or not exists (
      select 1 from public.job_interests i
      where i.job_id = new.id and i.worker_id = new.assigned_worker_id
    ) then
      raise exception 'Choose a worker who responded to this job.';
    end if;
    new.completed_at := now();
  elsif new.assigned_worker_id is not null then
    raise exception 'A worker can only be assigned when completing a job.';
  end if;

  return new;
end;
$$;

create or replace function private.count_completed_job()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.contractor_id is not null then
    update public.contractors
    set completed_jobs_count = completed_jobs_count + 1
    where id = new.contractor_id;
    update public.workers
    set completed_jobs_count = completed_jobs_count + 1
    where id in (select a.worker_id from public.job_assignments a where a.job_id = new.id);
  else
    update public.workers
    set completed_jobs_count = completed_jobs_count + 1
    where id = new.assigned_worker_id;
  end if;
  return new;
end;
$$;

-- Posting a job and its exact pin in one transaction. Runs as the caller, so
-- RLS and the triggers above still apply.
create function public.post_job(
  p_trade text,
  p_description text,
  p_location text,
  p_urgency public.job_urgency,
  p_photo_paths text[],
  p_contractor_id uuid default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_address_details text default ''
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_id uuid;
begin
  insert into public.job_requests (
    trade, description, location, urgency, photo_paths, contractor_id,
    approx_lat, approx_lng
  ) values (
    p_trade, p_description, p_location, p_urgency, coalesce(p_photo_paths, '{}'),
    p_contractor_id, p_lat, p_lng
  )
  returning id into v_id;

  if p_lat is not null and p_lng is not null then
    insert into public.job_locations (job_id, lat, lng, address_details)
    values (v_id, p_lat, p_lng, coalesce(p_address_details, ''));
  end if;

  return v_id;
end;
$$;

create function public.respond_to_order(p_job_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.job_requests
  set contractor_status = case when p_accept then 'accepted' else 'declined' end::public.order_status,
      status = case when p_accept then status else 'closed' end::public.job_status
  where id = p_job_id
    and contractor_id = auth.uid()
    and status = 'active'
    and contractor_status = 'pending';
  if not found then
    raise exception 'This order is no longer waiting for a reply.';
  end if;
end;
$$;

create function public.assign_order_team(p_job_id uuid, p_worker_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if coalesce(cardinality(p_worker_ids), 0) = 0 then
    raise exception 'Choose at least one worker.';
  end if;
  if not exists (
    select 1 from public.job_requests j
    where j.id = p_job_id and j.contractor_id = uid
      and j.status = 'active' and j.contractor_status = 'accepted'
  ) then
    raise exception 'Accept this order before sending workers.';
  end if;
  if exists (
    select 1 from unnest(p_worker_ids) as t(worker_id)
    where not exists (
      select 1 from public.contractor_members m
      where m.contractor_id = uid and m.worker_id = t.worker_id and m.status = 'active'
    )
  ) then
    raise exception 'Only members of your team can be sent.';
  end if;

  delete from public.job_assignments where job_id = p_job_id;
  insert into public.job_assignments (job_id, worker_id)
  select distinct p_job_id, t.worker_id from unnest(p_worker_ids) as t(worker_id);
end;
$$;

-- Team management ------------------------------------------------------------

create function public.invite_team_member(p_phone text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  v_worker_id uuid;
  v_name text;
begin
  if not exists (
    select 1 from public.contractors where id = uid and verification_status = 'approved'
  ) then
    raise exception 'Your shop must be verified before you can build a team.';
  end if;

  select id, full_name into v_worker_id, v_name
  from public.workers
  where phone = p_phone and verification_status = 'approved';

  if v_worker_id is null then
    raise exception 'No verified worker found with this number.';
  end if;

  insert into public.contractor_members (contractor_id, worker_id, status, responded_at)
  values (
    uid, v_worker_id,
    case when v_worker_id = uid then 'active' else 'invited' end::public.member_status,
    case when v_worker_id = uid then now() end
  )
  on conflict (contractor_id, worker_id) do nothing;

  return v_name;
end;
$$;

create function public.respond_to_team_invite(p_contractor_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_accept then
    update public.contractor_members
    set status = 'active', responded_at = now()
    where contractor_id = p_contractor_id and worker_id = auth.uid() and status = 'invited';
  else
    delete from public.contractor_members
    where contractor_id = p_contractor_id and worker_id = auth.uid() and status = 'invited';
  end if;
  if not found then
    raise exception 'This invitation is no longer available.';
  end if;
end;
$$;

-- Either side can end a membership: the contractor removes, the worker leaves.
create function public.remove_team_membership(p_contractor_id uuid, p_worker_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.contractor_members
  where contractor_id = p_contractor_id
    and worker_id = p_worker_id
    and auth.uid() in (p_contractor_id, p_worker_id);
end;
$$;

-- Reviews of contractors ------------------------------------------------------

alter table public.reviews
  alter column worker_id drop not null,
  add column contractor_id uuid references public.contractors (id) on delete cascade,
  add constraint reviews_one_subject check (num_nonnulls(worker_id, contractor_id) = 1);

create index reviews_contractor_idx on public.reviews (contractor_id, created_at desc);

create function private.refresh_contractor_rating()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target uuid := coalesce(new.contractor_id, old.contractor_id);
begin
  if target is null then
    return null;
  end if;
  update public.contractors c
  set rating_avg = coalesce(s.average, 0), review_count = s.total
  from (
    select round(avg(rating), 1) as average, count(*)::integer as total
    from public.reviews where contractor_id = target
  ) s
  where c.id = target;
  return null;
end;
$$;

create trigger reviews_refresh_contractor_rating after insert or delete on public.reviews
  for each row execute function private.refresh_contractor_rating();

-- ---------------------------------------------------------------------------
-- 5. Account deletion (required by app stores)
-- ---------------------------------------------------------------------------
-- Deleting the auth user cascades through profiles to every owned row.
create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Please sign in again.';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Privileges and RLS
-- ---------------------------------------------------------------------------

revoke all on public.contractors, public.contractor_verifications, public.contractor_members,
  public.job_assignments, public.job_locations from anon, authenticated;

revoke all on function
  public.submit_worker_application(text, text, text, integer, integer, text[], text, text, text, text, double precision, double precision),
  public.submit_contractor_application(text, text, text[], text, text[], text, double precision, double precision, text, text, text, text, text),
  public.post_job(text, text, text, public.job_urgency, text[], uuid, double precision, double precision, text),
  public.respond_to_order(uuid, boolean),
  public.assign_order_team(uuid, uuid[]),
  public.invite_team_member(text),
  public.respond_to_team_invite(uuid, boolean),
  public.remove_team_membership(uuid, uuid),
  public.delete_my_account()
from public, anon;

grant execute on function
  public.submit_worker_application(text, text, text, integer, integer, text[], text, text, text, text, double precision, double precision),
  public.submit_contractor_application(text, text, text[], text, text[], text, double precision, double precision, text, text, text, text, text),
  public.post_job(text, text, text, public.job_urgency, text[], uuid, double precision, double precision, text),
  public.respond_to_order(uuid, boolean),
  public.assign_order_team(uuid, uuid[]),
  public.invite_team_member(text),
  public.respond_to_team_invite(uuid, boolean),
  public.remove_team_membership(uuid, uuid),
  public.delete_my_account()
to authenticated;

revoke all on function
  private.round_worker_base(),
  private.apply_contractor_decision(),
  private.refresh_contractor_rating()
from public, anon, authenticated;

-- Policy helpers (SECURITY DEFINER so they do not re-enter RLS).
create function private.is_job_party(p_job_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.job_requests j
    where j.id = p_job_id
      and (j.customer_id = auth.uid() or j.contractor_id = auth.uid())
  );
$$;

create function private.is_assigned_to_job(p_job_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.job_assignments a
    where a.job_id = p_job_id and a.worker_id = auth.uid()
  );
$$;

create function private.can_see_exact_location(p_job_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.job_requests j
    where j.id = p_job_id
      and (
        j.customer_id = auth.uid()
        or j.contractor_id = auth.uid()
        or exists (
          select 1 from public.job_interests i
          where i.job_id = j.id and i.worker_id = auth.uid()
        )
        or exists (
          select 1 from public.job_assignments a
          where a.job_id = j.id and a.worker_id = auth.uid()
        )
      )
  );
$$;

revoke all on function
  private.is_job_party(uuid),
  private.is_assigned_to_job(uuid),
  private.can_see_exact_location(uuid)
from public, anon;
grant execute on function
  private.is_job_party(uuid),
  private.is_assigned_to_job(uuid),
  private.can_see_exact_location(uuid)
to authenticated;

-- Open jobs in a trade are only the broadcast ones; contractor orders are
-- private to that contractor.
create or replace function private.can_express_interest(p_job_id uuid)
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
      and j.contractor_id is null
      and j.customer_id <> w.id
      and j.trade = w.trade
      and w.verification_status = 'approved'
  );
$$;

-- contractors
alter table public.contractors enable row level security;
grant select on public.contractors to authenticated;
grant update (business_name, phone, trades, bio, neighbourhood, service_areas,
  shop_address, lat, lng, is_accepting_orders)
  on public.contractors to authenticated;

create policy "contractors: read approved or own" on public.contractors
  for select to authenticated
  using (verification_status = 'approved' or id = (select auth.uid()));

create policy "contractors: update own" on public.contractors
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- contractor_verifications: own status only.
alter table public.contractor_verifications enable row level security;
grant select (contractor_id, status, rejection_reason, rejection_code, face_match_score,
  submitted_at, reviewed_at)
  on public.contractor_verifications to authenticated;

create policy "contractor verification: read own status" on public.contractor_verifications
  for select to authenticated
  using (contractor_id = (select auth.uid()));

-- cnic_verifications: expose the new result columns to their owner.
grant select (rejection_code, face_match_score) on public.cnic_verifications to authenticated;

-- contractor_members: active teams are public; invitations are private.
alter table public.contractor_members enable row level security;
grant select on public.contractor_members to authenticated;

create policy "members: read active, own invites, own team" on public.contractor_members
  for select to authenticated
  using (
    status = 'active'
    or worker_id = (select auth.uid())
    or contractor_id = (select auth.uid())
  );

-- job_assignments
alter table public.job_assignments enable row level security;
grant select on public.job_assignments to authenticated;

create policy "assignments: read own or own job" on public.job_assignments
  for select to authenticated
  using (worker_id = (select auth.uid()) or private.is_job_party(job_id));

-- job_locations
alter table public.job_locations enable row level security;
grant select on public.job_locations to authenticated;
grant insert (job_id, lat, lng, address_details) on public.job_locations to authenticated;

create policy "job locations: people working the job" on public.job_locations
  for select to authenticated
  using (private.can_see_exact_location(job_id));

create policy "job locations: insert on own job" on public.job_locations
  for insert to authenticated
  with check (
    exists (
      select 1 from public.job_requests j
      where j.id = job_id and j.customer_id = (select auth.uid())
    )
  );

-- job_requests: new columns and wider read access.
grant insert (contractor_id, approx_lat, approx_lng) on public.job_requests to authenticated;

drop policy "jobs: read own, assigned, or open in trade" on public.job_requests;
create policy "jobs: read own, assigned, ordered, or open in trade" on public.job_requests
  for select to authenticated
  using (
    customer_id = (select auth.uid())
    or assigned_worker_id = (select auth.uid())
    or contractor_id = (select auth.uid())
    or private.is_assigned_to_job(id)
    or (
      status = 'active'
      and contractor_id is null
      and trade = (select private.approved_worker_trade())
    )
  );

-- reviews: customers can now review the contractor of a completed order.
grant insert (contractor_id) on public.reviews to authenticated;

drop policy "reviews: customer of completed job" on public.reviews;
create policy "reviews: customer of completed job" on public.reviews
  for insert to authenticated
  with check (
    customer_id = (select auth.uid())
    and exists (
      select 1 from public.job_requests j
      where j.id = job_id
        and j.customer_id = (select auth.uid())
        and j.status = 'completed'
        and (
          (reviews.worker_id is not null and j.assigned_worker_id = reviews.worker_id)
          or (reviews.contractor_id is not null and j.contractor_id = reviews.contractor_id)
        )
    )
  );

-- Live updates for orders, assignments and team invitations.
alter publication supabase_realtime add table public.job_requests;
alter publication supabase_realtime add table public.job_assignments;
alter publication supabase_realtime add table public.contractor_members;
