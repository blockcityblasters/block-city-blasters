-- 06: cloud saves (progress + settings) for approved players
create table if not exists public.saves(
  uid uuid primary key default auth.uid() references auth.users on delete cascade,
  data jsonb not null check (pg_column_size(data) < 60000),
  updated timestamptz not null default now());
alter table public.saves enable row level security;
drop policy if exists sv_sel on public.saves; create policy sv_sel on public.saves for select to authenticated using (uid = auth.uid() or public.is_admin());
drop policy if exists sv_ins on public.saves; create policy sv_ins on public.saves for insert to authenticated with check (uid = auth.uid() and public.is_approved());
drop policy if exists sv_upd on public.saves; create policy sv_upd on public.saves for update to authenticated using (uid = auth.uid() and public.is_approved()) with check (uid = auth.uid() and public.is_approved());
grant select on public.saves to authenticated;
grant insert (uid, data, updated) on public.saves to authenticated;
grant update (uid, data, updated) on public.saves to authenticated;

-- moving to a new device with the picture password also moves the saved game
create or replace function public.claim(p_nick text, p_pin text) returns text language plpgsql security definer set search_path = public, extensions as $$
declare me uuid := auth.uid(); r record; any_locked boolean := false;
begin
  if me is null then return 'no'; end if;
  for r in select * from public.players where lower(nick) = lower(trim(p_nick)) and status = 'approved' and pin_hash is not null loop
    if r.locked_until is not null and r.locked_until > now() then any_locked := true; continue; end if;
    if r.pin_hash = crypt(p_pin, r.pin_hash) then
      if r.id = me then return 'ok'; end if;
      delete from public.players where id = me;
      insert into public.players(id, nick, pic, status, req_no, device, grownup, pin_hash, has_pin, voice)
        values (me, r.nick, r.pic, 'approved', r.req_no, r.device, r.grownup, r.pin_hash, true, r.voice);
      delete from public.saves where uid = me;
      update public.saves set uid = me where uid = r.id;
      update public.weekly set uid = me where uid = r.id;
      delete from public.players where id = r.id;
      return 'ok';
    else
      update public.players set fails = case when fails + 1 >= 5 then 0 else fails + 1 end,
        locked_until = case when fails + 1 >= 5 then now() + interval '15 minutes' else locked_until end where id = r.id;
    end if;
  end loop;
  return case when any_locked then 'locked' else 'wrong' end;
end $$;
revoke execute on function public.claim(text, text) from public, anon;
grant execute on function public.claim(text, text) to authenticated;
