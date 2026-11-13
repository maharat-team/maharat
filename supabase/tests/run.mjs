// Runs the Maharat migrations on PGlite with a minimal Supabase shim, then
// exercises the main flows as real users through RLS.
import { PGlite } from '@electric-sql/pglite';
import fs from 'node:fs';
import path from 'node:path';

const dir = process.argv[2];
const db = new PGlite();

const shim = `
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema auth;
create table auth.users (id uuid primary key, email text);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
create schema storage;
create table storage.buckets (id text primary key, name text, public boolean, file_size_limit bigint, allowed_mime_types text[]);
create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text, name text);
alter table storage.objects enable row level security;
create function storage.foldername(name text) returns text[] language sql as $$ select string_to_array(name, '/') $$;
create publication supabase_realtime;
grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
`;
await db.exec(shim);

const files = fs.readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
for (const f of files) {
  try {
    await db.exec(fs.readFileSync(path.join(dir, f), 'utf8'));
    console.log('OK  ', f);
  } catch (e) {
    console.log('FAIL', f, '\n   ', e.message, e.position ?? '');
    process.exit(1);
  }
}

if (process.argv[3]) {
  const script = await import(path.resolve(process.argv[3]));
  await script.default(db);
}
