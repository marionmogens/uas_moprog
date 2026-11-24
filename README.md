PadelBook — Aplikasi Reservasi Layanan Padel
Aplikasi Android berbasis Flutter untuk memesan lapangan dan kelas padel. Proyek ini dibuat sebagai tugas Ujian Tengah Semester (UTS) mata kuliah Mobile Programming dengan fokus pada antarmuka pengguna (UI) dan layout. Seluruh data bersifat statis/dummy, tanpa database maupun API.
Identitas Kelompok
	
Mata kuliah	Mobile Programming
Topik	Aplikasi Reservasi Layanan

Anggota	
Ellya Edyawati – 825240002
Teresa Yuardy – 825240031
Marion Mogens – 825240141

Deskripsi
PadelBook memungkinkan pengguna melihat daftar layanan padel (lapangan dan kelas), menyesuaikan pesanan (durasi, tambahan, catatan), memilih jadwal, mengumpulkan beberapa reservasi di keranjang, lalu menyelesaikan pembayaran hingga muncul konfirmasi dengan kode booking.
Alur Aplikasi
```
Beranda → Detail Layanan → Pilih Jadwal → Keranjang → Ringkasan → Pembayaran → Konfirmasi
```
Fitur Utama (sesuai ketentuan topik)
Fitur utama	Wujud di aplikasi
Keranjang	Menyimpan reservasi yang sudah dipilih jadwalnya, lengkap dengan tambahan dan subtotal
Pemilihan layanan	Daftar lapangan dan kelas, serta kustomisasi durasi, tambahan, dan catatan
Reservasi	Pilih tanggal, lapangan, dan jam berdasarkan ketersediaan, atau pilih sesi untuk kelas
Pembayaran	Pilih metode pembayaran, dialog konfirmasi, lalu halaman konfirmasi transaksi
Penjelasan Halaman

1. Beranda (Daftar Layanan)
AppBar berjudul PadelBook dengan ikon keranjang dan badge jumlah reservasi.
Teks sapaan, kolom pencarian (nama atau lokasi), dan chip kategori: Lapangan dan Kelas.
Daftar layanan berbentuk kartu: gambar, status (Tersedia/Penuh), nama, lokasi, rating, dan harga per jam.
Interaksi kartu: ketuk untuk membuka Detail, ketuk dua kali atau ikon hati untuk menandai favorit, tekan lama untuk preview singkat.
Bottom navigation: Beranda dan Favorit (menampilkan layanan yang sudah difavoritkan dalam grid 2 kolom).
2. Detail Layanan
Gambar besar dengan label status, nama, lokasi, rating, jumlah ulasan, dan indoor/outdoor.
Deskripsi dan fasilitas (parkir, toilet, AC, dan lain-lain).
Durasi 1 jam atau 2 jam untuk Lapangan. Untuk Kelas, durasi tetap 2 jam per sesi.
Tambahan yang bisa dipilih lebih dari satu: Sewa Raket, Sewa Bola, Handuk & Air Mineral 1,5L, dan Coach (khusus Lapangan; pada Kelas, pelatih sudah termasuk). Pada Kelas, raket dan bola untuk 2 orang sudah termasuk.
Kolom catatan untuk penyedia.
Total harga berubah langsung mengikuti pilihan durasi dan tambahan.
Tombol Pilih Jadwal (nonaktif jika layanan sedang penuh).
3. Pilih Jadwal
Tanggal dipilih lewat kalender (`showDatePicker`, 30 hari ke depan).
Lapangan (Lapangan 1, 2, 3) untuk reservasi lapangan.
Grid slot jam 06:00-22:00 dengan status berbeda warna: tersedia, penuh (dengan label "Penuh"), dipilih, dan di keranjang.
Jumlah slot yang dipilih harus sama dengan durasi dan berurutan.
Slot yang sudah ada di keranjang tidak bisa dipesan dua kali.
Untuk Kelas: pengguna memilih salah satu sesi kelas 2 jam yang tersedia, tanpa memilih lapangan.
Tombol lanjut hanya aktif jika tanggal dan jadwal sudah lengkap.
4. Keranjang
Daftar reservasi: layanan, lapangan/lokasi, tanggal, jam, dan durasi.
Rincian harga sewa dan subkeranjang tambahan dengan tombol + / - untuk mengubah jumlah.
Catatan yang bisa diubah, tombol Edit reservasi, dan Tambah jadwal.
Hapus reservasi dengan dialog konfirmasi.
Bar checkout berisi total harga dan tombol Checkout.
Tampilan khusus saat keranjang kosong.
5. Ringkasan Reservasi
Rincian semua reservasi (layanan, tanggal, waktu, lapangan, tambahan, catatan) dan total bayar.
Form data pemesan: nama lengkap dan nomor HP (wajib diisi sebelum lanjut).
6. Pembayaran
Total tagihan dan data pemesan.
Tiga metode pembayaran: Transfer Bank, E-Wallet, dan Bayar di Tempat (kartu dengan border saat terpilih).
Dialog konfirmasi sebelum membayar. Pembayaran hanya simulasi dan langsung menuju halaman Konfirmasi.
7. Konfirmasi
Ikon sukses dan teks "Reservasi Berhasil!".
Kode booking dummy (format `PDL-xxxxxx`).
Rincian reservasi, total dibayar, dan metode pembayaran.
Tombol Kembali ke Beranda. Keranjang sudah dikosongkan saat pembayaran dilakukan.
Fitur Tambahan
Elemen tambahan yang relevan dengan topik dan tidak mengubah fokus UI:
Favorit layanan (ikon hati, ketuk dua kali, dan tab Favorit).
Pencarian layanan berdasarkan nama atau lokasi.
Kategori Kelas dengan sesi jadwal tetap.
Edit reservasi dari Keranjang.
Pencegahan pemesanan slot yang sama dua kali.

