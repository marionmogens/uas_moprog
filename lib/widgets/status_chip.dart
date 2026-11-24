import 'package:flutter/material.dart';

class VenueStatusChip extends StatelessWidget {
  final String status;
  const VenueStatusChip({super.key, required this.status});

  static Color colorOf(String status) {
    switch (status) {
      case 'disetujui':
        return Colors.green.shade600;
      case 'ditolak':
        return Colors.red.shade400;
      case 'ditangguhkan':
        return Colors.blueGrey.shade600;
      default:
        return Colors.orange.shade700;
    }
  }

  static String labelOf(String status) {
    switch (status) {
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'ditangguhkan':
        return 'Ditangguhkan';
      default:
        return 'Menunggu persetujuan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labelOf(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}