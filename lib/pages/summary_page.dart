import 'package:flutter/material.dart';
import '../data/cart_store.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';
import 'payment_page.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  void _goToPayment(BuildContext context) {
    // Nama & nomor HP tidak perlu diisi lagi: diambil dari akun yang login.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = CartStore.items;
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade300,
        title: const Text('Ringkasan Reservasi',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Rincian Reservasi'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    for (final item in items) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.court.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                                Text(
                                  '${item.fieldName} • ${formatDate(item.date)} • ${item.timeSlot}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                                if (item.addons.isNotEmpty)
                                  Text(
                                    'Add-on: ${item.addonsText}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                  ),
                                if (item.note.isNotEmpty)
                                  Text(
                                    'Catatan: ${item.note}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            formatRupiah(item.totalPrice),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (item != items.last) const Divider(height: 20),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bayar',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          formatRupiah(CartStore.totalPrice),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.pink.shade300,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Data Pemesan'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _bookerRow(Icons.person_outline, 'Nama',
                        user?.fullName ?? '-'),
                    const SizedBox(height: 10),
                    _bookerRow(Icons.phone_outlined, 'Nomor HP',
                        (user?.phone.isNotEmpty ?? false) ? user!.phone : '-'),
                    const SizedBox(height: 10),
                    Text(
                      'Data diambil dari akunmu. Ubah lewat tab Akun bila perlu.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _goToPayment(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Lanjut ke Pembayaran'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _bookerRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 18, color: Colors.grey.shade600),
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      const Spacer(),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    );
  }
}