import 'package:flutter/material.dart';
import '../../models/tournament.dart';
import '../../services/auth_service.dart';
import '../../services/knockout_logic.dart';
import '../../services/tournament_store.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/score_sheet.dart';

class KnockoutPage extends StatefulWidget {
  final Tournament tournament;
  const KnockoutPage({super.key, required this.tournament});

  @override
  State<KnockoutPage> createState() => _KnockoutPageState();
}

class _KnockoutPageState extends State<KnockoutPage> {
  late Tournament _t;

  String get _uid => AuthService.instance.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _t = widget.tournament;
  }

  TMatch? get _finalMatch {
    for (final m in _t.matches) {
      if (m.round == _t.roundCount && !m.third) return m;
    }
    return null;
  }

  TMatch? get _thirdMatch {
    for (final m in _t.matches) {
      if (m.third) return m;
    }
    return null;
  }

  String _label(List<String> ids) =>
      ids.isEmpty ? 'Menunggu pemenang' : _t.teamLabel(ids);

  Future<void> _save(Tournament t) async {
    setState(() => _t = t);
    await TournamentStore.upsert(_uid, t);
  }

  // Akhiri turnamen -> tampilkan juara dulu -> lalu langsung kembali
  // ke halaman Kompetisi (tidak tinggal di halaman ini).
  Future<void> _finish() async {
    await _save(_t.copyWith(finished: true));
    if (!mounted) return;
    await _showChampionDialog();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _showChampionDialog() async {
    final f = _finalMatch;
    if (f == null) return;
    final champ = KnockoutLogic.winnerOf(f);
    if (champ == null || champ.isEmpty) return;
    final runner = KnockoutLogic.loserOf(f);
    final th = _thirdMatch;
    final third = th == null ? null : KnockoutLogic.winnerOf(th);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text(
              'Selamat kepada sang juara!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              _t.teamLabel(champ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _podiumRow('🏆', 'Juara', champ),
                  _podiumRow('🥈', 'Runner-up', runner),
                  _podiumRow('🥉', 'Juara 3', third),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kembali ke Kompetisi'),
          ),
        ],
      ),
    );
  }

  Future<void> _editScore(int index) async {
    final m = _t.matches[index];
    if (m.bye) return;
    if (!m.hasTeams) {
      showMessage(
        context,
        'Tim belum lengkap. Selesaikan pertandingan sebelumnya dulu.',
        isError: true,
      );
      return;
    }
    if (_t.finished) {
      showMessage(
        context,
        'Turnamen sudah selesai. Buka kembali lewat menu untuk mengubah skor.',
        isError: true,
      );
      return;
    }
    final result = await showModalBottomSheet<ScoreResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

    final before = _t.doneCount;
    var matches = List<TMatch>.of(_t.matches);
    matches[index] = result.clear
        ? m.cleared()
        : m.withScore(result.scoreA!, result.scoreB!);
    matches = KnockoutLogic.propagate(matches);
    final next = _t.copyWith(matches: matches);

    // Kalau hasil yang diubah memengaruhi babak berikutnya, skornya ikut reset.
    final expected = before + (result.clear ? -1 : (m.isDone ? 0 : 1));
    final affected = next.doneCount < expected;

    await _save(next);
    if (!mounted) return;
    if (affected) {
      showMessage(
        context,
        'Hasil babak berikutnya yang terdampak ikut direset.',
        isError: true,
      );
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
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(yes),
          ),
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
        'Semua hasil dihapus, bagan kembali ke awal.',
        'Reset',
      );
      if (!ok) return;
      await _save(
        _t.copyWith(
          matches: KnockoutLogic.propagate(
            [for (final m in _t.matches) m.cleared()],
          ),
          finished: false,
        ),
      );
    } else if (v == 'delete') {
      final ok = await _confirm(
        'Hapus turnamen?',
        '"${_t.name}" beserta semua hasilnya akan dihapus.',
        'Hapus',
      );
      if (!ok) return;
      await TournamentStore.delete(_uid, _t.id);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rounds = _t.roundCount;
    final canFinish = _t.allDone && !_t.finished;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade300,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t.name, style: const TextStyle(fontSize: 18)),
            Text(
              _t.formatLabel,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onMenu,
            itemBuilder: (_) => [
              if (_t.finished)
                const PopupMenuItem(
                  value: 'reopen',
                  child: Text('Buka kembali'),
                ),
              const PopupMenuItem(value: 'reset', child: Text('Reset skor')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Hapus turnamen'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildSummary(),
          _buildPodium(),
          const SizedBox(height: 8),
          for (var r = 1; r <= rounds; r++) ..._buildRound(r, rounds),
        ],
      ),
      bottomNavigationBar: canFinish
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PrimaryButton(
            label: 'Akhiri Turnamen',
            onPressed: _finish,
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildSummary() {
    final total = _t.matchCount;
    final done = _t.doneCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_t.dateLabel} · Lebih dulu ${_t.targetPoints} poin',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
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
            '${_t.teamCount} tim · ${_t.roundCount} babak',
            style: const TextStyle(fontSize: 13),
          ),
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
          Text(
            '$done dari $total pertandingan selesai',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Satu baris di daftar juara (dipakai kartu podium dan dialog juara).
  Widget _podiumRow(String medal, String title, List<String>? ids) {
    if (ids == null || ids.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  TextSpan(
                    text: _t.teamLabel(ids),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Muncul langsung begitu final selesai (tidak menunggu tombol Akhiri).
  Widget _buildPodium() {
    final f = _finalMatch;
    if (f == null) return const SizedBox.shrink();
    final champ = KnockoutLogic.winnerOf(f);
    if (champ == null || champ.isEmpty) return const SizedBox.shrink();
    final runner = KnockoutLogic.loserOf(f);
    final th = _thirdMatch;
    final third = th == null ? null : KnockoutLogic.winnerOf(th);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _podiumRow('🏆', 'Juara', champ),
          _podiumRow('🥈', 'Runner-up', runner),
          _podiumRow('🥉', 'Juara 3', third),
        ],
      ),
    );
  }

  List<Widget> _buildRound(int r, int rounds) {
    final idx = <int>[
      for (var i = 0; i < _t.matches.length; i++)
        if (_t.matches[i].round == r && !_t.matches[i].third) i,
    ];
    final thirdIdx = r == rounds ? _t.matches.indexWhere((m) => m.third) : -1;
    return [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(
          KnockoutLogic.roundLabel(r, rounds),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      for (final i in idx) _buildTile(i),
      if (thirdIdx >= 0) ...[
        const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            'Perebutan Juara 3',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        _buildTile(thirdIdx),
      ],
    ];
  }

  Widget _buildTile(int index) {
    final m = _t.matches[index];

    if (m.bye) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _t.teamLabel(m.teamA),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'BYE · lolos otomatis',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final aWin = m.isDone && m.scoreA! > m.scoreB!;
    final bWin = m.isDone && m.scoreB! > m.scoreA!;
    TextStyle teamStyle(List<String> ids, bool win) => TextStyle(
      fontWeight: win ? FontWeight.bold : FontWeight.normal,
      fontStyle: ids.isEmpty ? FontStyle.italic : FontStyle.normal,
      color: ids.isEmpty ? Colors.grey.shade500 : Colors.black87,
    );

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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _label(m.teamA),
                    style: teamStyle(m.teamA, aWin),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                    m.isDone ? Colors.pink.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: m.isDone
                      ? Text(
                    '${m.scoreA} - ${m.scoreB}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.pink.shade400,
                    ),
                  )
                      : Text(
                    m.hasTeams ? 'Isi skor' : 'vs',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.pink.shade300,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _label(m.teamB),
                    textAlign: TextAlign.right,
                    style: teamStyle(m.teamB, bWin),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}