import 'dart:math';
import 'package:flutter/material.dart';
import 'primary_button.dart';

// Hasil bottom sheet: simpan skor, atau hapus skor.
class ScoreResult {
  final int? scoreA;
  final int? scoreB;
  final bool clear;
  const ScoreResult.save(this.scoreA, this.scoreB) : clear = false;
  const ScoreResult.clear()
      : scoreA = null,
        scoreB = null,
        clear = true;
}

class ScoreSheet extends StatefulWidget {
  final String teamA;
  final String teamB;
  final int target;
  final int? initialA;
  final int? initialB;
  final bool canClear;

  const ScoreSheet({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.target,
    this.initialA,
    this.initialB,
    this.canClear = false,
  });

  @override
  State<ScoreSheet> createState() => _ScoreSheetState();
}

class _ScoreSheetState extends State<ScoreSheet> {
  int? _winner; // 0 = tim A, 1 = tim B, null = belum dipilih
  int _loser = 0; // skor tim yang kalah

  @override
  void initState() {
    super.initState();
    final a = widget.initialA;
    final b = widget.initialB;
    if (a != null && b != null) {
      _winner = a >= b ? 0 : 1;
      _loser = max(0, min(min(a, b), widget.target - 1));
    }
  }

  void _setLoser(int v) {
    if (v < 0 || v > widget.target - 1) return;
    setState(() => _loser = v);
  }

  void _save() {
    final a = _winner == 0 ? widget.target : _loser;
    final b = _winner == 1 ? widget.target : _loser;
    Navigator.pop(context, ScoreResult.save(a, b));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Masukkan Skor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Ketuk tim yang lebih dulu mencapai ${widget.target} poin, '
                'lalu atur skor tim lawan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _teamCard(0)),
              const SizedBox(width: 12),
              Expanded(child: _teamCard(1)),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Simpan Skor',
            onPressed: _winner == null ? null : _save,
          ),
          if (widget.canClear)
            TextButton(
              onPressed: () => Navigator.pop(context, const ScoreResult.clear()),
              child: Text('Hapus skor',
                  style: TextStyle(color: Colors.red.shade400)),
            ),
        ],
      ),
    );
  }

  Widget _teamCard(int side) {
    final name = side == 0 ? widget.teamA : widget.teamB;
    final isWinner = _winner == side;
    final isLoser = _winner != null && !isWinner;

    return Container(
      decoration: BoxDecoration(
        color: isWinner ? Colors.pink.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? Colors.pink.shade300 : Colors.grey.shade300,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _winner = side),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isWinner
                            ? Icons.emoji_events
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: isWinner
                            ? Colors.pink.shade400
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isWinner ? 'Menang' : 'Ketuk jika menang',
                        style: TextStyle(
                          fontSize: 12,
                          color: isWinner
                              ? Colors.pink.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
            child: isWinner
                ? Text('${widget.target}',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade400))
                : isLoser
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundBtn(
                    icon: Icons.remove,
                    onTap: () => _setLoser(_loser - 1)),
                Text('$_loser',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold)),
                _RoundBtn(
                    icon: Icons.add,
                    onTap: () => _setLoser(_loser + 1)),
              ],
            )
                : Text('-',
                style: TextStyle(
                    fontSize: 32, color: Colors.grey.shade400)),
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300)),
        child: Icon(icon, size: 20, color: Colors.pink.shade400),
      ),
    );
  }
}