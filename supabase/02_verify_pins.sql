-- 02: request numbers, device info, grown-up name, picture passwords
create extension if not exists pgcrypto with schema extensions;
alter table public.players add column if not exists req_no int not null default floor(random()*9000+1000)::int;
alter table public.players add column if not exists device text check (char_length(device) <= 40);
alter table public.players add column if not exists grownup text check (char_length(grownup) <= 30);
alter table public.players add column if not exists pin_hash text;
alter table public.players add column if not exists has_pin boolean not null default false;
alter table public.players add column if not exists fails int not null default 0;
alter table public.players add column if not exists locked_until timestamptz;

-- players can only read/write safe columns (never the password hash)
revoke select, insert, update on public.players from authenticated;
grant select (id, nick, pic, status, created_at, req_no, device, grownup, has_pin) on public.players to authenticated;
grant insert (id, nick, pic, device, grownup) on public.players to authenticated;
grant update (nick, status) on public.players to authenticated;

create or replace function public.set_pin(pid uuid, pin text) returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  if pin is null or pin !~ '^[0-9]{4}$' then raise exception 'bad pin'; end if;
  update public.players set pin_hash = crypt(pin, gen_salt('bf')), has_pin = true, fails = 0, locked_until = null where id = pid;
end $$;

create or replace function public.claim(p_nick text, p_pin text) returns text language plpgsql security definer set search_path = public, extensions as $$
declare me uuid := auth.uid(); r record; any_locked boolean := false;
begin
  if me is null then return 'no'; end if;
  for r in select * from public.players where lower(nick) = lower(trim(p_nick)) and status = 'approved' and pin_hash is not null loop
    if r.locked_until is not null and r.locked_until > now() then any_locked := true; continue; end if;
    if r.pin_hash = crypt(p_pin, r.pin_hash) then
      if r.id = me then return 'ok'; end if;
      delete from public.players where id = me;
      insert into public.players(id, nick, pic, status, req_no, device, grownup, pin_hash, has_pin)
        values (me, r.nick, r.pic, 'approved', r.req_no, r.device, r.grownup, r.pin_hash, true);
      delete from public.players where id = r.id;
      return 'ok';
    else
      update public.players set fails = case when fails + 1 >= 5 then 0 else fails + 1 end,
        locked_until = case when fails + 1 >= 5 then now() + interval '15 minutes' else locked_until end where id = r.id;
    end if;
  end loop;
  return case when any_locked then 'locked' else 'wrong' end;
end $$;
revoke execute on function public.set_pin(uuid, text) from public, anon;
revoke execute on function public.claim(text, text) from public, anon;
grant execute on function public.set_pin(uuid, text) to authenticated;
grant execute on function public.claim(text, text) to authenticated;
