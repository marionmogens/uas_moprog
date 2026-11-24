import 'package:flutter/material.dart';
import '../data/help_content.dart';
import '../services/help_pdf_service.dart';
import '../utils/ui_helpers.dart';

class HelpPage extends StatefulWidget {
  final String role; // 'pelanggan' | 'pemilik' | 'admin'
  const HelpPage({super.key, this.role = 'pelanggan'});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  bool _exporting = false;
  String _faqQuery = '';

  Future<void> _downloadPdf() async {
    setState(() => _exporting = true);
    try {
      await HelpPdfService.share();
    } catch (_) {
      if (mounted) showMessage(context, 'PDF gagal dibuat. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == 'admin';
    final accent = isAdmin ? Colors.indigo.shade600 : Colors.pink.shade300;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: accent,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Pusat Bantuan',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          actions: [
            IconButton(
              tooltip: 'Unduh panduan PDF',
              onPressed: _exporting ? null : _downloadPdf,
              icon: _exporting
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Panduan'), Tab(text: 'FAQ')],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [_buildGuide(accent), _buildFaq()],
          ),
        ),
      ),
    );
  }

  Widget _buildGuide(Color accent) {
    final sections = [...helpSections]
      ..sort((a, b) =>
          (a.id == widget.role ? 0 : 1).compareTo(b.id == widget.role ? 0 : 1));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book_outlined, color: accent),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Panduan lengkap memakai PadelBook dari awal sampai akhir. '
                          'Ketuk ikon PDF di kanan atas untuk mengunduhnya.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final s in sections)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: s.id == widget.role,
                    title: Text(s.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(s.intro, style: const TextStyle(fontSize: 11.5)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final step in s.steps)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(step.title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: accent)),
                              const SizedBox(height: 2),
                              Text(step.body,
                                  style: const TextStyle(fontSize: 12.5, height: 1.45)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _exporting ? null : _downloadPdf,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Unduh Panduan (PDF)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaq() {
    final q = _faqQuery.trim().toLowerCase();
    final items = faqItems
        .where((f) =>
    q.isEmpty ||
        f.question.toLowerCase().contains(q) ||
        f.answer.toLowerCase().contains(q))
        .toList();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _faqQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari pertanyaan...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Tidak ada pertanyaan yang cocok'))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(items[i].question,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].answer,
                            style: const TextStyle(fontSize: 12.5, height: 1.45)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}