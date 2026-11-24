import 'package:flutter/material.dart';
import '../data/cart_store.dart';
import '../models/padel_court.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/favorite_store.dart';
import '../services/venue_service.dart';
import '../widgets/court_card.dart';
import '../widgets/custom_bottom_nav.dart';
import 'account_page.dart';
import 'detail_page.dart';
import 'history_page.dart';
import 'cart_page.dart';
import '../models/venue_filter.dart';
import '../services/location_service.dart';
import '../utils/formatters.dart';
import '../utils/ui_helpers.dart';
import '../widgets/filter_sheet.dart';
import 'help_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Daftar tempat diambil dari Supabase (hanya yang sudah disetujui admin).
  List<PadelCourt> _courts = [];
  bool _loading = true;
  String? _loadError;
  Set<String> _favoriteIds = {};
  final List<String> _categories = const ['Lapangan', 'Kelas'];

  String _selectedCategory = 'Lapangan';
  int _navIndex = 0;
  String? _toastMessage;
  int _toastToken = 0;

  // Controller + teks pencarian untuk search bar di Home.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  VenueFilter _filter = const VenueFilter();
  UserLocation? _userLocation; // null = "Dekat saya" belum aktif
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    // Setiap isi keranjang berubah (di halaman mana pun), Home ikut
    // di-refresh supaya angka badge keranjang selalu sesuai.
    CartStore.onChanged = () {
      if (mounted) {
        setState(() {});
      }
    };
    _loadCourts();
  }

  @override
  void dispose() {
    CartStore.onChanged = null;
    _searchController.dispose();
    super.dispose();
  }

  String get _userId => AuthService.instance.currentUser?.id ?? '';

  // Ambil daftar tempat dari server + tanda favorit yang tersimpan di HP.
  Future<void> _loadCourts() async {
    try {
      final courts = await VenueService.instance.fetchApproved();
      final favorites = await FavoriteStore.load(_userId);
      for (final court in courts) {
        court.isFavorite = favorites.contains(court.id);
      }
      if (!mounted) return;
      setState(() {
        _courts = courts;
        _favoriteIds = favorites;
        _loadError = null;
        _loading = false;
        _applyDistances();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    }
  }

  // Dipakai tombol muat ulang dan tombol "Coba lagi".
  void _reloadCourts() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _loadCourts();
  }

  // Daftar layanan setelah difilter: kategori (Lapangan / Kelas), kata kunci
  // pencarian, dan filter lanjutan (kota, jarak, urutan, dst.).
  List<PadelCourt> get _filteredCourts => _filter.apply(
    _courts,
    category: _selectedCategory,
    query: _searchQuery,
  );

  // Daftar layanan yang sudah ditandai favorit (hati merah), dari kategori mana pun.
  List<PadelCourt> get _favoriteCourts =>
      _courts.where((c) => c.isFavorite).toList();

  // Tandai / batalkan favorit, simpan ke HP, lalu tampilkan toast.
  Future<void> _toggleFavorite(PadelCourt court) async {
    final nowFavorite = !court.isFavorite;
    setState(() {
      court.isFavorite = nowFavorite;
      if (nowFavorite) {
        _favoriteIds.add(court.id);
      } else {
        _favoriteIds.remove(court.id);
      }
    });
    _showToast(
      nowFavorite
          ? '${court.name} ditambahkan ke favorit'
          : '${court.name} dihapus dari favorit',
    );
    await FavoriteStore.save(_userId, _favoriteIds);
  }

  List<String> get _cities {
    final set = _courts.map((c) => c.city).where((c) => c.isNotEmpty).toSet();
    return set.toList()..sort();
  }

  void _applyDistances() {
    final loc = _userLocation;
    for (final c in _courts) {
      c.distanceKm = (loc != null && c.hasCoordinates)
          ? LocationService.instance.distanceKm(loc, c.latitude!, c.longitude!)
          : null;
    }
  }

  Future<void> _toggleNearby() async {
    if (_userLocation != null) {
      setState(() {
        _userLocation = null;
        _applyDistances();
        _filter = _filter.copyWith(
          clearRadius: true,
          sort: _filter.sort == VenueSort.nearest
              ? VenueSort.recommended
              : _filter.sort,
        );
      });
      return;
    }
    setState(() => _locating = true);
    try {
      final loc = await LocationService.instance.getCurrent();
      if (!mounted) return;
      setState(() {
        _userLocation = loc;
        _applyDistances();
        _filter = _filter.copyWith(sort: VenueSort.nearest);
      });
      final withCoords = _courts.where((c) => c.hasCoordinates).length;
      if (withCoords == 0) {
        showMessage(context,
            'Lokasimu ditemukan, tapi belum ada tempat yang punya titik koordinat.',
            isError: true);
      }
    } on LocationException catch (e) {
      if (!mounted) return;
      showMessage(context, e.message, isError: true);
      if (e.openAppSettings) {
        await LocationService.instance.openAppSettings();
      } else if (e.openLocationSettings) {
        await LocationService.instance.openLocationSettings();
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openFilter() async {
    final result = await showFilterSheet(
      context,
      current: _filter,
      cities: _cities,
      hasLocation: _userLocation != null,
    );
    if (result != null) setState(() => _filter = result);
  }

  // Notifikasi kecil di atas layar, dipicu dari double tap.
  // Pola token sama seperti di aplikasi sebelumnya, supaya pesan
  // tidak saling tertutup ketika beberapa card di-double tap beruntun.
  void _showToast(String message) {
    setState(() => _toastMessage = message);
    final myToken = ++_toastToken;
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && myToken == _toastToken) {
        setState(() => _toastMessage = null);
      }
    });
  }

  // Dipicu dari long press: preview cepat lapangan tanpa pindah halaman dulu.
  void _showQuickPreview(PadelCourt court) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                court.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                court.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _openDetail(court);
                  },
                  child: const Text('Lihat Detail'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDetail(PadelCourt court) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailPage(court: court)),
    );
    // Refresh setelah kembali dari Detail, siapa tahu status
    // favorite-nya diubah dari sana (object yang sama, isFavorite mutable).
    // Sinkronkan juga ke daftar id + simpan ke HP.
    if (!mounted) return;
    setState(() {
      _favoriteIds = _courts.where((c) => c.isFavorite).map((c) => c.id).toSet();
    });
    await FavoriteStore.save(_userId, _favoriteIds);
  }

  Future<void> _openCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
    );
    // Refresh badge setelah kembali dari Keranjang, karena isi
    // CartStore mungkin berubah (item dihapus atau jumlahnya diubah)
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade300,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: _buildBrandRefresh(),
        actions: [
          IconButton(
            tooltip: 'Bantuan',
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpPage()),
            ),
          ),
          _buildCartButton(),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildTabContent(),
            if (_toastMessage != null)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: _ToastBanner(message: _toastMessage!),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomBottomNav(
          currentIndex: _navIndex,
          onTap: (index) => setState(() => _navIndex = index),
        ),
      ),
    );
  }

  // Isi body sesuai tab bottom nav yang sedang aktif:
  // 0 = Beranda, 1 = Favorit, 2 = Riwayat, 3 = Akun.
  Widget _buildTabContent() {
    if (_navIndex == 1) {
      return _buildFavoritesView();
    }
    if (_navIndex == 2) {
      return const HistoryPage();
    }
    if (_navIndex == 3) {
      return const AccountPage();
    }
    return Column(
      children: [
        _buildGreeting(),
        _buildSearchBar(),
        _buildCategoryChips(),
        _buildQuickFilters(),
        const SizedBox(height: 4),
        Expanded(child: _buildCourtGrid()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Cari nama lapangan atau lokasi...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            InkWell(
              onTap: _openFilter,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.tune, color: Colors.pink.shade300),
                    if (_filter.activeCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_filter.activeCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    final nearbyOn = _userLocation != null;
    final chips = <Widget>[
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          avatar: _locating
              ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.my_location,
              size: 16, color: nearbyOn ? Colors.white : Colors.pink.shade300),
          label: Text('Dekat saya',
              style: TextStyle(
                  fontSize: 12, color: nearbyOn ? Colors.white : Colors.black87)),
          selected: nearbyOn,
          showCheckmark: false,
          selectedColor: Colors.pink.shade300,
          backgroundColor: Colors.white,
          onSelected: _locating ? null : (_) => _toggleNearby(),
        ),
      ),
    ];

    Widget active(String label, VoidCallback onRemove) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.pink.shade50,
        onDeleted: onRemove,
        deleteIconColor: Colors.pink.shade300,
      ),
    );

    if (_filter.city != null) {
      chips.add(active(_filter.city!,
              () => setState(() => _filter = _filter.copyWith(clearCity: true))));
    }
    if (_filter.hasBudget) {
      final max = _filter.maxPrice >= VenueFilter.budgetMax
          ? '${formatRupiah(VenueFilter.budgetMax)}+'
          : formatRupiah(_filter.maxPrice);
      chips.add(active('${formatRupiah(_filter.minPrice)} - $max',
              () => setState(() => _filter = _filter.copyWith(
              minPrice: VenueFilter.budgetMin, maxPrice: VenueFilter.budgetMax))));
    }
    if (_filter.radiusKm != null) {
      chips.add(active('≤ ${_filter.radiusKm!.toStringAsFixed(0)} km',
              () => setState(() => _filter = _filter.copyWith(clearRadius: true))));
    }
    if (_filter.indoor != null) {
      chips.add(active(_filter.indoor! ? 'Indoor' : 'Outdoor',
              () => setState(() => _filter = _filter.copyWith(clearIndoor: true))));
    }
    if (_filter.sort != VenueSort.recommended &&
        !(nearbyOn && _filter.sort == VenueSort.nearest)) {
      chips.add(active(_filter.sort.label,
              () => setState(() => _filter = _filter.copyWith(sort: VenueSort.recommended))));
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: chips,
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Welcome to PadelBook!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                'Silakan pilih layanan yang Anda butuhkan',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        )
    );
  }

