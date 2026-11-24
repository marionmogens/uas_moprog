import 'package:flutter/material.dart';
import '../services/api_exception.dart';
import '../services/review_service.dart';
import '../utils/ui_helpers.dart';
import 'star_rating.dart';

Future<bool?> showReviewDialog(
    BuildContext context, {
      required String venueId,
      required String venueName,
    }) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _ReviewDialog(venueId: venueId, venueName: venueName),
  );
}

class _ReviewDialog extends StatefulWidget {
  final String venueId;
  final String venueName;
  const _ReviewDialog({required this.venueId, required this.venueName});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _saving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      showMessage(context, 'Pilih jumlah bintang dulu', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ReviewService.instance.submit(
        venueId: widget.venueId,
        rating: _rating,
        comment: _commentController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text('Ulasan ${widget.venueName}',
          style: const TextStyle(fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StarPicker(value: _rating, onChanged: (v) => setState(() => _rating = v)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Ceritakan pengalamanmu (opsional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Kirim'),
        ),
      ],
    );
  }
}