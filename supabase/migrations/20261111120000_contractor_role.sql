-- New role for shop owners who run a team of workers.
-- Kept in its own migration: a new enum value cannot be used in the same
-- transaction that adds it.
alter type public.user_role add value if not exists 'contractor';
