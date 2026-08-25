-- ADIT INVITATION PRO - SUPABASE SETUP
-- Jalankan seluruh file ini di Supabase Dashboard > SQL Editor > New query > Run.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default 'User',
  email text not null default '',
  role text not null default 'user' check (role in ('user','admin')),
  plan text not null default 'Pro' check (plan in ('Basic','Pro','Premium')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.invitations (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  owner_email text not null default '',
  owner_name text not null default '',
  slug text not null unique,
  project_name text not null default 'Undangan Pernikahan',
  plan text not null default 'Pro',
  published boolean not null default false,
  active boolean not null default true,
  active_until date,
  visit_count bigint not null default 0,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists invitations_owner_id_idx on public.invitations(owner_id);
create index if not exists invitations_slug_idx on public.invitations(slug);

create table if not exists public.rsvps (
  id uuid primary key default gen_random_uuid(),
  invitation_id uuid not null references public.invitations(id) on delete cascade,
  name text not null default 'Tamu',
  status text not null check (status in ('yes','no')),
  pax integer not null default 1 check (pax >= 1 and pax <= 50),
  created_at timestamptz not null default now()
);

create table if not exists public.guestbook (
  id uuid primary key default gen_random_uuid(),
  invitation_id uuid not null references public.invitations(id) on delete cascade,
  name text not null default 'Tamu',
  message text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.visits (
  id uuid primary key default gen_random_uuid(),
  invitation_id uuid not null references public.invitations(id) on delete cascade,
  guest text not null default '',
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, email, role, plan, active)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(coalesce(new.email,''),'@',1), 'User'),
    coalesce(new.email,''),
    'user', 'Pro', true
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists(
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and active = true
  );
$$;

create or replace function public.increment_invitation_visit(p_invitation_id uuid, p_guest text default '')
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not exists (
    select 1 from public.invitations
    where id = p_invitation_id
      and published = true
      and active = true
      and (active_until is null or active_until >= current_date)
  ) then
    raise exception 'Invitation is not public';
  end if;
  insert into public.visits(invitation_id, guest) values (p_invitation_id, coalesce(p_guest,''));
  update public.invitations set visit_count = visit_count + 1 where id = p_invitation_id;
end;
$$;

grant execute on function public.increment_invitation_visit(uuid,text) to anon, authenticated;

alter table public.profiles enable row level security;
alter table public.invitations enable row level security;
alter table public.rsvps enable row level security;
alter table public.guestbook enable row level security;
alter table public.visits enable row level security;

-- PROFILES
create policy "profile read own or admin" on public.profiles
for select using (id = auth.uid() or public.is_admin());
create policy "profile admin update" on public.profiles
for update using (public.is_admin()) with check (public.is_admin());
create policy "profile own insert as user" on public.profiles
for insert to authenticated with check (id = auth.uid() and role = 'user');

-- INVITATIONS
create policy "invitation owner or admin read" on public.invitations
for select to authenticated using (owner_id = auth.uid() or public.is_admin() or (published and active and (active_until is null or active_until >= current_date)));
create policy "invitation public read" on public.invitations
for select to anon using (published and active and (active_until is null or active_until >= current_date));
create policy "invitation owner insert" on public.invitations
for insert to authenticated with check (owner_id = auth.uid() or public.is_admin());
create policy "invitation owner update" on public.invitations
for update to authenticated using (owner_id = auth.uid() or public.is_admin()) with check (owner_id = auth.uid() or public.is_admin());
create policy "invitation owner delete" on public.invitations
for delete to authenticated using (owner_id = auth.uid() or public.is_admin());

-- RSVP / GUESTBOOK: publik boleh mengirim hanya ke undangan yang aktif
create policy "public rsvp insert" on public.rsvps
for insert to anon, authenticated with check (exists(select 1 from public.invitations i where i.id=invitation_id and i.published and i.active and (i.active_until is null or i.active_until >= current_date)));
create policy "owner rsvp read" on public.rsvps
for select to authenticated using (exists(select 1 from public.invitations i where i.id=invitation_id and (i.owner_id=auth.uid() or public.is_admin())));

create policy "public guestbook insert" on public.guestbook
for insert to anon, authenticated with check (exists(select 1 from public.invitations i where i.id=invitation_id and i.published and i.active and (i.active_until is null or i.active_until >= current_date)));
create policy "guestbook public or owner read" on public.guestbook
for select to anon, authenticated using (exists(select 1 from public.invitations i where i.id=invitation_id and ((i.published and i.active and (i.active_until is null or i.active_until >= current_date)) or (auth.uid() is not null and (i.owner_id=auth.uid() or public.is_admin())))));

create policy "owner visits read" on public.visits
for select to authenticated using (exists(select 1 from public.invitations i where i.id=invitation_id and (i.owner_id=auth.uid() or public.is_admin())));

-- DATA API GRANTS (RLS tetap menentukan baris yang boleh diakses)
revoke all on table public.profiles, public.invitations, public.rsvps, public.guestbook, public.visits from anon, authenticated;
grant select on table public.invitations, public.guestbook to anon;
grant insert on table public.rsvps, public.guestbook to anon;
grant select, insert, update, delete on table public.profiles, public.invitations, public.rsvps, public.guestbook, public.visits to authenticated;

-- STORAGE
insert into storage.buckets (id, name, public, file_size_limit)
values ('invitation-media','invitation-media',true,52428800)
on conflict (id) do update set public=true;

drop policy if exists "public invitation media read" on storage.objects;
create policy "public invitation media read" on storage.objects
for select using (bucket_id = 'invitation-media');
drop policy if exists "user upload own invitation media" on storage.objects;
create policy "user upload own invitation media" on storage.objects
for insert to authenticated with check (
  bucket_id='invitation-media' and (storage.foldername(name))[1] = auth.uid()::text
);
drop policy if exists "user update own invitation media" on storage.objects;
create policy "user update own invitation media" on storage.objects
for update to authenticated using (
  bucket_id='invitation-media' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
);
drop policy if exists "user delete own invitation media" on storage.objects;
create policy "user delete own invitation media" on storage.objects
for delete to authenticated using (
  bucket_id='invitation-media' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
);

-- Realtime untuk RSVP dan buku tamu.
do $$ begin
  alter publication supabase_realtime add table public.rsvps;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.guestbook;
exception when duplicate_object then null; end $$;
