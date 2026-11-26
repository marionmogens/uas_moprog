-- Pembatalan: paling lambat H-1, refund 50% dari total bayar.
alter table public.bookings
  add column if not exists refund_amount int not null default 0;

drop function if exists public.cancel_booking(uuid);

create or replace function public.cancel_booking(p_id uuid)
returns int
language plpgsql
security definer set search_path = ''
as $$
declare
  v_date   date;
  v_total  int;
  v_status text;
  v_refund int;
begin
  select b.booking_date, b.total_price, b.status
    into v_date, v_total, v_status
    from public.bookings b
   where b.id = p_id and b.user_id = auth.uid();

  if not found then
    raise exception 'BOOKING_NOT_FOUND';
  end if;

  if v_status not in ('menunggu', 'dikonfirmasi') then
    raise exception 'CANNOT_CANCEL';
  end if;

  -- Harus H-1 atau lebih awal: tanggal hari ini (WIB) harus < tanggal booking.
  if (now() at time zone 'Asia/Jakarta')::date >= v_date then
    raise exception 'TOO_LATE';
  end if;

  v_refund := floor(v_total * 0.5);

  update public.bookings
     set status = 'dibatalkan',
         refund_amount = v_refund
   where id = p_id;

  return v_refund;
end;
$$;

revoke execute on function public.cancel_booking(uuid) from public, anon;
grant  execute on function public.cancel_booking(uuid) to authenticated;