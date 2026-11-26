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
// Hanya UI (sesuai ketentuan UTS: fitur selain Home/Detail cukup
// sebagai rancangan tampilan, belum perlu benar-benar pindah halaman).
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  // Daftar menu. Default = menu pelanggan; pemilik mengirim daftarnya sendiri.
  final List<NavItemData> items;
  final Color? activeColor;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = navItems,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? Colors.pink.shade300;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
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
        }),
      ),
    );
  }
}