-- make the grown-up login an admin (run after creating that user)
insert into public.admins(id) select id from auth.users where email = 'blockcityblasters@gmail.com' on conflict do nothing;
