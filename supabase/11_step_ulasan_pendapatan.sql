-- =====================================================================
-- Tahap 11: (a) pemilik tempat boleh menghapus ulasan di tempatnya sendiri,
--           (b) fungsi pendapatan per tempat untuk admin dan pemilik.
-- Jalankan SEKALI di Supabase > SQL Editor.
-- =====================================================================

-- ---------- (a) Hapus ulasan oleh pemilik tempat ----------
-- Rating & jumlah ulasan tempat dihitung ulang otomatis oleh trigger
-- `reviews_after_change_trg` (sudah ada di tahap 5) saat baris dihapus.
grant delete on public.reviews to authenticated;

drop policy if exists "review: hapus oleh pemilik tempat" on public.reviews;
create policy "review: hapus oleh pemilik tempat"
  on public.reviews for delete to authenticated
  using (
    exists (
      select 1 from public.venues v
      where v.id = reviews.venue_id
        and v.owner_id = auth.uid()
    )
  );

-- ---------- (b) Pendapatan per tempat ----------
-- Hanya pesanan yang sudah dibayar (status 'dikonfirmasi') yang dihitung.
-- Admin melihat SEMUA tempat; pemilik hanya tempat miliknya sendiri.
-- Pembagian 20% admin / 80% pemilik dihitung di aplikasi
-- (lib/config/revenue_config.dart), jadi persentase mudah diubah.
create or replace function public.venue_revenue()
returns table (
  venue_id      uuid,
  venue_name    text,
  owner_name    text,
  booking_count bigint,
  gross         bigint
)
language sql
stable
security definer set search_path = ''
as $$
  select v.id,
         v.name,
         coalesce(nullif(btrim(p.full_name), ''), '-'),
         count(b.id),
         coalesce(sum(b.total_price), 0)::bigint
    from public.venues v
    left join public.profiles p on p.id = v.owner_id
    left join public.bookings b
           on b.court_id = v.id::text
          and b.status = 'dikonfirmasi'
   where public.is_admin() or v.owner_id = auth.uid()
   group by v.id, v.name, p.full_name
   order by coalesce(sum(b.total_price), 0) desc, v.name;
$$;

revoke execute on function public.venue_revenue() from public, anon;
grant  execute on function public.venue_revenue() to authenticated;