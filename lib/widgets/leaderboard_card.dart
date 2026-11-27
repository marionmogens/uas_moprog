import 'package:flutter/material.dart';
import '../models/tournament.dart';

class LeaderboardCard extends StatelessWidget {
  final List<Standing> standings;
  final bool showAll;
  final VoidCallback onToggle;

  const LeaderboardCard({
    super.key,
    required this.standings,
    required this.showAll,
    required this.onToggle,
  });

  Color _rankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber.shade600;
      case 1:
        return Colors.grey.shade500;
      case 2:
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = showAll ? standings : standings.take(3).toList();
    const head = TextStyle(fontSize: 12, color: Colors.grey);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  SizedBox(width: 40),
                  Expanded(child: Text('Pemain', style: head)),
                  SizedBox(
                      width: 44,
                      child: Text('P', style: head, textAlign: TextAlign.center)),
                  SizedBox(
                      width: 62,
                      child: Text('W-T-L',
                          style: head, textAlign: TextAlign.center)),
                  SizedBox(
                      width: 40,
                      child: Text('+/-',
                          style: head, textAlign: TextAlign.right)),
                ],
              ),
              const Divider(height: 16),
              for (var i = 0; i < visible.length; i++) ...[
                _row(i, visible[i]),
                if (i != visible.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
        if (standings.length > 3)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onToggle,
              icon: Icon(
                  showAll ? Icons.keyboard_arrow_up : Icons.arrow_forward,
                  size: 18),
              label: Text(showAll ? 'Sembunyikan' : 'Lihat semua'),
            ),
          ),
      ],
    );
  }

  Widget _row(int index, Standing s) {
    final diff = s.diff;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${index + 1}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Container(
                    width: 22,
                    height: 3,
                    color: _rankColor(index)),
              ],
            ),
          ),
          Expanded(
            child: Text(s.player.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          SizedBox(
            width: 44,
            child: Text('${s.points}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 62,
            child: Text('${s.wins}-${s.ties}-${s.losses}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700)),
          ),
          SizedBox(
            width: 40,
            child: Text(diff > 0 ? '+$diff' : '$diff',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    color: diff > 0
                        ? Colors.green.shade600
                        : diff < 0
                        ? Colors.red.shade400
                        : Colors.grey)),
          ),
        ],
      ),
    );
  }
}