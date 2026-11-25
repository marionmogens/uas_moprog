-- Tolak pesanan baru jika tempat sedang tidak menerima pesanan
-- atau belum/tidak lagi berstatus disetujui.
create or replace function public.check_venue_accepting()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.venues v
    where v.id::text = new.court_id
      and (v.accepting_bookings = false or v.status <> 'disetujui')
  ) then
    raise exception 'VENUE_CLOSED';
  end if;
  return new;
end;
$$;

drop trigger if exists booking_venue_open_check on public.bookings;
create trigger booking_venue_open_check
  before insert on public.bookings
  for each row execute function public.check_venue_accepting();