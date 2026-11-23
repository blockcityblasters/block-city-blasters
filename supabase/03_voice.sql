-- 03: live voice switches (grown-up controls)
alter table public.players add column if not exists voice boolean not null default true;
alter table public.settings add column if not exists voice boolean not null default true;
grant select (voice) on public.players to authenticated;
grant update (voice) on public.players to authenticated;