Data Dummy
6 lapangan dan 2 kelas (`lib/data/dummy_courts.dart`), dua lapangan berstatus penuh.
Opsi durasi, tambahan, lapangan, slot jam, dan metode pembayaran ada di `lib/data/booking_options.dart`.
Slot penuh bersifat statis (pukul 08:00, 09:00, 15:00, 19:00, dan 20:00) agar tampilan konsisten.
Keranjang disimpan di memori lewat `CartStore` (`lib/data/cart_store.dart`) dan hilang saat aplikasi ditutup.
Gambar diambil dari internet (`Image.network`) dengan ikon cadangan jika gagal dimuat.
Pemenuhan Ketentuan UTS
Ketentuan	Keterangan
Dikembangkan dengan Flutter	Ya, bahasa Dart dengan widget Material
Kelompok maksimal 3 mahasiswa	Ya
Satu topik dari daftar	Aplikasi Reservasi Layanan (layanan padel)
Fokus UI/layout dengan data dummy	Ya, tidak ada database atau API
Fitur sebagai rancangan tampilan	Pembayaran, kode booking, dan ketersediaan hanya simulasi
Elemen/halaman tambahan relevan	Favorit, pencarian, kategori Kelas, dan edit reservasi
Halaman contoh dari soal	Home/Daftar Layanan, Detail, Pilih Jadwal, Ringkasan, dan Konfirmasi/Pembayaran
Konsep yang Digunakan
Halaman	Widget dan konsep utama
Beranda	`AppBar`, `Stack` + `Positioned` (badge), kartu `Container`, `Image.network`, `InkWell`, `Navigator.push`
Detail	`SingleChildScrollView`, `Stack` (gambar + label), `Container` + `InkWell` (pilihan), `TextField`, `setState`
Pilih Jadwal	`showDatePicker`, `Row`/`Column` dengan perulangan, status warna slot, `Stack` untuk label "Penuh", tombol dengan kondisi `if`
Keranjang	Kartu reservasi, stepper +/-, getter `fold`, bar checkout, `AlertDialog` hapus
Ringkasan	Teks rincian, `TextField` nama dan nomor HP, `ElevatedButton`
Pembayaran	Kartu `InkWell` dengan border terpilih, `AlertDialog` konfirmasi
Konfirmasi	`Icon` besar, `Text`, kode booking dummy, `ElevatedButton`
Catatan Implementasi
Selain widget dasar di atas, kelompok kami menggunakan beberapa widget dan teknik tambahan agar aplikasi dapat dibuat utuh dan tampil rapi:
Tambahan	Digunakan untuk
`GridView.builder`, `LayoutBuilder`	Grid kartu di Beranda dan Favorit
`ListView.builder`	Daftar reservasi di Keranjang
`ChoiceChip`, `Wrap`	Chip kategori, fasilitas, tambahan, dan slot jam
`showModalBottomSheet`, `Dialog`, `GestureDetector`	Preview cepat (tekan lama)
`SnackBar`	Pesan validasi form pemesan
`Navigator.pushAndRemoveUntil`, `popUntil`	Membersihkan tumpukan halaman setelah reservasi dan pembayaran
`Future.delayed`, `async`/`await`	Notifikasi favorit dan menunggu halaman Keranjang/Detail ditutup
Callback `static` pada `CartStore`	Memperbarui badge keranjang di Beranda

Struktur Proyek
```
lib/
├── main.dart
├── data/
│   ├── booking_options.dart   # durasi, tambahan, lapangan, slot jam, metode bayar
│   ├── cart_store.dart        # penyimpanan keranjang (dummy, di memori)
│   └── dummy_courts.dart      # data lapangan dan kelas
├── models/
│   ├── cart_item.dart         # CartItem dan CartAddon
│   └── padel_court.dart       # model layanan
├── pages/
│   ├── home_page.dart
│   ├── detail_page.dart
│   ├── schedule_page.dart
│   ├── cart_page.dart
│   ├── summary_page.dart
│   ├── payment_page.dart
│   └── confirmation_page.dart
├── utils/
│   └── formatters.dart        # format rupiah dan tanggal
└── widgets/
    ├── court_card.dart
    ├── custom_bottom_nav.dart
    ├── facility_chip.dart
    └── selectable_option.dart

```
Cara Menjalankan
Prasyarat: Flutter 3.27 atau lebih baru, Android Studio (atau VS Code), dan emulator Android atau perangkat fisik. Koneksi internet diperlukan agar gambar tampil.
```bash
git clone https://github.com/marionmogens/uts_moprog.git
cd uts_moprog
flutter pub get
flutter run
```

Pastikan perangkat Android terpilih (`flutter devices`) sebelum menjalankan.
Batasan
Tidak ada backend, database, atau autentikasi.
Pembayaran, kode booking, dan ketersediaan slot hanya simulasi.
Data hilang saat aplikasi ditutup.
Tab Riwayat dan Akun belum dibuat karena tidak diperlukan pada tahap UI.
