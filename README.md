# PadelBook

Aplikasi mobile (Flutter) untuk memesan **lapangan dan kelas padel**, lengkap dengan
fitur **Kompetisi** untuk menghitung poin turnamen dan melihat leaderboard secara
real-time. Backend memakai **Supabase** (Auth + PostgREST + Row Level Security).

> Project UAS Mobile Programming.

---

## Daftar Isi

- [Fitur](#fitur)
- [Peran Pengguna](#peran-pengguna)
- [Fitur Kompetisi](#fitur-kompetisi)
- [Teknologi](#teknologi)
- [Struktur Folder](#struktur-folder)
- [Menjalankan Project](#menjalankan-project)
- [Setup Supabase](#setup-supabase)
- [Aturan Bisnis](#aturan-bisnis)
- [Catatan](#catatan)

---

## Fitur

### Pelanggan
- Daftar akun dengan **verifikasi email (kode OTP)**, masuk, dan lupa kata sandi.
- **Mode tamu**: melihat lapangan, kelas, dan ulasan tanpa akun.
- Cari lapangan/kelas: kategori, kata kunci, dan filter lanjutan
  (kota, budget per jam, jarak, indoor/outdoor, urutan).
- **Dekat saya**: urut berdasarkan jarak memakai GPS perangkat.
- Detail tempat: foto, deskripsi, fasilitas, rating, dan ulasan.
- **Favorit** (tekan ikon hati atau ketuk dua kali kartu), tersimpan di perangkat.
- Pilih durasi, add-on (sewa raket, bola, handuk & air, coach), dan jadwal
  30 hari ke depan.
- Ringkasan pesanan, pembayaran (simulasi), dan **riwayat pesanan** dengan kode booking.
- **Batalkan reservasi** (paling lambat H-1, refund 50%) dan **beri ulasan**.
- **Buku panduan** di dalam aplikasi, bisa diunduh sebagai PDF.

### Pemilik Tempat
- Ajukan lapangan/kelas dari tab Akun; akun pelanggan otomatis menjadi pemilik
  setelah pengajuan pertama disetujui admin.
- Kelola tempat: ubah data, ajukan ulang jika ditolak, sakelar *Menerima pesanan*.
- Lihat pesanan di tempat miliknya, rating, dan ulasan (bisa menghapus ulasan
  yang tidak pantas di tempat sendiri).
- Ringkasan **pendapatan** total dan bersih per tempat.

### Admin
- Tinjau pengajuan tempat (setujui atau tolak dengan alasan).
- Kelola semua tempat, pesanan, dan ulasan.
- Laporan **pendapatan** platform per tempat.

### Kompetisi
Hitung poin turnamen padel dengan format **Americano**, **Mexicano**, dan
**Knockout**. Detail lengkap ada di bagian [Fitur Kompetisi](#fitur-kompetisi).

---

## Peran Pengguna

| Peran | Cara mendapatkan | Akses utama |
|---|---|---|
| Tamu | Tombol *Masuk sebagai Tamu* | Hanya melihat tempat dan ulasan |
| Pelanggan | Daftar + verifikasi email | Pesan, favorit, riwayat, ulasan, kompetisi |
| Pemilik | Pengajuan tempat disetujui admin | Kelola tempat, pesanan, ulasan, pendapatan |
| Admin | Diatur di tabel `profiles` | Persetujuan, pesanan, ulasan, pendapatan |

Setelah login, `role_router.dart` mengarahkan admin ke `AdminHomePage` dan
selain itu ke `HomePage`.

---

## Fitur Kompetisi

Dibuka lewat **tombol bulat pink di tengah menu bawah** (tamu diminta masuk dulu).
Turnamen disimpan di **Supabase** (tabel `tournaments`), jadi ikut akun dan bisa
dibuka dari perangkat lain. Salinan lokal dipakai sebagai cache, sehingga tetap
bisa dipakai saat offline dan disinkronkan otomatis begitu terhubung lagi.

### Alur
1. **Pilih format** → 2. **Beri nama turnamen** → 3. **Isi pemain/tim dan pengaturan**
   → jadwal dibuat otomatis → isi skor tiap pertandingan.

### Format

| Format | Cara kerja |
|---|---|
| **Classic Americano** | Pasangan berganti tiap ronde, tiap pemain mengumpulkan poin sendiri. Jadwal dibuat otomatis supaya jumlah main, pasangan, dan lawan merata. |
| **Classic Mexicano** | Ronde 1 diacak. Ronde berikutnya dibentuk dari peringkat terbaru (peringkat 1 + 4 melawan 2 + 3 dalam tiap kelompok 4 pemain). Ronde baru muncul setelah semua skor ronde sebelumnya terisi. |
| **Knockout** | Sistem gugur antar tim tetap (2 pemain per tim). Mendukung undian acak atau berdasarkan urutan input (seed), *bye* untuk jumlah tim non-pangkat-2, dan perebutan juara 3. |

### Aturan skor
Tim yang **lebih dulu mencapai poin kemenangan** (7, 11, 15, 21, atau 25) menang.
Di lembar skor, ketuk tim pemenang lalu atur skor tim lawan (0 sampai target − 1).
Tidak ada seri.

### Pengaturan Americano & Mexicano
- Minimal 4 pemain (maksimal 24).
- Jumlah lapangan dan jumlah ronde diketik langsung; ronde disarankan otomatis
  agar semua pemain main sama banyak, dan aplikasi memberi tahu bila belum rata.
- Peringkat berdasarkan **total poin** atau **kemenangan**; seri diselesaikan
  dengan selisih poin lalu nama.

### Leaderboard & statistik
- Leaderboard (P, W-T-L, selisih poin) dihitung ulang setiap skor disimpan.
- Tab **Statistik**: grafik performa (poin atau peringkat tiap ronde), rentetan
  menang, kemenangan terbesar, dan sorotan pemain (rata-rata poin, partner
  terbaik, lawan tersulit).

### Mengakhiri turnamen
Setelah semua pertandingan selesai, ketuk **Akhiri Turnamen**. Untuk Knockout,
dialog juara tampil lebih dulu, lalu aplikasi kembali ke daftar Kompetisi.
Turnamen bisa dibuka kembali lewat menu titik tiga.

---

## Teknologi

| Bagian | Teknologi |
|---|---|
| Framework | Flutter (Dart `^3.13.0`) |
| Backend | Supabase: Auth, REST (PostgREST), Row Level Security, fungsi SQL |
| HTTP | `http` (tanpa SDK Supabase, lewat `api_client.dart`) |
| Penyimpanan lokal | `shared_preferences` (sesi, favorit, cache turnamen) |
| Lokasi | `geolocator` |
| PDF | `pdf` + `printing` (buku panduan) |

---

## Struktur Folder

```
lib/
├── main.dart
├── config/
│   ├── supabase_config.dart       # URL & publishable key Supabase
│   └── revenue_config.dart        # persentase komisi platform
├── models/                        # padel_court, booking, review, venue_filter,
│                                  # tournament, app_user, auth_session, ...
├── services/
│   ├── api_client.dart            # pembungkus HTTP + penanganan error
│   ├── auth_service.dart          # login, daftar, OTP, mode tamu
│   ├── venue_service.dart         # tempat (lapangan & kelas)
│   ├── booking_service.dart       # reservasi, pembatalan
│   ├── review_service.dart        # ulasan
│   ├── revenue_service.dart       # pendapatan
│   ├── location_service.dart      # GPS & jarak
│   ├── favorite_store.dart        # favorit (lokal)
│   ├── tournament_store.dart      # turnamen (Supabase + cache lokal)
│   ├── americano_scheduler.dart   # jadwal Americano yang merata
│   ├── mexicano_scheduler.dart    # pembentukan ronde Mexicano
│   ├── knockout_logic.dart        # bagan, bye, propagasi pemenang
│   ├── tournament_stats.dart      # statistik & data grafik
│   └── help_pdf_service.dart      # ekspor buku panduan
├── pages/
│   ├── splash_page.dart, role_router.dart, home_page.dart
│   ├── auth/                      # login, register, verifikasi email, lupa sandi
│   ├── detail_page, schedule_page, cart_page, summary_page,
│   │   payment_page, confirmation_page, history_page, booking_detail_page
│   ├── account_page.dart, help_page.dart
│   ├── owner/                     # kelola tempat milik sendiri
│   ├── admin/                     # persetujuan, pesanan, ulasan, pendapatan
│   └── competition/
│       ├── competition_page.dart          # daftar turnamen
│       ├── create_tournament_page.dart    # pilih format → nama → pengaturan
│       ├── tournament_page.dart           # Americano & Mexicano
│       └── knockout_page.dart             # bagan Knockout
├── widgets/                       # custom_bottom_nav (tombol tengah pink),
│                                  # leaderboard_card, score_sheet,
│                                  # tournament_stats_view, court_card, ...
├── data/                          # help_content, booking_options, cart_store
└── utils/                         # formatters, validators, ui_helpers, guest_gate

supabase/                          # skrip SQL, jalankan berurutan
```

---

## Menjalankan Project

Prasyarat: Flutter SDK yang mendukung Dart `^3.13.0`, emulator atau perangkat,
dan project Supabase milikmu sendiri.

```bash
flutter pub get
flutter run
```

Izin lokasi diminta saat fitur *Dekat saya* dipakai. Fitur lain tetap berjalan
jika izin ditolak.

---

## Setup Supabase

1. Buat project di [supabase.com](https://supabase.com).
2. Isi URL dan *publishable key* project-mu di `lib/config/supabase_config.dart`.
3. Atur **Authentication → Email** agar mengirim kode verifikasi (OTP).
4. Buka **SQL Editor** dan jalankan skrip di folder `supabase/` **berurutan**:

| Urutan | Berkas | Isi |
|---|---|---|
| 1 | `01_profiles.sql` | Tabel profil pengguna |
| 2 | `02_bookings.sql` | Tabel reservasi |
| 3 | `03_venues.sql` | Tempat, peran admin, aturan persetujuan |
| 4 | `04_seed_demo.sql` | Data contoh (opsional) |
| 5 | `05_step1_reviews_admin.sql` | Ulasan dan rating |
| 6 | `06_step3_location.sql` | Koordinat tempat |
| 7 | `07_step_payment.sql` | Pembayaran langsung sukses |
| 8 | `08_step_kelola_lapangan.sql` | Tolak pesanan jika tempat tidak menerima |
| 9 | `08_fitur2_3_pesanan_dan_aturan_ulasan.sql` | Akses pesanan pemilik/admin, aturan ulasan |
| 10 | `09_step_guest.sql` | Akses baca untuk mode tamu |
| 11 | `10_step_batal_h1_refund.sql` | Pembatalan H-1 dengan refund 50% |
| 12 | `11_step_ulasan_pendapatan.sql` | Hapus ulasan oleh pemilik, fungsi pendapatan |
| 13 | `12_step_tournaments.sql` | Tabel turnamen (Kompetisi) + RLS |

5. Jadikan seorang pengguna admin dengan mengubah kolom `role` di tabel `profiles`
   menjadi `admin`.

> Dua berkas berawalan `08_` dibuat terpisah; jalankan keduanya. Skrip dibuat
> idempoten (`if not exists` / `drop ... if exists`), jadi aman bila terulang.

---

## Aturan Bisnis

- **Komisi**: 20% untuk platform, 80% untuk pemilik tempat
  (ubah di `lib/config/revenue_config.dart`).
- **Durasi**: lapangan 1 atau 2 jam; kelas berupa sesi 2 jam.
- **Pembayaran**: simulasi (Transfer Bank / E-Wallet), langsung berhasil.
- **Pembatalan**: paling lambat H-1 sebelum jadwal, refund 50%; dicek di server
  lewat fungsi `cancel_booking`.
- **Ulasan**: hanya untuk pengguna yang pernah punya reservasi (tidak dibatalkan)
  di tempat tersebut; satu ulasan per pengguna per tempat.

---

## Catatan

- Pembayaran tidak memproses uang sungguhan.
- Data Kompetisi tersimpan di Supabase dan di cache lokal. Perubahan yang dibuat
  saat offline dikirim otomatis saat aplikasi terhubung lagi. Jika turnamen yang
  sama diubah di dua perangkat sekaligus, versi yang terakhir terkirim yang
  dipakai.
