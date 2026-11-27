import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/tournament_stats.dart';

class TournamentStatsView extends StatefulWidget {
  final Tournament tournament;
  const TournamentStatsView({super.key, required this.tournament});

  @override
  State<TournamentStatsView> createState() => _TournamentStatsViewState();
}

class _TournamentStatsViewState extends State<TournamentStatsView> {
  static const List<Color> _palette = [
    Color(0xFF3B82F6), Color(0xFFEF4444), Color(0xFF22C55E),
    Color(0xFFF97316), Color(0xFFA855F7), Color(0xFF06B6D4),
    Color(0xFFEC4899), Color(0xFFEAB308), Color(0xFF14B8A6),
    Color(0xFF6366F1), Color(0xFF84CC16), Color(0xFF78716C),
  ];

  bool _rankMode = false;
  final Set<String> _hidden = {};
  String? _spotlightId;

  Tournament get _t => widget.tournament;
  Color _color(int i) => _palette[i % _palette.length];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildTiles(),
        const SizedBox(height: 16),
        _buildPerformance(),
        const SizedBox(height: 16),
        _title('Sorotan turnamen'),
        _buildStreak(),
        const SizedBox(height: 8),
        _buildBiggestWin(),
        const SizedBox(height: 16),
        _title('Sorotan pemain'),
        _buildSpotlight(),
      ],
    );
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
  );

  // ---------------- Kartu ringkasan ----------------
  Widget _buildTiles() {
    final totalPoints = _t.matches
        .where((m) => m.isDone)
        .fold<int>(0, (s, m) => s + m.scoreA! + m.scoreB!);
    Widget row(Widget a, Widget b) => Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
    return Column(
      children: [
        row(
          _StatTile(
              icon: Icons.groups, label: 'Peserta', value: '${_t.players.length}'),
          _StatTile(
              icon: Icons.repeat, label: 'Ronde', value: '${_t.roundCount}'),
        ),
        const SizedBox(height: 12),
        row(
          _StatTile(
              icon: Icons.sports_tennis,
              label: 'Pertandingan',
              value: '${_t.doneCount}/${_t.matchCount}'),
          _StatTile(
              icon: Icons.tag, label: 'Total poin', value: '$totalPoints'),
        ),
      ],
    );
  }

  // ---------------- Grafik performa ----------------
  Widget _buildPerformance() {
    final last = TournamentStats.lastDoneRound(_t);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Colors.pink.shade400),
              const SizedBox(width: 8),
              const Text('Performa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildToggle(),
          const SizedBox(height: 12),
          if (last == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Grafik muncul setelah skor pertama diisi.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else ...[
            _buildChart(last),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _t.players.length; i++)
                  _LegendChip(
                    color: _color(i),
                    name: _t.players[i].name,
                    on: !_hidden.contains(_t.players[i].id),
                    onTap: () => setState(() {
                      final id = _t.players[i].id;
                      if (!_hidden.remove(id)) _hidden.add(id);
                    }),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggle() {
    Widget btn(String label, bool on, VoidCallback onTap) => Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: on ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          btn('Poin', !_rankMode, () => setState(() => _rankMode = false)),
          btn('Peringkat', _rankMode, () => setState(() => _rankMode = true)),
        ],
      ),
    );
  }

  Widget _buildChart(int last) {
    final n = _t.players.length;
    final pts = TournamentStats.cumulativePoints(_t, last);
    final ranks = TournamentStats.ranks(_t, last);

    final series = <List<double>>[
      for (final p in _t.players)
        (_rankMode ? ranks[p.id]! : pts[p.id]!).map((e) => e.toDouble()).toList(),
    ];
    final labels = _rankMode
        ? [for (var r = 1; r <= last; r++) 'R$r']
        : [for (var r = 0; r <= last; r++) 'R$r'];

    double minY;
    double maxY;
    List<double> ticks;
    if (_rankMode) {
      minY = 1;
      maxY = n.toDouble();
      ticks = n <= 6
          ? [for (var i = 1; i <= n; i++) i.toDouble()]
          : <double>[1, ((n + 1) / 2).roundToDouble(), n.toDouble()];
    } else {
      var mx = 1.0;
      for (final s in series) {
        for (final v in s) {
          if (v > mx) mx = v;
        }
      }
      minY = 0;
      maxY = mx;
      ticks = <double>[0, (mx / 2).roundToDouble(), mx];
    }

    return SizedBox(
      height: 220,
      width: double.infinity,
      child: CustomPaint(
        painter: _LineChartPainter(
          series: series,
          colors: [for (var i = 0; i < n; i++) _color(i)],
          visible: [for (final p in _t.players) !_hidden.contains(p.id)],
          labels: labels,
          minY: minY,
          maxY: maxY,
          invertY: _rankMode,
          yTicks: ticks,
        ),
      ),
    );
  }

  // ---------------- Sorotan turnamen ----------------
  Widget _buildStreak() {
    final s = TournamentStats.longestStreak(_t);
    return _InfoCard(
      icon: Icons.local_fire_department,
      title: 'Rentetan menang',
      child: s == null
          ? Text('Belum ada pemain yang menang 2 kali beruntun.',
          style: TextStyle(color: Colors.grey.shade700))
          : Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: _t.nameOf(s.playerId),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text: ' menang ${s.count} kali beruntun di ronde '
                    '${s.fromRound}–${s.toRound}'),
          ],
        ),
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _buildBiggestWin() {
    final m = TournamentStats.biggestWin(_t);
    if (m == null) {
      return _InfoCard(
        icon: Icons.bolt,
        title: 'Kemenangan terbesar',
        child: Text('Belum ada pertandingan selesai.',
            style: TextStyle(color: Colors.grey.shade700)),
      );
    }
    final aWon = m.scoreA! > m.scoreB!;
    final winners = aWon ? m.teamA : m.teamB;
    final losers = aWon ? m.teamB : m.teamA;
    final ws = aWon ? m.scoreA! : m.scoreB!;
    final ls = aWon ? m.scoreB! : m.scoreA!;
    return _InfoCard(
      icon: Icons.bolt,
      title: 'Kemenangan terbesar',
      child: Row(
        children: [
          Text('${ws - ls}',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade400)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_t.teamLabel(winners)} mengalahkan ${_t.teamLabel(losers)} '
                  '($ws-$ls) di ronde ${m.round}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Sorotan pemain ----------------
  Widget _buildSpotlight() {
    final ranking = _t.standings();
    final id = (_spotlightId != null &&
        ranking.any((s) => s.player.id == _spotlightId))
        ? _spotlightId!
        : ranking.first.player.id;
    final sp = TournamentStats.spotlight(_t, id);
    final s = sp.standing;

    Widget cell(String value, String label) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );

    final diff = s.diff;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: id,
              isExpanded: true,
              items: [
                for (var i = 0; i < ranking.length; i++)
                  DropdownMenuItem(
                    value: ranking[i].player.id,
                    child: Text('${ranking[i].player.name}   #${i + 1}'),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _spotlightId = v);
              },
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              cell('${s.wins}-${s.ties}-${s.losses}', 'W-T-L'),
              cell(diff > 0 ? '+$diff' : '$diff', 'Selisih poin'),
              cell(sp.avgScored.toStringAsFixed(1), 'Rata-rata poin'),
              cell('${s.points}', 'Total poin'),
              cell(sp.bestPartner ?? '-', 'Partner terbaik'),
              cell(sp.toughestOpponent ?? '-', 'Lawan tersulit'),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Widget kecil
// =====================================================================
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.pink.shade300),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style:
              const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _InfoCard(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.pink.shade400),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 18),
          child,
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String name;
  final bool on;
  final VoidCallback onTap;
  const _LegendChip({
    required this.color,
    required this.name,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? color : Colors.grey.shade300),
          color: on ? color.withValues(alpha: 0.08) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: on ? color : Colors.grey.shade400,
                  shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(name,
                style: TextStyle(
                    fontSize: 12,
                    color: on ? Colors.black87 : Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Grafik garis (tanpa package tambahan)
// =====================================================================
class _LineChartPainter extends CustomPainter {
  final List<List<double>> series;
  final List<Color> colors;
  final List<bool> visible;
  final List<String> labels;
  final double minY;
  final double maxY;
  final bool invertY; // true untuk grafik peringkat (1 di atas)
  final List<double> yTicks;

  _LineChartPainter({
    required this.series,
    required this.colors,
    required this.visible,
    required this.labels,
    required this.minY,
    required this.maxY,
    required this.invertY,
    required this.yTicks,
  });

  void _text(Canvas c, String s, Offset o,
      {double width = 30, TextAlign align = TextAlign.right}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(c, o);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0, right = 10.0, top = 8.0, bottom = 22.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    final n = labels.length;

    double xOf(int i) => n <= 1 ? left + w / 2 : left + w * i / (n - 1);
    double yOf(double v) {
      final f = maxY == minY ? 0.5 : (v - minY) / (maxY - minY);
      return invertY ? top + h * f : top + h * (1 - f);
    }

    // Garis bantu + angka sumbu Y
    final grid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    for (final tk in yTicks) {
      final y = yOf(tk);
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
      _text(canvas, '${tk.round()}', Offset(0, y - 6), width: left - 6);
    }

    // Label sumbu X (dijarangkan kalau ronde banyak)
    final step = (n / 7).ceil().clamp(1, 100);
    for (var i = 0; i < n; i++) {
      if (i % step == 0 || i == n - 1) {
        _text(canvas, labels[i], Offset(xOf(i) - 14, size.height - bottom + 6),
            width: 28, align: TextAlign.center);
      }
    }

    // Garis tiap pemain
    for (var p = 0; p < series.length; p++) {
      if (!visible[p]) continue;
      final line = Paint()
        ..color = colors[p]
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final dot = Paint()..color = colors[p];

      final path = Path();
      for (var i = 0; i < series[p].length; i++) {
        final pt = Offset(xOf(i), yOf(series[p][i]));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, line);
      for (var i = 0; i < series[p].length; i++) {
        canvas.drawCircle(Offset(xOf(i), yOf(series[p][i])), 3.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => true;
}