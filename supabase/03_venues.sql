-- =====================================================================
-- TAHAP 4A-1: tempat (Lapangan & Kelas), peran admin, aturan persetujuan
-- =====================================================================

alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('pelanggan', 'pemilik', 'admin'));

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name, phone, role)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    'pelanggan'
  );
  return new;
end;
$$;

-- Akun uji yang dulu mendaftar sebagai 'pemilik' dikembalikan jadi pelanggan.
update public.profiles set role = 'pelanggan' where role = 'pemilik';

-- Data uji reservasi lama (id tempat contoh p1..k2) dibersihkan.
delete from public.bookings
where court_id in ('p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'k1', 'k2');

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

revoke execute on function public.is_admin() from public, anon;
grant  execute on function public.is_admin() to authenticated;

drop policy if exists "profil: admin baca semua" on public.profiles;
create policy "profil: admin baca semua"
  on public.profiles for select to authenticated
  using (public.is_admin());

create table if not exists public.venues (
  id                 uuid primary key default gen_random_uuid(),
  owner_id           uuid not null default auth.uid()
                     references public.profiles (id) on delete cascade,
  category           text not null default 'Lapangan'
                     check (category in ('Lapangan', 'Kelas')),
  name               text not null check (char_length(btrim(name)) > 0),
  city               text not null default '',
  address            text not null default '',
  maps_url           text not null default '',
  whatsapp           text not null default '',
  is_indoor          boolean not null default true,
  field_count        int  not null default 1 check (field_count between 1 and 10),
  price_per_hour     int  not null check (price_per_hour > 0),
  open_hour          int  not null default 6  check (open_hour between 6 and 22),
  close_hour         int  not null default 22 check (close_hour between 7 and 23),
  facilities         text[] not null default '{}',
  description        text not null default '',
  image_url          text not null default '',
  class_start_slots  int[]  not null default '{}',
  accepting_bookings boolean not null default true,
  status             text not null default 'menunggu'
                     check (status in ('menunggu', 'disetujui', 'ditolak', 'ditangguhkan')),
  reject_reason      text not null default '',
  reviewed_by        uuid references public.profiles (id) on delete set null,
  reviewed_at        timestamptz,
  created_at         timestamptz not null default now(),
  constraint venues_hours_check check (close_hour > open_hour),
  constraint venues_class_slots_check check (
    class_start_slots <@ array[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
    and (category <> 'Kelas' or cardinality(class_start_slots) > 0)
  )
);

create index if not exists venues_status_idx on public.venues (status, category);
create index if not exists venues_owner_idx  on public.venues (owner_id);

alter table public.venues enable row level security;

revoke all on public.venues from anon, authenticated;
grant select on public.venues to authenticated;

grant insert (category, name, city, address, maps_url, whatsapp, is_indoor,
              field_count, price_per_hour, open_hour, close_hour, facilities,
              description, image_url, class_start_slots, accepting_bookings)
  on public.venues to authenticated;
grant update (category, name, city, address, maps_url, whatsapp, is_indoor,
              field_count, price_per_hour, open_hour, close_hour, facilities,
              description, image_url, class_start_slots, accepting_bookings)
  on public.venues to authenticated;

drop policy if exists "venue: baca" on public.venues;
create policy "venue: baca"
  on public.venues for select to authenticated
  using (status = 'disetujui' or owner_id = auth.uid() or public.is_admin());

drop policy if exists "venue: ajukan" on public.venues;
create policy "venue: ajukan"
  on public.venues for insert to authenticated
  with check (owner_id = auth.uid() and status = 'menunggu');

drop policy if exists "venue: ubah milik sendiri" on public.venues;
create policy "venue: ubah milik sendiri"
  on public.venues for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create or replace function public.review_venue(
  p_id       uuid,
  p_decision text,
  p_reason   text default ''
)
returns void
language plpgsql
security definer set search_path = ''
as $$
declare
  v_owner uuid;
begin
  if not public.is_admin() then
    raise exception 'NOT_ADMIN';
  end if;
  if p_decision not in ('disetujui', 'ditolak', 'ditangguhkan') then
    raise exception 'INVALID_DECISION';
  end if;
  if p_decision in ('ditolak', 'ditangguhkan')
     and btrim(coalesce(p_reason, '')) = '' then
    raise exception 'REASON_REQUIRED';
  end if;

  update public.venues
     set status        = p_decision,
         reject_reason = case when p_decision = 'disetujui' then ''
                              else btrim(p_reason) end,
         reviewed_by   = auth.uid(),
         reviewed_at   = now()
   where id = p_id
   returning owner_id into v_owner;

  if v_owner is null then
    raise exception 'VENUE_NOT_FOUND';
  end if;

  if p_decision = 'disetujui' then
    update public.profiles set role = 'pemilik'
     where id = v_owner and role = 'pelanggan';
  end if;
end;
$$;

revoke execute on function public.review_venue(uuid, text, text) from public, anon;
grant  execute on function public.review_venue(uuid, text, text) to authenticated;

create or replace function public.resubmit_venue(p_id uuid)
returns void
language plpgsql
security definer set search_path = ''
as $$
begin
  update public.venues
     set status = 'menunggu', reject_reason = ''
   where id = p_id and owner_id = auth.uid() and status = 'ditolak';

  if not found then
    raise exception 'CANNOT_RESUBMIT';
  end if;
end;
$$;

revoke execute on function public.resubmit_venue(uuid) from public, anon;
grant  execute on function public.resubmit_venue(uuid) to authenticated;