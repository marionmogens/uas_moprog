class HelpStep {
  final String title;
  final String body;
  const HelpStep(this.title, this.body);
}

class HelpSection {
  final String id; // 'pelanggan' | 'pemilik' | 'kompetisi'
  final String title;
  final String intro;
  final List<HelpStep> steps;
  const HelpSection({
    required this.id,
    required this.title,
    required this.intro,
    required this.steps,
  });
}

class FaqItem {
  final String question;
  final String answer;
  const FaqItem(this.question, this.answer);
}

// Buku panduan untuk Pelanggan, Pemilik Tempat, dan fitur Kompetisi.
// Admin tidak memiliki buku panduan.
const List<HelpSection> helpSections = [
  HelpSection(
    id: 'pelanggan',
    title: 'Untuk Pelanggan: dari daftar sampai bermain',
    intro: 'Alur lengkap memesan lapangan atau kelas padel.',
    steps: [
      HelpStep('1. Buat akun dan verifikasi email',
          'Di halaman Masuk ketuk Daftar, isi nama, nomor HP, email, dan kata sandi (minimal 6 karakter), centang syarat & ketentuan, lalu ketuk Daftar. Kami mengirim kode verifikasi ke emailmu: masukkan kode itu di halaman Verifikasi Email dan kamu langsung masuk ke aplikasi. Kode tidak datang? Cek folder spam atau ketuk Kirim ulang kode.'),
      HelpStep('2. Masuk, lupa kata sandi, atau jadi tamu',
          'Masuk dengan email dan kata sandi. Lupa kata sandi? Ketuk Lupa kata sandi, masukkan emailmu, lalu isi kode yang dikirim beserta kata sandi baru (tanpa kata sandi lama). Belum mau daftar? Ketuk Masuk sebagai Tamu untuk melihat lapangan dan kelas lebih dulu. Saat memesan, menyimpan favorit, atau membuka Riwayat, kamu akan diminta masuk atau daftar.'),
      HelpStep('3. Cari lapangan atau kelas',
          'Di tab Beranda pilih kategori Lapangan atau Kelas. Gunakan kolom pencarian untuk nama atau lokasi. Ketuk Dekat saya agar lapangan diurutkan dari yang terdekat (aplikasi akan meminta izin lokasi). Ketuk ikon filter untuk memilih kota, budget, jarak, indoor/outdoor, dan urutan.'),
      HelpStep('4. Lihat detail',
          'Ketuk kartu untuk melihat foto, deskripsi, fasilitas, rating dan ulasan. Tekan lama kartu untuk preview cepat, ketuk dua kali atau ikon hati untuk menyimpan ke Favorit.'),
      HelpStep('5. Atur pesanan',
          'Pilih durasi (1 atau 2 jam untuk lapangan), tambahan seperti sewa raket, bola, handuk & air mineral, atau coach (jumlahnya bisa diatur dengan tombol + dan -), dan tulis catatan untuk pengelola bila perlu. Total harga berubah otomatis.'),
      HelpStep('6. Pilih jadwal',
          'Ketuk Pilih Jadwal, tentukan tanggal (30 hari ke depan), lapangan, dan jam. Slot berlabel Penuh sudah dipesan orang lain. Jumlah jam yang dipilih harus sama dengan durasi dan berurutan. Untuk Kelas, pilih salah satu sesi 2 jam.'),
      HelpStep('7. Ringkasan',
          'Setelah memilih jadwal, ketuk Lanjut ke Ringkasan untuk memeriksa pesananmu. Nama dan nomor HP otomatis diambil dari akunmu.'),
      HelpStep('8. Bayar',
          'Pilih metode pembayaran (Transfer Bank atau E-Wallet), lalu ketuk Bayar Sekarang. Pembayaran di aplikasi ini adalah simulasi dan langsung berhasil.'),
      HelpStep('9. Cek riwayat dan beri ulasan',
          'Semua pesanan ada di tab Riwayat lengkap dengan kode booking. Ketuk satu pesanan untuk melihat detailnya. Pesanan yang sudah dibayar tidak bisa dibatalkan. Setelah bermain, ketuk Beri Ulasan untuk memberi bintang dan komentar. Mau mencatat skor permainan bersama teman? Pakai tombol Kompetisi di tengah menu bawah (lihat panduan Fitur Kompetisi).'),
    ],
  ),
  HelpSection(
    id: 'pemilik',
    title: 'Untuk Pemilik Lapangan',
    intro: 'Cara memasukkan lapangan atau kelasmu ke PadelBook dan mengelolanya.',
    steps: [
      HelpStep('1. Buka Kelola Lapangan',
          'Masuk ke tab Akun lalu ketuk Daftarkan Lapanganmu (atau Kelola Lapangan). Tidak perlu membuat akun baru; akun pelangganmu otomatis menjadi Pemilik Tempat setelah pengajuan pertama disetujui.'),
      HelpStep('2. Isi data tempat',
          'Ketuk Tambah Tempat. Pilih jenis (Lapangan atau Kelas), isi nama, kota, alamat, harga per jam, jam buka-tutup, jumlah lapangan, fasilitas, deskripsi, dan link foto. Isi titik lokasi dengan tombol Pakai lokasiku sekarang agar muncul di pencarian terdekat.'),
      HelpStep('3. Tunggu persetujuan',
          'Pengajuan berstatus Menunggu persetujuan sampai admin meninjaunya. Jika ditolak, alasan admin tampil di kartu tempat; perbaiki datanya lewat tombol Ubah lalu ketuk Ajukan Ulang.'),
      HelpStep('4. Kelola tempat',
          'Setelah Disetujui, tempatmu tampil di Beranda pelanggan. Gunakan sakelar Menerima pesanan untuk menutup sementara pemesanan. Ketuk kartu tempat untuk melihat detail, rating, dan semua ulasan, atau mengubah datanya.'),
      HelpStep('5. Hapus ulasan yang tidak pantas',
          'Di detail tempatmu, ketuk ikon tempat sampah pada ulasan yang tidak pantas, lalu konfirmasi. Rating tempat dihitung ulang otomatis. Kamu hanya bisa menghapus ulasan di lapangan atau kelas milikmu sendiri.'),
      HelpStep('6. Lihat pendapatan',
          'Di bagian atas Kelola Lapangan tampil Total Pendapatan dari pesanan yang sudah dibayar, beserta Pendapatan Bersih 80% milikmu setelah komisi PadelBook 20%. Pendapatan tiap tempat juga tampil di kartunya masing-masing.'),
    ],
  ),
  HelpSection(
    id: 'kompetisi',
    title: 'Fitur Kompetisi: hitung poin & leaderboard',
    intro: 'Catat skor turnamen padel (Americano, Mexicano, Knockout) dan lihat peringkat berubah langsung.',
    steps: [
      HelpStep('1. Buka Kompetisi',
          'Ketuk tombol bulat pink di tengah menu bawah. Tamu diminta masuk dulu. Halaman Kompetisi berisi daftar turnamenmu; ketuk Buat Turnamen untuk memulai. Data turnamen tersimpan di HP dan terpisah untuk tiap akun.'),
      HelpStep('2. Pilih format',
          'Classic Americano: pasangan berganti tiap ronde dan tiap pemain mengumpulkan poinnya sendiri; jadwal dibuat otomatis agar jumlah main tiap pemain merata. Classic Mexicano: ronde 1 diacak, ronde berikutnya dibentuk dari peringkat terbaru (peringkat 1 + 4 melawan peringkat 2 + 3). Knockout: sistem gugur antar tim yang terdiri dari 2 pemain.'),
      HelpStep('3. Isi nama, pemain, dan pengaturan',
          'Beri nama turnamen, lalu tambahkan minimal 4 pemain (Americano dan Mexicano) atau minimal 2 tim berisi 2 pemain (Knockout). Pilih poin kemenangan (tim yang lebih dulu mencapai angka itu menang), jumlah lapangan, jumlah ronde, dan urutan peringkat berdasarkan total poin atau kemenangan. Aplikasi memberi tahu apakah semua pemain main sama banyak; kalau belum, ubah jumlah ronde.'),
      HelpStep('4. Masukkan skor',
          'Ketuk satu pertandingan. Di lembar skor, ketuk di mana saja pada kotak tim yang lebih dulu mencapai poin kemenangan, lalu atur skor tim lawan dengan tombol - dan +, kemudian ketuk Simpan Skor. Salah input? Ketuk pertandingannya lagi untuk mengubah, atau pilih Hapus skor.'),
      HelpStep('5. Leaderboard real-time',
          'Setiap skor disimpan, leaderboard langsung diperbarui: menang, seri, kalah, poin, dan selisih poin. Urutan memakai total poin atau kemenangan (sesuai pengaturanmu), lalu selisih poin.'),
      HelpStep('6. Ronde Mexicano berikutnya',
          'Begitu semua skor dalam satu ronde terisi, ronde berikutnya dibuat otomatis dari peringkat terbaru, dan kamu tinggal lanjut mengisi skor. Kalau belum muncul (misalnya pada turnamen lama), ketuk tombol Buat Ronde di bagian bawah halaman.'),
      HelpStep('7. Knockout',
          'Pemenang tiap pertandingan otomatis naik ke babak berikutnya di bagan. Tim yang tidak mendapat lawan lolos otomatis (bye). Kamu bisa mengacak undian dan menambah perebutan juara 3 saat membuat turnamen. Mengubah hasil yang memengaruhi babak berikutnya akan mereset hasil di babak tersebut.'),
      HelpStep('8. Lihat statistik',
          'Buka tab Statistik untuk grafik performa (poin atau peringkat tiap ronde; ketuk nama pemain untuk menyembunyikan atau menampilkan garisnya), rentetan menang, kemenangan terbesar, dan sorotan tiap pemain: W-T-L, selisih poin, rata-rata poin, partner terbaik, dan lawan tersulit.'),
      HelpStep('9. Akhiri turnamen',
          'Setelah semua pertandingan selesai, ketuk Akhiri Turnamen. Kamu langsung kembali ke daftar Kompetisi dan juaranya tampil. Ingin mengubah skor lagi? Buka turnamennya, lalu menu titik tiga > Buka kembali. Menu itu juga berisi Reset skor dan Hapus turnamen.'),
    ],
  ),
];