// Ikon keranjang di AppBar + badge jumlah item. Stack + Positioned
// dipakai supaya badge bisa "menempel" di pojok kanan atas ikon.
// Badge hanya muncul kalau keranjang tidak kosong.
  Widget _buildCartButton() {
    final count = CartStore.totalItemCount;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: _openCart,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              if (count > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Logo + tulisan "PadelBook" di kiri atas. Diketuk = muat ulang daftar
  // tempat (menggantikan tombol refresh yang dulu ada di kanan atas).
  // Saat sedang memuat, logo diganti spinner kecil sebagai penanda.
  Widget _buildBrandRefresh() {
    return Tooltip(
      message: 'Ketuk untuk muat ulang',
      child: InkWell(
        onTap: _loading ? null : _reloadCourts,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: _loading
                    ? const Padding(
                  padding: EdgeInsets.all(2),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.sports_tennis,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                'PadelBook',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _loadError ?? 'Gagal memuat data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _reloadCourts,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // Filter kategori (Lapangan/Kelas). Menggunakan Wrap supaya chip
  // tidak overflow kalau daftar kategori bertambah atau layar sempit.
  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: _categories.map((category) {
          final isSelected = category == _selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            selectedColor: Colors.pink.shade300,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 12,
            ),
            onSelected: (_) => setState(() => _selectedCategory = category),
          );
        }).toList(),
      ),
    );
  }

  // Menghitung childAspectRatio supaya tinggi sel grid pas dengan isi card.
  // Tinggi card = tinggi gambar (lebar / 1.6, sesuai AspectRatio 16/10)
  // + bagian teks (sekitar 92 px). Dengan begini tidak ada ruang kosong
  // di bawah card, berapa pun lebar layarnya.
  double _cardAspectRatio(double gridWidth, int columns) {
    const sidePadding = 16.0 * 2; // padding kiri-kanan grid
    const spacing = 12.0; // jarak antar kolom
    final cellWidth = (gridWidth - sidePadding - spacing * (columns - 1)) / columns;
    final cellHeight = cellWidth / 1.6 + 92;
    return cellWidth / cellHeight;
  }

  // Grid responsif: LayoutBuilder dipakai untuk menentukan jumlah kolom
  // berdasarkan lebar layar yang TERSEDIA (bukan lebar layar penuh),
  // jadi tetap akurat walau dipakai di dalam layout lain.
  Widget _buildCourtGrid() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) return _buildLoadError();
    final courts = _filteredCourts;
    if (courts.isEmpty) {
      return Center(
        child: Text(
          (_searchQuery.trim().isEmpty && _filter.activeCount > 0)
              ? 'Tidak ada tempat yang cocok dengan filter'
              :
          _searchQuery.trim().isEmpty
              ? (_courts.isEmpty
              ? 'Belum ada tempat yang terdaftar.'
              : 'Belum ada layanan untuk kategori ini')
              : 'Tidak ada hasil untuk "${_searchQuery.trim()}"',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth >= 900) {
          crossAxisCount = 3; // desktop/tablet lanskap
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2; // tablet
        } else {
          crossAxisCount = 1; // mobile
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: _cardAspectRatio(constraints.maxWidth, crossAxisCount),
          ),
          itemBuilder: (context, index) {
            final court = courts[index];
            return CourtCard(
              court: court,
              onTap: () => _openDetail(court),
              onDoubleTap: () => _toggleFavorite(court),
              onLongPress: () => _showQuickPreview(court),
              onToggleFavorite: () => _toggleFavorite(court),
            );
          },
        );
      },
    );
  }

  // Tampilan tab Favorit: grid 2 kolom supaya kartunya tidak terlalu
  // melebar. Memakai CourtCard yang sama dengan Home, jadi gesture-nya
  // (tap, double tap, long press, ikon hati) tetap bekerja.
  Widget _buildFavoritesView() {
    final favorites = _favoriteCourts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'My Favorites',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
              ? _buildLoadError()
              : favorites.isEmpty
              ? _buildEmptyFavorites()
              : LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: _cardAspectRatio(constraints.maxWidth, 2),
                ),
                itemBuilder: (context, index) {
                  final court = favorites[index];
                  return CourtCard(
                    court: court,
                    onTap: () => _openDetail(court),
                    onDoubleTap: () => _toggleFavorite(court),
                    onLongPress: () => _showQuickPreview(court),
                    onToggleFavorite: () => _toggleFavorite(court),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Belum ada favorit',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(
              'Ketuk ikon hati atau ketuk dua kali pada layanan untuk menyimpannya di favorit',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToastBanner extends StatelessWidget {
  final String message;
  const _ToastBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}