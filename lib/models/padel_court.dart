// Model satu layanan (Lapangan atau Kelas). Dibentuk dari satu baris tabel
// `venues` di Supabase lewat PadelCourt.fromJson.
// Field yang bisa berubah (isFavorite) sengaja bukan "final" supaya bisa
// diubah langsung lewat setState di halaman Home/Detail.
class PadelCourt {
  // Jam pertama pada daftar slot (timeSlots.first = "06:00").
  static const int firstSlotHour = 6;
  // Jumlah slot di daftar timeSlots (06:00 sampai 22:00 = 17 slot).
  static const int slotCount = 17;

  final String id;
  final String name;
  final String location; // "alamat, kota" (untuk ditampilkan)
  final String category; // 'Lapangan' | 'Kelas'
  final String imageUrl;
  final int pricePerHour;
  final double rating;
  final int reviewCount;
  final bool isIndoor;
  final bool isAvailable; // false = pemilik sedang tidak menerima pesanan
  final String description;
  final List<String> facilities; // nama fasilitas, dipetakan ke ikon di UI
  final String openHours; // teks jam operasional, mis. "06.00 - 23.00 WIB"
  final List<int> classStartSlots;

  // ---- data tambahan dari tabel venues ----
  final String ownerId;
  final String city;
  final String address;
  final String mapsUrl;
  final String whatsapp;
  final int fieldCount;
  final int openHour;
  final int closeHour;
  final String status; // menunggu | disetujui | ditolak | ditangguhkan
  final String rejectReason;
  final DateTime? createdAt;

  // Koordinat tempat (boleh kosong untuk data lama) dan jarak dari user.
  final double? latitude;
  final double? longitude;
  double? distanceKm; // diisi Beranda setelah lokasi user diketahui

  // Diisi hanya pada tampilan admin (data pengaju, lewat embed `owner`).
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;

  bool isFavorite;

  PadelCourt({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    required this.imageUrl,
    required this.pricePerHour,
    required this.isIndoor,
    required this.isAvailable,
    required this.description,
    required this.facilities,
    this.rating = 0,
    this.reviewCount = 0,
    this.openHours = '',
    this.classStartSlots = const [],
    this.ownerId = '',
    this.city = '',
    this.address = '',
    this.mapsUrl = '',
    this.whatsapp = '',
    this.fieldCount = 1,
    this.openHour = 6,
    this.closeHour = 22,
    this.status = 'disetujui',
    this.rejectReason = '',
    this.createdAt,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.ownerName = '',
    this.ownerPhone = '',
    this.ownerEmail = '',
    this.isFavorite = false,
  });

  bool get isClass => category == 'Kelas';
  bool get hasCoordinates => latitude != null && longitude != null;

  // "Lapangan 1" ... "Lapangan N", sesuai jumlah lapangan yang didaftarkan.
  List<String> get fieldNames =>
      List.generate(fieldCount, (i) => 'Lapangan ${i + 1}');

  // Indeks slot pertama yang buka, dan indeks (eksklusif) setelah slot
  // terakhir. Contoh buka 08:00, tutup 22:00 -> slot 2 sampai 15.
  int get openSlotIndex => _hourToIndex(openHour);
  int get closeSlotIndex => _hourToIndex(closeHour);

  static int _hourToIndex(int hour) {
    final index = hour - firstSlotHour;
    if (index < 0) return 0;
    if (index > slotCount) return slotCount;
    return index;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  factory PadelCourt.fromJson(Map<String, dynamic> json) {
    final city = (json['city'] ?? '') as String;
    final address = (json['address'] ?? '') as String;
    final category = (json['category'] ?? 'Lapangan') as String;
    final openHour = (json['open_hour'] as num?)?.toInt() ?? 6;
    final closeHour = (json['close_hour'] as num?)?.toInt() ?? 22;
    final createdAt = json['created_at'] as String?;
    final owner = json['owner'] as Map<String, dynamic>?;

    return PadelCourt(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      location: address.isEmpty ? city : '$address, $city',
      category: category,
      imageUrl: (json['image_url'] ?? '') as String,
      pricePerHour: (json['price_per_hour'] as num?)?.toInt() ?? 0,
      isIndoor: (json['is_indoor'] ?? true) as bool,
      rating: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      isAvailable: (json['accepting_bookings'] ?? true) as bool,
      description: (json['description'] ?? '') as String,
      facilities: (json['facilities'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      openHours: category == 'Kelas'
          ? ''
          : '${_two(openHour)}.00 - ${_two(closeHour)}.00 WIB',
      classStartSlots: (json['class_start_slots'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      ownerId: (json['owner_id'] ?? '') as String,
      city: city,
      address: address,
      mapsUrl: (json['maps_url'] ?? '') as String,
      whatsapp: (json['whatsapp'] ?? '') as String,
      fieldCount: (json['field_count'] as num?)?.toInt() ?? 1,
      openHour: openHour,
      closeHour: closeHour,
      status: (json['status'] ?? 'menunggu') as String,
      rejectReason: (json['reject_reason'] ?? '') as String,
      createdAt: createdAt == null ? null : DateTime.parse(createdAt).toLocal(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      ownerName: owner == null ? '' : (owner['full_name'] ?? '') as String,
      ownerPhone: owner == null ? '' : (owner['phone'] ?? '') as String,
      ownerEmail: owner == null ? '' : (owner['email'] ?? '') as String,
    );
  }
}