import 'dart:math';
import '../models/tournament.dart';

// Mexicano: ronde 1 diacak, ronde berikutnya dibentuk dari peringkat terbaru.
// Tiap kelompok 4 pemain (urut peringkat): #1 + #4 melawan #2 + #3.
// Kelompok teratas main di lapangan 1.
class MexicanoScheduler {
  MexicanoScheduler._();

  static int _slots(int players, int courts) =>
      min(courts, players ~/ 4) * 4;

  static List<TMatch> firstRound(List<TPlayer> players, int courts) {
    final ids = players.map((p) => p.id).toList()..shuffle(Random());
    return _build(ids.take(_slots(players.length, courts)).toList(), 1);
  }

  static List<TMatch> nextRound(Tournament t) {
    final round = t.generatedRounds + 1;
    final st = t.standings(); // sudah urut peringkat
    final slots = _slots(t.players.length, t.courts);
    final rankOf = {
      for (var i = 0; i < st.length; i++) st[i].player.id: i,
    };

    // Yang istirahat: pemain yang sudah paling banyak main
    // (kalau sama, yang peringkatnya paling bawah).
    final pick = List<Standing>.from(st)
      ..sort((a, b) {
        final c = a.played.compareTo(b.played);
        if (c != 0) return c;
        return rankOf[a.player.id]!.compareTo(rankOf[b.player.id]!);
      });
    final chosen = pick.take(slots).map((s) => s.player.id).toSet();

    // Urutkan lagi berdasarkan peringkat untuk dikelompokkan per 4.
    final ids = [
      for (final s in st)
        if (chosen.contains(s.player.id)) s.player.id,
    ];
    return _build(ids, round);
  }

  static List<TMatch> _build(List<String> ids, int round) {
    final out = <TMatch>[];
    for (var g = 0; g * 4 + 3 < ids.length; g++) {
      final a = ids[g * 4];
      final b = ids[g * 4 + 1];
      final c = ids[g * 4 + 2];
      final d = ids[g * 4 + 3];
      out.add(TMatch(
        round: round,
        court: g + 1,
        teamA: [a, d],
        teamB: [b, c],
      ));
    }
    return out;
  }
}