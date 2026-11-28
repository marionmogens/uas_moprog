import 'package:flutter/material.dart';
import '../../models/tournament.dart';
import '../../services/auth_service.dart';
import '../../services/knockout_logic.dart';
import '../../services/tournament_store.dart';
import 'create_tournament_page.dart';
import 'knockout_page.dart';
import 'tournament_page.dart';

class CompetitionPage extends StatefulWidget {
  const CompetitionPage({super.key});

  @override
  State<CompetitionPage> createState() => _CompetitionPageState();
}

class _CompetitionPageState extends State<CompetitionPage> {
  List<Tournament> _items = [];
  bool _loading = true;

  String get _uid => AuthService.instance.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = await TournamentStore.loadCached(_uid);
    if (!mounted) return;
    if (cached.isNotEmpty) {
      setState(() {
        _items = cached;
        _loading = false;
      });
    }
    final fresh = await TournamentStore.load(_uid);
    if (!mounted) return;
    setState(() {
      _items = fresh;
      _loading = false;
    });
  }

  Widget _pageFor(Tournament t) => t.format == TournamentFormat.knockout
      ? KnockoutPage(tournament: t)
      : TournamentPage(tournament: t);

  Future<void> _open(Tournament t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _pageFor(t)),
    );
    _load();
  }

  Future<void> _create() async {
    final created = await Navigator.push<Tournament>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTournamentPage()),
    );
    if (created == null || !mounted) return;
    await _open(created);
  }

  Future<void> _delete(Tournament t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus turnamen?'),
        content: Text('"${t.name}" beserta semua skornya akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    await TournamentStore.delete(_uid, t.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade300,
        foregroundColor: Colors.white,
        title: const Text('Kompetisi'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.pink.shade400,
        foregroundColor: Colors.white,
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Buat Turnamen'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? _empty()
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _items.length,
        itemBuilder: (_, i) => _card(_items[i]),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.pink.shade200),
            const SizedBox(height: 12),
            const Text('Belum ada turnamen',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Buat turnamen Americano, Mexicano, atau Knockout, catat skor '
                  'tiap pertandingan, dan lihat hasilnya berubah langsung.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // Keterangan singkat di kartu: juara (knockout) / pemain teratas.
  String _extra(Tournament t) {
    if (t.format == TournamentFormat.knockout) {
      for (final m in t.matches) {
        if (m.round == t.roundCount && !m.third) {
          final w = KnockoutLogic.winnerOf(m);
          if (w != null && w.isNotEmpty) return ' · Juara: ${t.teamLabel(w)}';
        }
      }
      return '';
    }
    if (t.doneCount > 0 && t.players.isNotEmpty) {
      return ' · Teratas: ${t.standings().first.player.name}';
    }
    return '';
  }

  Widget _card(Tournament t) {
    final who = t.format == TournamentFormat.knockout
        ? '${t.teamCount} tim'
        : '${t.players.length} pemain';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(t),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: Colors.pink.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.emoji_events, color: Colors.pink.shade400),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${t.formatLabel} · ${t.dateLabel}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Text(
                        '$who · ${t.doneCount}/${t.matchCount} match${_extra(t)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t.finished ? 'Selesai' : 'Berlangsung',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t.finished
                            ? Colors.green.shade600
                            : Colors.orange.shade700,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.delete_outline,
                          color: Colors.grey.shade500),
                      onPressed: () => _delete(t),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}