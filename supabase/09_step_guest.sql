-- =====================================================================
-- Tahap 9: mode tamu. Pengguna yang belum login (peran `anon`) boleh
-- MELIHAT tempat yang sudah disetujui beserta ulasannya. Hanya baca:
-- membuat reservasi, favorit, dan riwayat tetap butuh akun.
-- Jalankan SEKALI di Supabase > SQL Editor.
-- =====================================================================

grant select on public.venues  to anon;
grant select on public.reviews to anon;

drop policy if exists "venue: baca tamu" on public.venues;
create policy "venue: baca tamu"
  on public.venues for select to anon
  using (status = 'disetujui');

drop policy if exists "review: baca tamu" on public.reviews;
create policy "review: baca tamu"
  on public.reviews for select to anon
  using (true);