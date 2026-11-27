import 'package:flutter/material.dart';
import '../../models/padel_court.dart';
import '../../models/review.dart';
import '../../services/api_exception.dart';
import '../../services/review_service.dart';
import '../../services/venue_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../account_page.dart';
import 'admin_actions.dart';
import 'admin_reviews_tab.dart';
import 'admin_submissions_tab.dart';
import 'admin_venues_tab.dart';
import 'admin_bookings_tab.dart';
import 'admin_revenue_tab.dart';

const List<NavItemData> _adminNav = [
  NavItemData(
      icon: Icons.inbox_outlined, activeIcon: Icons.inbox, label: 'Pengajuan'),
  NavItemData(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront,
      label: 'Tempat'),
  NavItemData(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Pesanan'),
  NavItemData(
      icon: Icons.reviews_outlined, activeIcon: Icons.reviews, label: 'Ulasan'),
  NavItemData(
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments,
      label: 'Pendapatan'),
  NavItemData(
      icon: Icons.person_outline, activeIcon: Icons.person, label: 'Akun'),
];

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _navIndex = 0;
  bool _loading = true;
  String? _error;
  List<PadelCourt> _venues = [];
  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        VenueService.instance.fetchAllForAdmin(),
        ReviewService.instance.fetchAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _venues = results[0] as List<PadelCourt>;
        _reviews = results[1] as List<Review>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _decide(PadelCourt venue, String decision) async {
    final done = await runAdminDecision(context, venue, decision);
    if (done) _load();
  }

  Widget _body() {
    if (_navIndex == 4) return const AccountPage(isAdminView: true);
    if (_navIndex == 3) return const AdminRevenueTab();
    if (_navIndex == 2) return const AdminBookingsTab();
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    switch (_navIndex) {
      case 1:
        return AdminVenuesTab(
          venues: _venues,
          reviews: _reviews,
          onRefresh: _load,
          onDecision: _decide,
        );
      case 3:
        return AdminReviewsTab(reviews: _reviews, onRefresh: _load);
      default:
        return AdminSubmissionsTab(
          venues: _venues,
          reviews: _reviews,
          onRefresh: _load,
          onDecision: _decide,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: adminColor,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('PadelBook Admin',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(child: _body()),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomBottomNav(
          currentIndex: _navIndex,
          items: _adminNav,
          activeColor: adminColor,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }
}