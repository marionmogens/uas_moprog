-- 1) Pemilik boleh MEMBACA pesanan di tempat miliknya; admin membaca semua.
drop policy if exists "booking: baca pesanan tempat milik sendiri" on public.bookings;
create policy "booking: baca pesanan tempat milik sendiri"
  on public.bookings for select to authenticated
  using (
    exists (
      select 1 from public.venues v
      where v.id::text = bookings.court_id
        and v.owner_id = auth.uid()
    )
  );

drop policy if exists "booking: admin baca semua" on public.bookings;
create policy "booking: admin baca semua"
  on public.bookings for select to authenticated
  using (public.is_admin());

create index if not exists bookings_court_date_idx
  on public.bookings (court_id, booking_date);

-- 2) Statistik per tempat. Pemilik hanya melihat tempatnya, admin melihat semua.
--    Periode memakai TANGGAL MAIN (booking_date); null = tanpa batas.
create or replace function public.venue_booking_stats(
  p_from date default null,
  p_to   date default null
)
returns table (
  venue_id           uuid,
  venue_name         text,
  category           text,
  city               text,
  status             text,
  total_bookings     bigint,
  cancelled_bookings bigint,
  revenue            bigint
)
language sql
stable
security invoker set search_path = ''
as $$
  select
    v.id,
    v.name,
    v.category,
    v.city,
    v.status,
    count(b.id) filter (where b.status not in ('dibatalkan', 'ditolak')),
    count(b.id) filter (where b.status in ('dibatalkan', 'ditolak')),
    coalesce(sum(b.total_price) filter (where b.status not in ('dibatalkan', 'ditolak')), 0)::bigint
  from public.venues v
  left join public.bookings b
         on b.court_id = v.id::text
        and (p_from is null or b.booking_date >= p_from)
        and (p_to   is null or b.booking_date <= p_to)
  where v.owner_id = auth.uid() or public.is_admin()
  group by v.id, v.name, v.category, v.city, v.status
  order by 8 desc, 6 desc, v.name;
$$;

revoke execute on function public.venue_booking_stats(date, date) from public, anon;
grant  execute on function public.venue_booking_stats(date, date) to authenticated;

-- 3) Ulasan hanya boleh dibuat/diubah kalau jadwal sudah SELESAI
--    (jam akhir = 6 + slot terakhir + 1; zona waktu Asia/Jakarta).
drop policy if exists "review: tulis" on public.reviews;
create policy "review: tulis"
  on public.reviews for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.bookings b
      where b.user_id = auth.uid()
        and b.court_id = venue_id::text
        and b.status not in ('dibatalkan', 'ditolak')
        and b.booking_date::timestamp
            + make_interval(hours => 7 + (select max(s) from unnest(b.slot_indexes) s))
            <= (now() at time zone 'Asia/Jakarta')
    )
  );

drop policy if exists "review: ubah milik sendiri" on public.reviews;
create policy "review: ubah milik sendiri"
  on public.reviews for update to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.bookings b
      where b.user_id = auth.uid()
        and b.court_id = venue_id::text
        and b.status not in ('dibatalkan', 'ditolak')
        and b.booking_date::timestamp
            + make_interval(hours => 7 + (select max(s) from unnest(b.slot_indexes) s))
            <= (now() at time zone 'Asia/Jakarta')
    )
  );