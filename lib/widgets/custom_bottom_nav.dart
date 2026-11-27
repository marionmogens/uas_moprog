import 'package:flutter/material.dart';

class NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const List<NavItemData> navItems = [
  NavItemData(
      icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda'),
  NavItemData(
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      label: 'Favorit'),
  NavItemData(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Aktivitas'),
  NavItemData(
      icon: Icons.person_outline, activeIcon: Icons.person, label: 'Akun'),
];

// Bottom navigation custom, reusable widget class terpisah.
// Kalau onCenterTap diisi, muncul tombol bulat pink menonjol di tengah.
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  // Daftar menu. Default = menu pelanggan; pemilik mengirim daftarnya sendiri.
  final List<NavItemData> items;
  final Color? activeColor;

  // Tombol tengah (opsional).
  final VoidCallback? onCenterTap;
  final IconData centerIcon;
  final String centerLabel;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = navItems,
    this.activeColor,
    this.onCenterTap,
    this.centerIcon = Icons.emoji_events,
    this.centerLabel = 'Kompetisi',
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? Colors.pink.shade300;
    final hasCenter = onCenterTap != null;

    final bar = Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(children: _buildChildren(active, hasCenter)),
    );

    if (!hasCenter) return bar;

    // Tinggi ditambah supaya tombol bulat yang menonjol tetap bisa diketuk.
    return SizedBox(
      height: 82,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, right: 0, bottom: 0, child: bar),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: _buildCenterButton()),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChildren(Color active, bool hasCenter) {
    final half = items.length ~/ 2;
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (hasCenter && i == half) children.add(_buildCenterSlot());
      children.add(_buildItem(i, active));
    }
    return children;
  }

  Widget _buildItem(int index, Color active) {
    final item = items[index];
    final isSelected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? active : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? active : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ruang kosong di bawah tombol bulat + labelnya.
  Widget _buildCenterSlot() {
    return Expanded(
      child: InkWell(
        onTap: onCenterTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            const SizedBox(height: 4),
            Text(
              centerLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: onCenterTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink.shade300, Colors.pink.shade500],
          ),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(centerIcon, color: Colors.white, size: 28),
      ),
    );
  }
}