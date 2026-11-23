-- 07: houses players build (friends can visit)
create table if not exists public.houses(
  uid uuid primary key default auth.uid() references auth.users on delete cascade,
  x int not null, z int not null,
  blocks jsonb not null default '[]'::jsonb check (pg_column_size(blocks) < 30000),
  updated timestamptz not null default now());
alter table public.houses enable row level security;
drop policy if exists h_sel on public.houses; create policy h_sel on public.houses for select to authenticated using (public.is_approved());
drop policy if exists h_ins on public.houses; create policy h_ins on public.houses for insert to authenticated with check (uid = auth.uid() and public.is_approved());
drop policy if exists h_upd on public.houses; create policy h_upd on public.houses for update to authenticated using (uid = auth.uid() and public.is_approved()) with check (uid = auth.uid() and public.is_approved());
grant select on public.houses to authenticated;
grant insert (uid, x, z, blocks, updated) on public.houses to authenticated;
grant update (uid, x, z, blocks, updated) on public.houses to authenticated;
