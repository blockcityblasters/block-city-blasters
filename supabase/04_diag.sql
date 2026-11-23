-- 04: small problem reports from devices (only approved players can send; only the grown-up admin can read)
create table if not exists public.diag(id bigserial primary key, uid uuid default auth.uid(), at timestamptz not null default now(), info jsonb not null check (pg_column_size(info) < 8000));
alter table public.diag enable row level security;
drop policy if exists d_ins on public.diag; create policy d_ins on public.diag for insert to authenticated with check (public.is_approved() and uid = auth.uid());
drop policy if exists d_sel on public.diag; create policy d_sel on public.diag for select to authenticated using (public.is_admin());
grant insert (info) on public.diag to authenticated;
grant select on public.diag to authenticated;
grant usage on sequence public.diag_id_seq to authenticated;
