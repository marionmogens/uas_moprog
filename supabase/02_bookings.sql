create table if not exists public.bookings (
  id             uuid primary key default gen_random_uuid(),
  booking_code   text not null,
  user_id        uuid not null default auth.uid()
                 references auth.users (id) on delete cascade,
  court_id       text not null,
  court_name     text not null,
  field_name     text not null,
  booking_date   date not null,
  slot_indexes   int[] not null,
  time_slot      text not null,
  duration       text not null default '',
  court_price    int  not null default 0,
  addons         jsonb not null default '[]'::jsonb,
  note           text not null default '',
  total_price    int  not null,
  customer_name  text not null default '',
  customer_phone text not null default '',
  payment_method text not null default '',
  status         text not null default 'menunggu'
                 check (status in ('menunggu', 'dikonfirmasi', 'ditolak', 'dibatalkan')),
  created_at     timestamptz not null default now()
);

create index if not exists bookings_slot_lookup_idx
  on public.bookings (court_id, field_name, booking_date);
create index if not exists bookings_user_idx
  on public.bookings (user_id, created_at desc);

alter table public.bookings enable row level security;

grant select on public.profiles to authenticated;

revoke all on public.bookings from anon, authenticated;
grant select, insert on public.bookings to authenticated;
grant update (status) on public.bookings to authenticated;

drop policy if exists "booking: baca milik sendiri" on public.bookings;
create policy "booking: baca milik sendiri"
  on public.bookings for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "booking: buat milik sendiri" on public.bookings;
create policy "booking: buat milik sendiri"
  on public.bookings for insert to authenticated
  with check (auth.uid() = user_id and status = 'menunggu');

drop policy if exists "booking: batalkan milik sendiri" on public.bookings;
create policy "booking: batalkan milik sendiri"
  on public.bookings for update to authenticated
  using (auth.uid() = user_id and status in ('menunggu', 'dikonfirmasi'))
  with check (auth.uid() = user_id and status = 'dibatalkan');

create or replace function public.check_booking_overlap()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  perform pg_advisory_xact_lock(
    hashtext(new.court_id || '|' || new.field_name || '|' || new.booking_date::text)
  );

  if exists (
    select 1
    from public.bookings b
    where b.court_id     = new.court_id
      and b.field_name   = new.field_name
      and b.booking_date = new.booking_date
      and b.status in ('menunggu', 'dikonfirmasi')
      and b.slot_indexes && new.slot_indexes
  ) then
    raise exception 'SLOT_TAKEN';
  end if;

  return new;
end;
$$;

drop trigger if exists booking_overlap_check on public.bookings;
create trigger booking_overlap_check
  before insert on public.bookings
  for each row execute function public.check_booking_overlap();

create or replace function public.get_taken_slots(
  p_court_id text,
  p_field    text,
  p_date     date
)
returns table (slot_index int)
language sql
stable
security definer set search_path = ''
as $$
  select distinct unnest(b.slot_indexes) as slot_index
  from public.bookings b
  where b.court_id     = p_court_id
    and b.field_name   = p_field
    and b.booking_date = p_date
    and b.status in ('menunggu', 'dikonfirmasi');
$$;

revoke execute on function public.get_taken_slots(text, text, date) from public, anon;
grant  execute on function public.get_taken_slots(text, text, date) to authenticated;