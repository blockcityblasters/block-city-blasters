-- 05: weekly leaderboard (approved players only)
create table if not exists public.weekly(
  uid uuid not null default auth.uid() references auth.users on delete cascade,
  wk text not null check (wk ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'),
  xp int not null default 0 check (xp between 0 and 1000000),
  lv int not null default 1 check (lv between 1 and 100000),
  missions int not null default 0 check (missions between 0 and 100000),
  updated timestamptz not null default now(),
  primary key (uid, wk));
alter table public.weekly enable row level security;
drop policy if exists w_sel on public.weekly; create policy w_sel on public.weekly for select to authenticated using (public.is_approved());
drop policy if exists w_ins on public.weekly; create policy w_ins on public.weekly for insert to authenticated with check (uid = auth.uid() and public.is_approved());
drop policy if exists w_upd on public.weekly; create policy w_upd on public.weekly for update to authenticated using (uid = auth.uid() and public.is_approved()) with check (uid = auth.uid() and public.is_approved());
drop policy if exists w_del on public.weekly; create policy w_del on public.weekly for delete to authenticated using (public.is_admin());
grant select, delete on public.weekly to authenticated;
grant insert (uid, wk, xp, lv, missions) on public.weekly to authenticated;
grant update (uid, wk, xp, lv, missions, updated) on public.weekly to authenticated;
