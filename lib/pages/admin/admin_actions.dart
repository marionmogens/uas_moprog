import 'package:flutter/material.dart';
import '../../models/padel_court.dart';
import '../../services/api_exception.dart';
import '../../services/venue_service.dart';
import '../../utils/ui_helpers.dart';

final Color adminColor = Colors.indigo.shade600;

Future<String?> _askReason(BuildContext context, String title) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Tulis alasan (wajib, akan dilihat pemilik)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            Navigator.pop(context, text);
          },
          child: const Text('Kirim'),
        ),
      ],
    ),
  );
}

Future<bool> runAdminDecision(
    BuildContext context,
    PadelCourt venue,
    String decision,
    ) async {
  String reason = '';
  if (decision == 'ditolak' || decision == 'ditangguhkan') {
    final title = decision == 'ditolak'
        ? 'Tolak "${venue.name}"'
        : 'Tangguhkan "${venue.name}"';
    final input = await _askReason(context, title);
    if (input == null) return false;
    reason = input;
  } else {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Setujui tempat'),
        content: Text('"${venue.name}" akan tampil di Beranda pelanggan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Setujui')),
        ],
      ),
    );
    if (ok != true) return false;
  }

  try {
    await VenueService.instance.adminReview(venue.id, decision, reason: reason);
    if (context.mounted) {
      final msg = decision == 'disetujui'
          ? 'Tempat disetujui'
          : decision == 'ditolak'
          ? 'Pengajuan ditolak'
          : 'Tempat ditangguhkan';
      showMessage(context, msg);
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) showMessage(context, e.message, isError: true);
    return false;
  }
}