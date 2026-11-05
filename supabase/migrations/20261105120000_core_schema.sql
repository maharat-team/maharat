-- Maharat core schema: tables, indexes, integrity triggers.
-- Access control lives in the next migration (RLS + grants).

create schema if not exists private;
grant usage on schema private to authenticated, service_role;

create type public.user_role as enum ('customer', 'worker');
create type public.job_status as enum ('active', 'completed', 'closed');
create type public.job_urgency as enum ('today', 'tomorrow', 'any_day');
create type public.verification_status as enum ('pending', 'approved', 'rejected');

-- Tables ---------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '' check (char_length(full_name) <= 80),
  phone text check (phone ~ '^\+92[0-9]{10}$'),
  language text not null default 'English' check (language in ('English', 'Urdu')),
  active_role public.user_role not null default 'customer',
  neighbourhood text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.workers (
  id uuid primary key references public.profiles (id) on delete cascade,
  full_name text not null,
  trade text not null check (
    trade in ('Electrician', 'Plumber', 'Mason', 'Carpenter', 'Painter', 'AC Technician')
  ),
  phone text not null check (phone ~ '^\+92[0-9]{10}$'),
  bio text not null default '' check (char_length(bio) <= 1000),
  experience_years integer not null default 0 check (experience_years between 0 and 70),
  visit_fee integer not null default 0 check (visit_fee >= 0),
  neighbourhood text not null,
  service_areas text[] not null check (cardinality(service_areas) > 0),
  is_available_today boolean not null default true,
  verification_status public.verification_status not null default 'pending',
  rating_avg numeric(2, 1) not null default 0,
  review_count integer not null default 0,
  completed_jobs_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index workers_directory_idx on public.workers (trade, rating_avg desc)
  where verification_status = 'approved';
create index workers_service_areas_idx on public.workers using gin (service_areas);

create table public.worker_photos (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.workers (id) on delete cascade,
  storage_path text not null unique,
  created_at timestamptz not null default now()
);

create index worker_photos_worker_idx on public.worker_photos (worker_id, created_at desc);

create table public.cnic_verifications (
  worker_id uuid primary key references public.workers (id) on delete cascade,
  cnic_number text not null unique check (cnic_number ~ '^[0-9]{5}-[0-9]{7}-[0-9]$'),
  front_path text not null,
  back_path text not null,
  selfie_path text not null,
  status public.verification_status not null default 'pending',
  rejection_reason text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create table public.job_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  customer_name text not null,
  trade text not null check (
    trade in ('Electrician', 'Plumber', 'Mason', 'Carpenter', 'Painter', 'AC Technician')
  ),
  description text not null check (char_length(description) between 1 and 2000),
  location text not null,
  urgency public.job_urgency not null default 'today',
  status public.job_status not null default 'active',
  photo_paths text[] not null default '{}' check (cardinality(photo_paths) <= 6),
  assigned_worker_id uuid references public.workers (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

create index job_requests_customer_idx on public.job_requests (customer_id, created_at desc);
create index job_requests_open_idx on public.job_requests (trade, location, created_at desc)
  where status = 'active';
create index job_requests_assigned_idx on public.job_requests (assigned_worker_id);

create table public.job_interests (
  job_id uuid not null references public.job_requests (id) on delete cascade,
  worker_id uuid not null references public.workers (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (job_id, worker_id)
);

create index job_interests_worker_idx on public.job_interests (worker_id);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null unique references public.job_requests (id) on delete cascade,
  worker_id uuid not null references public.workers (id) on delete cascade,
  customer_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  customer_name text not null,
  rating numeric(2, 1) not null check (rating between 1 and 5),
  comment text not null default '' check (char_length(comment) <= 1000),
  tags text[] not null default '{}',
  created_at timestamptz not null default now()
);

create index reviews_worker_idx on public.reviews (worker_id, created_at desc);
create index reviews_customer_idx on public.reviews (customer_id);

-- Shared triggers ------------------------------------------------------------

create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_updated_at before update on public.profiles
  for each row execute function private.set_updated_at();
create trigger workers_updated_at before update on public.workers
  for each row execute function private.set_updated_at();
create trigger job_requests_updated_at before update on public.job_requests
  for each row execute function private.set_updated_at();

-- Every auth user gets a profile row.
create function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id) on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function private.handle_new_user();

-- Covers accounts created before this migration ran.
insert into public.profiles (id) select id from auth.users on conflict (id) do nothing;

-- Other users cannot read profiles, so the directory keeps its own copy of the name.
create function private.sync_worker_name()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.workers set full_name = new.full_name where id = new.id;
  return new;
end;
$$;

create trigger profiles_sync_worker_name after update of full_name on public.profiles
  for each row when (old.full_name is distinct from new.full_name)
  execute function private.sync_worker_name();

-- Job integrity --------------------------------------------------------------

create function private.prepare_job_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  owner_name text;
begin
  select full_name into owner_name from public.profiles where id = new.customer_id;
  if coalesce(btrim(owner_name), '') = '' then
    raise exception 'Please complete your profile before posting a job.';
  end if;
  -- A job may only reference the customer's own uploads. Workers get read access
  -- to photo_paths, so a foreign path here would leak someone else's file.
  if exists (
    select 1 from unnest(new.photo_paths) as path
    where path not like new.customer_id::text || '/%'
  ) then
    raise exception 'Invalid photo attachment.';
  end if;
  new.customer_name := owner_name;
  return new;
end;
$$;

create trigger job_requests_prepare before insert on public.job_requests
  for each row execute function private.prepare_job_request();

-- Clients may only move a job out of 'active'. Completing it requires naming a
-- worker who actually responded, which is what makes a later review legitimate.
create function private.guard_job_update()
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
    if new.assigned_worker_id is null or not exists (
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

create trigger job_requests_guard before update on public.job_requests
  for each row execute function private.guard_job_update();

create function private.count_completed_job()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.workers
  set completed_jobs_count = completed_jobs_count + 1
  where id = new.assigned_worker_id;
  return new;
end;
$$;

create trigger job_requests_count_completed after update of status on public.job_requests
  for each row when (old.status <> 'completed' and new.status = 'completed')
  execute function private.count_completed_job();

-- Reviews --------------------------------------------------------------------

create function private.prepare_review()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  select full_name into new.customer_name from public.profiles where id = new.customer_id;
  return new;
end;
$$;

create trigger reviews_prepare before insert on public.reviews
  for each row execute function private.prepare_review();

create function private.refresh_worker_rating()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target uuid := coalesce(new.worker_id, old.worker_id);
begin
  update public.workers w
  set rating_avg = coalesce(s.average, 0), review_count = s.total
  from (
    select round(avg(rating), 1) as average, count(*)::integer as total
    from public.reviews where worker_id = target
  ) s
  where w.id = target;
  return null;
end;
$$;

create trigger reviews_refresh_rating after insert or delete on public.reviews
  for each row execute function private.refresh_worker_rating();

-- Work photos ----------------------------------------------------------------

create function private.guard_worker_photo()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.storage_path not like new.worker_id::text || '/%' then
    raise exception 'Invalid photo path.';
  end if;
  if (select count(*) from public.worker_photos where worker_id = new.worker_id) >= 12 then
    raise exception 'You can add up to 12 work photos. Remove one to add another.';
  end if;
  return new;
end;
$$;

create trigger worker_photos_guard before insert on public.worker_photos
  for each row execute function private.guard_worker_photo();

-- CNIC verification ----------------------------------------------------------

-- Approve or reject from the dashboard SQL editor:
--   update public.cnic_verifications set status = 'approved' where worker_id = '...';
create function private.apply_verification_decision()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status <> 'pending' then
    new.reviewed_at := now();
  end if;
  update public.workers set verification_status = new.status where id = new.worker_id;
  return new;
end;
$$;

create trigger cnic_apply_decision before update of status on public.cnic_verifications
  for each row when (old.status is distinct from new.status)
  execute function private.apply_verification_decision();

-- Registration is one call so a worker can never exist without their CNIC record.
-- This is the only client write path to cnic_verifications and verification state.
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
  p_selfie_path text
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

  select status into current_status from public.cnic_verifications where worker_id = uid;
  if current_status in ('pending', 'approved') then
    raise exception 'Your application has already been submitted.';
  end if;

  if exists (
    select 1 from public.cnic_verifications
    where cnic_number = p_cnic_number and worker_id <> uid
  ) then
    raise exception 'This CNIC is already registered.';
  end if;

  insert into public.workers (
    id, full_name, trade, phone, bio, experience_years, visit_fee, neighbourhood, service_areas
  ) values (
    uid, owner_name, p_trade, p_phone, p_bio, p_experience_years, p_visit_fee,
    p_service_areas[1], p_service_areas
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    trade = excluded.trade,
    phone = excluded.phone,
    bio = excluded.bio,
    experience_years = excluded.experience_years,
    visit_fee = excluded.visit_fee,
    neighbourhood = excluded.neighbourhood,
    service_areas = excluded.service_areas;

  insert into public.cnic_verifications (
    worker_id, cnic_number, front_path, back_path, selfie_path
  ) values (
    uid, p_cnic_number, p_front_path, p_back_path, p_selfie_path
  )
  on conflict (worker_id) do update set
    cnic_number = excluded.cnic_number,
    front_path = excluded.front_path,
    back_path = excluded.back_path,
    selfie_path = excluded.selfie_path,
    status = 'pending',
    rejection_reason = null,
    submitted_at = now(),
    reviewed_at = null;

  update public.profiles set active_role = 'worker' where id = uid;
end;
$$;
