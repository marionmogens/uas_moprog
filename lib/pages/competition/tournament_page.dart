import 'package:flutter/material.dart';
import '../../models/tournament.dart';
import '../../services/auth_service.dart';
import '../../services/mexicano_scheduler.dart';
import '../../services/tournament_store.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/leaderboard_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/score_sheet.dart';
import '../../widgets/tournament_stats_view.dart';

class TournamentPage extends StatefulWidget {
  final Tournament tournament;
  const TournamentPage({super.key, required this.tournament});

  @override
  State<TournamentPage> createState() => _TournamentPageState();
}

class _TournamentPageState extends State<TournamentPage> {
  late Tournament _t;
  bool _showAll = false;

  String get _uid => AuthService.instance.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _t = widget.tournament;
  }

  // Update tampilan dulu (leaderboard + grafik langsung berubah), lalu simpan.
  Future<void> _save(Tournament t) async {
    setState(() => _t = t);
    await TournamentStore.upsert(_uid, t);
  }

  bool get _isMexicano => _t.format == TournamentFormat.mexicano;

  // Mexicano: bentuk ronde berikutnya dari peringkat terbaru, lalu tambahkan
  // ke daftar pertandingan.
  Tournament _withNextRound(Tournament t) {
    final next = MexicanoScheduler.nextRound(t);
    if (next.isEmpty) return t;
    return t.copyWith(matches: [...t.matches, ...next]);
  }

  Future<void> _generateNextRound() async {
    final n = _t.generatedRounds + 1;
    await _save(_withNextRound(_t));
    if (!mounted) return;
    showMessage(context, 'Ronde $n dibuat dari peringkat terbaru.');
  }

  // Akhiri turnamen lalu kembali ke halaman Kompetisi.
  Future<void> _finish() async {
    final st = _t.standings();
    await _save(_t.copyWith(finished: true));
    if (!mounted) return;
    showMessage(
        context,
        st.isEmpty
            ? 'Turnamen selesai.'
            : 'Turnamen selesai. Juara: ${st.first.player.name}');
    Navigator.pop(context);
  }

  Future<void> _editScore(int index) async {
    if (_t.finished) {
      showMessage(context,
          'Turnamen sudah selesai. Buka kembali lewat menu untuk mengubah skor.',
          isError: true);
      return;
    }
    final m = _t.matches[index];
    final result = await showModalBottomSheet<ScoreResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ScoreSheet(
        teamA: _t.teamLabel(m.teamA),
        teamB: _t.teamLabel(m.teamB),
        target: _t.targetPoints,
        initialA: m.scoreA,
        initialB: m.scoreB,
        canClear: m.isDone,
      ),
    );
    if (result == null) return;

    final matches = List<TMatch>.of(_t.matches);
    matches[index] = result.clear
        ? m.cleared()
        : m.withScore(result.scoreA!, result.scoreB!);
    var updated = _t.copyWith(matches: matches);

    // Mexicano: begitu semua skor di ronde ini terisi, ronde berikutnya
    // langsung dibuat berdasarkan peringkat terbaru.
    final autoNext = _isMexicano && updated.needsNextRound;
    final roundNo = updated.generatedRounds + 1;
    if (autoNext) updated = _withNextRound(updated);

    await _save(updated);
    if (!mounted) return;
    if (autoNext) {
      showMessage(context, 'Ronde $roundNo dibuat dari peringkat terbaru.');
    }
  }

  Future<bool> _confirm(String title, String body, String yes) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(yes)),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _onMenu(String v) async {
    if (v == 'reopen') {
      await _save(_t.copyWith(finished: false));
    } else if (v == 'reset') {
      final ok = await _confirm(
          'Reset semua skor?',
          _isMexicano
              ? 'Semua skor dihapus dan kembali ke ronde 1. Ronde berikutnya '
              'dibuat ulang dari peringkat.'
              : 'Semua skor akan dihapus, jadwal tetap.',
          'Reset');
      if (!ok) return;
      await _save(_t.copyWith(
        // Mexicano: ronde 2 dst. dibentuk dari peringkat, jadi ikut dibuang.
          matches: [
            for (final m in _t.matches)
              if (!_isMexicano || m.round == 1) m.cleared(),
          ],
          finished: false));
    } else if (v == 'delete') {
      final ok = await _confirm('Hapus turnamen?',
          '"${_t.name}" beserta semua skornya akan dihapus.', 'Hapus');
      if (!ok) return;
      await TournamentStore.delete(_uid, _t.id);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = _t.standings();
    final rounds = _t.generatedRounds; // ronde yang sudah dibuat

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.pink.shade300,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_t.name, style: const TextStyle(fontSize: 18)),
              Text(_t.formatLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: _onMenu,
              itemBuilder: (_) => [
                if (_t.finished)
                  const PopupMenuItem(
                      value: 'reopen', child: Text('Buka kembali')),
                const PopupMenuItem(value: 'reset', child: Text('Reset skor')),
                const PopupMenuItem(
                    value: 'delete', child: Text('Hapus turnamen')),
              ],
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Peringkat'), Tab(text: 'Statistik')],
          ),
        ),
        body: TabBarView(
          children: [
            // ----- Tab 1: Peringkat + jadwal ronde -----
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildSummary(st),
                const SizedBox(height: 16),
                const _SectionTitle('Leaderboard'),
                LeaderboardCard(
                  standings: st,
                  showAll: _showAll,
                  onToggle: () => setState(() => _showAll = !_showAll),
                ),
                const SizedBox(height: 8),
                const _SectionTitle('Pertandingan'),
                for (var r = 1; r <= rounds; r++) ..._buildRound(r),
                if (_isMexicano && !_t.finished && _t.generatedRounds < _t.totalRounds)
                  _buildNextRoundHint(),
              ],
            ),
            // ----- Tab 2: Statistik + grafik -----
            TournamentStatsView(tournament: _t),
          ],
        ),
        bottomNavigationBar: _buildBottomAction(),
      ),
    );
  }

  // Tombol di bawah: lanjut ke ronde berikutnya (Mexicano) atau akhiri turnamen.
  Widget? _buildBottomAction() {
    if (_t.finished) return null;

    String? label;
    VoidCallback? onTap;
    if (_isMexicano && _t.needsNextRound) {
      // Cadangan: ronde sebelumnya sudah selesai tetapi ronde berikutnya belum
      // terbentuk (mis. data lama atau skor direset).
      label = 'Buat Ronde ${_t.generatedRounds + 1}';
      onTap = _generateNextRound;
    } else if (_t.allDone) {
      label = 'Akhiri Turnamen';
      onTap = _finish;
    }
    if (label == null) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: PrimaryButton(label: label, onPressed: onTap),
      ),
    );
  }

  Widget _buildNextRoundHint() {
    final next = _t.generatedRounds + 1;
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.autorenew, color: Colors.pink.shade300),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ronde $next dari ${_t.totalRounds} dibuat otomatis dari '
                  'peringkat terbaru begitu semua skor ronde ini terisi.',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<Standing> st) {
    final total = _t.matchCount; // Mexicano: termasuk ronde yang belum dibuat
    final done = _t.doneCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    '${_t.dateLabel} · Lebih dulu ${_t.targetPoints} poin',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              Text(
                _t.finished ? 'Selesai' : 'Berlangsung',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _t.finished
                      ? Colors.green.shade600
                      : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              '${_t.players.length} pemain · ${_t.courts} lapangan · '
                  '${_t.roundCount} ronde',
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 8,
              backgroundColor: Colors.pink.shade50,
              color: Colors.pink.shade300,
            ),
          ),
          const SizedBox(height: 6),
          Text('$done dari $total pertandingan selesai',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          if (_t.finished && st.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Juara: ${st.first.player.name} '
                            '(${st.first.points} poin)',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildRound(int r) {
    final idx = <int>[
      for (var i = 0; i < _t.matches.length; i++)
        if (_t.matches[i].round == r) i,
    ];
    final resting = _t.restingIn(r);
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Row(
          children: [
            Text('Ronde $r',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (resting.isNotEmpty)
              Expanded(
                child: Text(
                  '  ·  Istirahat: ${resting.map((p) => p.name).join(', ')}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
      for (final i in idx) _buildMatchTile(i),
    ];
  }

  Widget _buildMatchTile(int index) {
    final m = _t.matches[index];
    final aWin = m.isDone && m.scoreA! > m.scoreB!;
    final bWin = m.isDone && m.scoreB! > m.scoreA!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _editScore(index),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_t.courts > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('Lapangan ${m.court}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(_t.teamLabel(m.teamA),
                          style: TextStyle(
                              fontWeight:
                              aWin ? FontWeight.bold : FontWeight.normal)),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: m.isDone
                            ? Colors.pink.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: m.isDone
                          ? Text('${m.scoreA} - ${m.scoreB}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.pink.shade400))
                          : Text('Isi skor',
                          style: TextStyle(
                              fontSize: 12, color: Colors.pink.shade300)),
                    ),
                    Expanded(
                      child: Text(_t.teamLabel(m.teamB),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight:
                              bWin ? FontWeight.bold : FontWeight.normal)),
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    );
  }
}