const List<FaqItem> faqItems = [
  FaqItem('Apakah pembayaran di aplikasi ini sungguhan?',
      'Tidak. Pembayaran hanya simulasi untuk demonstrasi, jadi tidak ada uang yang dipotong.'),
  FaqItem('Apakah pesanan bisa dibatalkan?',
      'Tidak. Setelah pembayaran berhasil, pesanan tidak bisa dibatalkan dari aplikasi. Kamu tetap bisa melihat detail pesanan di tab Riwayat.'),
  FaqItem('Kenapa saya harus verifikasi email?',
      'Supaya akunmu benar-benar milikmu. Setelah mendaftar, masukkan kode yang dikirim ke emailmu dan kamu langsung masuk. Tanpa verifikasi, akun belum bisa dipakai masuk.'),
  FaqItem('Kode verifikasi tidak masuk ke email, bagaimana?',
      'Cek folder spam, pastikan emailnya benar, lalu ketuk Kirim ulang kode (tersedia setiap 60 detik). Kalau email salah ketik, kembali dan daftar ulang dengan email yang benar.'),
  FaqItem('Saya lupa kata sandi, bagaimana?',
      'Di halaman Masuk ketuk Lupa kata sandi, masukkan email, lalu isi kode yang dikirim dan kata sandi baru. Kata sandi lama tidak diperlukan.'),
  FaqItem('Apa bedanya masuk sebagai tamu?',
      'Tamu bisa melihat lapangan, kelas, dan ulasan tanpa akun. Untuk memesan, menyimpan favorit, atau melihat riwayat, kamu perlu masuk atau mendaftar dulu.'),
  FaqItem('Kenapa slot jam tertentu berlabel Penuh?',
      'Slot itu sudah dipesan pengguna lain. Pilih jam atau lapangan lain, atau tanggal yang berbeda.'),
  FaqItem('Aplikasi meminta izin lokasi, apakah aman?',
      'Lokasi hanya dipakai di perangkatmu untuk menghitung jarak ke lapangan dan tidak disimpan di server. Kamu bisa menolak izin dan tetap memakai aplikasi, hanya fitur Dekat saya yang tidak aktif.'),
  FaqItem('Fitur Dekat saya tidak berfungsi, apa yang harus dilakukan?',
      'Pastikan GPS/Layanan Lokasi di perangkat menyala dan izin lokasi untuk aplikasi diizinkan di pengaturan. Lapangan tanpa titik koordinat tidak muncul pada filter jarak.'),
  FaqItem('Bagaimana cara memakai filter budget?',
      'Di Beranda ketuk ikon filter, geser slider Budget per jam untuk menentukan harga minimum dan maksimum, lalu ketuk Terapkan.'),
  FaqItem('Bagaimana cara menjadi pemilik lapangan?',
      'Buka tab Akun lalu ketuk Daftarkan Lapanganmu, isi data tempat, dan kirim. Setelah admin menyetujui, kamu menjadi Pemilik Tempat.'),
  FaqItem('Pengajuan tempatku ditolak, apa yang harus dilakukan?',
      'Baca alasan penolakan di kartu tempat pada halaman Kelola Lapangan, perbaiki datanya lewat Ubah, lalu ketuk Ajukan Ulang.'),
  FaqItem('Berapa pembagian pendapatan untuk pemilik tempat?',
      'Dari setiap pesanan yang sudah dibayar, 80% menjadi pendapatan bersih pemilik tempat dan 20% adalah komisi PadelBook. Totalnya bisa dilihat di bagian atas halaman Kelola Lapangan.'),
  FaqItem('Bisakah pemilik menghapus ulasan?',
      'Bisa, tetapi hanya ulasan yang tidak pantas dan hanya di lapangan atau kelas miliknya sendiri. Buka detail tempat, ketuk ikon tempat sampah pada ulasan, lalu konfirmasi.'),
  FaqItem('Siapa yang bisa memberi ulasan?',
      'Pengguna yang pernah memiliki reservasi (tidak dibatalkan) di tempat tersebut. Satu pengguna satu ulasan per tempat dan bisa diubah dengan memberi ulasan lagi.'),
  FaqItem('Bagaimana mengubah nama atau nomor HP?',
      'Buka tab Akun, ubah di bagian Ubah Profil, lalu ketuk Simpan Perubahan.'),
  FaqItem('Apa beda Americano, Mexicano, dan Knockout?',
      'Americano: pasangan berganti tiap ronde menurut jadwal yang dibuat otomatis. Mexicano: ronde 1 diacak, ronde berikutnya dibentuk dari peringkat terbaru sehingga lawan selalu seimbang. Knockout: sistem gugur, yang kalah tersingkir dan pemenang naik ke babak berikutnya.'),
  FaqItem('Kenapa jumlah main tiap pemain tidak sama?',
      'Itu terjadi bila jumlah ronde tidak pas dengan jumlah pemain dan lapangan. Aplikasi menampilkan berapa kali tiap pemain main; ubah jumlah ronde sampai tertulis semua pemain main tepat sama banyak.'),
  FaqItem('Ronde Mexicano berikutnya tidak muncul, bagaimana?',
      'Ronde berikutnya muncul otomatis setelah semua skor ronde saat ini terisi. Pastikan tidak ada pertandingan yang masih berstatus Isi skor. Jika semuanya sudah terisi tetapi belum muncul, ketuk tombol Buat Ronde di bagian bawah halaman.'),
  FaqItem('Bagaimana cara memilih pemenang di lembar skor?',
      'Ketuk di mana saja pada kotak tim yang menang, tidak perlu mengetuk ikonnya. Lalu atur skor tim lawan dengan tombol - dan +, dan ketuk Simpan Skor.'),
  FaqItem('Apakah data kompetisi tersimpan di server?',
      'Tidak. Turnamen disimpan di HP dan terpisah untuk tiap akun. Jika kamu menghapus data aplikasi atau berpindah HP, turnamen tidak ikut terbawa.'),
  FaqItem('Bisakah tamu memakai fitur Kompetisi?',
      'Tidak. Ketuk tombol Kompetisi sebagai tamu akan mengarahkan ke halaman Masuk atau Daftar terlebih dahulu.'),
];