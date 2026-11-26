import 'package:flutter/material.dart';
import '../models/booking.dart';

// Label status reservasi berdasarkan fase: akan datang / berlangsung /
// selesai / dibatalkan / ditolak.
class BookingPhaseChip extends StatelessWidget {
  final Booking booking;
  const BookingPhaseChip({super.key, required this.booking});

  Color get _color {
    switch (booking.phase) {
      case BookingPhase.upcoming:
        return booking.status == Booking.statusPending
            ? Colors.orange.shade700
            : Colors.blue.shade600;
      case BookingPhase.inProgress:
        return Colors.green.shade600;
      case BookingPhase.finished:
        return Colors.teal.shade600;
      case BookingPhase.cancelled:
        return Colors.grey.shade600;
      case BookingPhase.rejected:
        return Colors.red.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        booking.displayLabel,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}