-- =====================================================================
-- Tahap 7: pembayaran langsung sukses (tanpa "menunggu konfirmasi"),
--          pesanan tidak bisa dibatalkan pelanggan.
-- Jalankan SEKALI di Supabase > SQL Editor.
-- =====================================================================

-- 1) Pesanan lama yang masih 'menunggu' dianggap sudah dibayar.
update public.bookings
   set status = 'dikonfirmasi'
 where status = 'menunggu';

-- 2) Pesanan baru langsung 'dikonfirmasi' (ditampilkan "Pembayaran Berhasil").
alter table public.bookings
  alter column status set default 'dikonfirmasi';

drop policy if exists "booking: buat milik sendiri" on public.bookings;
create policy "booking: buat milik sendiri"
  on public.bookings for insert to authenticated
  with check (auth.uid() = user_id and status = 'dikonfirmasi');

-- 3) Pelanggan tidak boleh lagi membatalkan / mengubah status pesanan.
drop policy if exists "booking: batalkan milik sendiri" on public.bookings;
revoke update on public.bookings from authenticated;