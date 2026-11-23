-- Block City Blasters: family-only players, approved by a grown-up
create table if not exists public.players(
  id uuid primary key references auth.users on delete cascade,
  nick text not null check (char_length(nick) between 1 and 16),
  pic text not null default '🦖' check (char_length(pic) <= 8),
  status text not null default 'pending' check (status in ('pending','approved','denied')),
  created_at timestamptz not null default now());
create table if not exists public.admins(id uuid primary key references auth.users on delete cascade);
create table if not exists public.settings(id int primary key default 1 check (id=1), chat boolean not null default true);
insert into public.settings(id) values (1) on conflict do nothing;

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as
$$ select exists(select 1 from public.admins where id = auth.uid()) $$;
create or replace function public.is_approved() returns boolean language sql stable security definer set search_path=public as
$$ select public.is_admin() or exists(select 1 from public.players where id = auth.uid() and status = 'approved') $$;

alter table public.players enable row level security;
alter table public.admins enable row level security;
alter table public.settings enable row level security;

drop policy if exists p_sel on public.players;   create policy p_sel on public.players for select to authenticated using (id = auth.uid() or public.is_admin() or (status = 'approved' and public.is_approved()));
drop policy if exists p_ins on public.players;   create policy p_ins on public.players for insert to authenticated with check (id = auth.uid() and status = 'pending');
drop policy if exists p_upd on public.players;   create policy p_upd on public.players for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists p_del on public.players;   create policy p_del on public.players for delete to authenticated using (public.is_admin());
drop policy if exists a_sel on public.admins;    create policy a_sel on public.admins for select to authenticated using (id = auth.uid());
drop policy if exists s_sel on public.settings;  create policy s_sel on public.settings for select to authenticated using (public.is_approved());
drop policy if exists s_upd on public.settings;  create policy s_upd on public.settings for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- only approved players can see or send live game messages (private channel "bcb-family")
drop policy if exists bcb_rt_read on realtime.messages;
create policy bcb_rt_read on realtime.messages for select to authenticated using (realtime.topic() = 'bcb-family' and public.is_approved());
drop policy if exists bcb_rt_write on realtime.messages;
create policy bcb_rt_write on realtime.messages for insert to authenticated with check (realtime.topic() = 'bcb-family' and public.is_approved());
