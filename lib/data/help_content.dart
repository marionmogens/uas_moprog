class HelpStep {
  final String title;
  final String body;
  const HelpStep(this.title, this.body);
}

class HelpSection {
  final String id; // 'pelanggan' | 'pemilik' | 'admin'
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

const List<HelpSection> helpSections = [
  HelpSection(
    id: 'pelanggan',
    title: 'Untuk Pelanggan: dari daftar sampai bermain',
    intro: 'Alur lengkap memesan lapangan atau kelas padel.',
    steps: [
      HelpStep('1. Buat akun dan masuk',
          'Di halaman Masuk ketuk Daftar, isi nama, nomor HP, email, dan kata sandi (minimal 6 karakter), centang syarat & ketentuan, lalu ketuk Daftar. Data nama dan nomor HP tersimpan di akunmu dan bisa diubah di tab Akun.'),
      HelpStep('2. Cari lapangan atau kelas',
          'Di tab Beranda pilih kategori Lapangan atau Kelas. Gunakan kolom pencarian untuk nama atau lokasi. Ketuk Dekat saya agar lapangan diurutkan dari yang terdekat (aplikasi akan meminta izin lokasi). Ketuk ikon filter untuk memilih kota, budget, jarak, indoor/outdoor, dan urutan.'),
      HelpStep('3. Lihat detail',
          'Ketuk kartu untuk melihat foto, deskripsi, fasilitas, rating dan ulasan. Tekan lama kartu untuk preview cepat, ketuk dua kali atau ikon hati untuk menyimpan ke Favorit.'),
      HelpStep('4. Atur pesanan',
          'Pilih durasi (1 atau 2 jam untuk lapangan), tambahan seperti sewa raket, bola, handuk & air mineral, atau coach, dan tulis catatan untuk pengelola bila perlu. Total harga berubah otomatis.'),
      HelpStep('5. Pilih jadwal',
          'Ketuk Pilih Jadwal, tentukan tanggal (30 hari ke depan), lapangan, dan jam. Slot berlabel Penuh sudah dipesan orang lain. Jumlah jam yang dipilih harus sama dengan durasi dan berurutan. Untuk Kelas, pilih salah satu sesi 2 jam.'),
      HelpStep('6. Keranjang dan ringkasan',
          'Reservasi masuk ke Keranjang (ikon keranjang di pojok kanan atas). Di sana kamu bisa mengubah jumlah tambahan, mengedit atau menghapus reservasi, dan menambah jadwal lain. Ketuk Checkout untuk melihat ringkasan.'),
      HelpStep('7. Bayar',
          'Pilih metode pembayaran (Transfer Bank atau E-Wallet), lalu ketuk Bayar Sekarang. Pembayaran di aplikasi ini adalah simulasi.'),
      HelpStep('8. Cek riwayat dan beri ulasan',
          // langkah riwayat
          'Semua pesanan ada di tab Riwayat lengkap dengan kode booking. Ketuk satu pesanan untuk melihat detailnya. Pesanan yang sudah dibayar tidak bisa dibatalkan. Setelah bermain, ketuk Beri Ulasan untuk memberi bintang dan komentar.'
      ),
    ],
  ),
  HelpSection(
    id: 'pemilik',
    title: 'Untuk Pemilik Lapangan',
    intro: 'Cara memasukkan lapangan atau kelasmu ke PadelBook.',
    steps: [
      HelpStep('1. Buka Tempat Saya',
          'Masuk ke tab Akun lalu ketuk Daftarkan Lapanganmu (atau Tempat Saya). Tidak perlu membuat akun baru; akun pelangganmu otomatis menjadi Pemilik Tempat setelah pengajuan pertama disetujui.'),
      HelpStep('2. Isi data tempat',
          'Ketuk Tambah Tempat. Pilih jenis (Lapangan atau Kelas), isi nama, kota, alamat, harga per jam, jam buka-tutup, jumlah lapangan, fasilitas, deskripsi, dan link foto. Isi titik lokasi dengan tombol Pakai lokasiku sekarang agar muncul di pencarian terdekat.'),
      HelpStep('3. Tunggu persetujuan',
          'Pengajuan berstatus Menunggu persetujuan sampai admin meninjaunya. Jika ditolak, alasan admin tampil di kartu tempat; perbaiki datanya lewat tombol Ubah lalu ketuk Ajukan Ulang.'),
      HelpStep('4. Kelola tempat',
          'Setelah Disetujui, tempatmu tampil di Beranda pelanggan. Gunakan sakelar Menerima pesanan untuk menutup sementara pemesanan, dan lihat rating serta jumlah ulasan di kartu tempat.'),
    ],
  ),
  HelpSection(
    id: 'admin',
    title: 'Untuk Admin',
    intro: 'Tugas admin: meninjau pengajuan dan memantau kualitas tempat.',
    steps: [
      HelpStep('1. Tab Pengajuan',
          'Menampilkan ringkasan angka dan antrean pengajuan. Periksa data tempat dan pengaju, lalu ketuk Setujui atau Tolak. Penolakan wajib disertai alasan yang akan dilihat pemilik.'),
      HelpStep('2. Tab Tempat',
          'Daftar semua tempat dengan filter status dan pencarian. Ketuk satu tempat untuk melihat detail, rating, ulasan, serta menangguhkan atau mengaktifkan kembali.'),
      HelpStep('3. Tab Ulasan',
          'Melihat seluruh ulasan pengguna, rata-rata rating, sebaran bintang, dan menyaring berdasarkan jumlah bintang.'),
    ],
  ),
];

const List<FaqItem> faqItems = [
  FaqItem('Apakah pembayaran di aplikasi ini sungguhan?',
      'Tidak. Pembayaran hanya simulasi untuk demonstrasi, jadi tidak ada uang yang dipotong.'),
  FaqItem('Bagaimana cara membatalkan reservasi?',
      'Buka tab Riwayat, cari reservasinya, lalu ketuk Batalkan. Slot jam akan terbuka kembali untuk pengguna lain.'),
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
      'Baca alasan penolakan di kartu tempat pada halaman Tempat Saya, perbaiki datanya lewat Ubah, lalu ketuk Ajukan Ulang.'),
  FaqItem('Siapa yang bisa memberi ulasan?',
      'Pengguna yang pernah memiliki reservasi (tidak dibatalkan) di tempat tersebut. Satu pengguna satu ulasan per tempat dan bisa diubah dengan memberi ulasan lagi.'),
  FaqItem('Bagaimana mengubah nama atau nomor HP?',
      'Buka tab Akun, ubah di bagian Ubah Profil, lalu ketuk Simpan Perubahan.'),
  // FAQ pembatalan
  FaqItem('Apakah pesanan bisa dibatalkan?',
      'Tidak. Setelah pembayaran berhasil, pesanan tidak bisa dibatalkan dari aplikasi. Kamu tetap bisa melihat detail pesanan di tab Riwayat.'),
];