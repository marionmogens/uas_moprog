import '../models/tournament.dart';

class StreakInfo {
  final String playerId;
  final int count;
  final int fromRound;
  final int toRound;
  const StreakInfo(this.playerId, this.count, this.fromRound, this.toRound);
}

class SpotlightStats {
  final Standing standing;
  final int rank;
  final double avgScored;
  final String? bestPartner;
  final String? toughestOpponent;
  const SpotlightStats({
    required this.standing,
    required this.rank,
    required this.avgScored,
    required this.bestPartner,
    required this.toughestOpponent,
  });
}

class TournamentStats {
  TournamentStats._();

  // Ronde terakhir yang sudah ada skornya (grafik berhenti di sini,
  // jadi bertambah otomatis setiap ada skor baru).
  static int lastDoneRound(Tournament t) {
    var last = 0;
    for (final m in t.matches) {
      if (m.isDone && m.round > last) last = m.round;
    }
    return last;
  }

  // Poin kumulatif tiap pemain: indeks 0 = sebelum mulai (0), 1..last = akhir ronde.
  static Map<String, List<int>> cumulativePoints(Tournament t, int last) {
    final res = {for (final p in t.players) p.id: <int>[0]};
    final running = {for (final p in t.players) p.id: 0};
    for (var r = 1; r <= last; r++) {
      for (final m in t.matches) {
        if (!m.isDone || m.round != r) continue;
        for (final id in m.teamA) {
          running[id] = running[id]! + m.scoreA!;
        }
        for (final id in m.teamB) {
          running[id] = running[id]! + m.scoreB!;
        }
      }
      for (final p in t.players) {
        res[p.id]!.add(running[p.id]!);
      }
    }
    return res;
  }

  // Peringkat tiap pemain di akhir ronde 1..last (indeks 0 = ronde 1).
  static Map<String, List<int>> ranks(Tournament t, int last) {
    final res = {for (final p in t.players) p.id: <int>[]};
    for (var r = 1; r <= last; r++) {
      final st = t.standings(upToRound: r);
      for (var i = 0; i < st.length; i++) {
        res[st[i].player.id]!.add(i + 1);
      }
    }
    return res;
  }

  // Rentetan menang terpanjang (minimal 2). Ronde istirahat tidak memutus rentetan.
  static StreakInfo? longestStreak(Tournament t) {
    final done = t.matches.where((m) => m.isDone).toList()
      ..sort((a, b) => a.round.compareTo(b.round));
    StreakInfo? best;
    for (final p in t.players) {
      var run = 0;
      var from = 0;
      for (final m in done) {
        final inA = m.teamA.contains(p.id);
        final inB = m.teamB.contains(p.id);
        if (!inA && !inB) continue;
        final own = inA ? m.scoreA! : m.scoreB!;
        final opp = inA ? m.scoreB! : m.scoreA!;
        if (own > opp) {
          if (run == 0) from = m.round;
          run++;
          if (run >= 2 && (best == null || run > best.count)) {
            best = StreakInfo(p.id, run, from, m.round);
          }
        } else {
          run = 0;
        }
      }
    }
    return best;
  }

  // Kemenangan dengan selisih poin terbesar.
  static TMatch? biggestWin(Tournament t) {
    TMatch? best;
    var bestMargin = 0;
    for (final m in t.matches) {
      if (!m.isDone) continue;
      final d = (m.scoreA! - m.scoreB!).abs();
      if (d > bestMargin) {
        bestMargin = d;
        best = m;
      }
    }
    return best;
  }

  static SpotlightStats spotlight(Tournament t, String id) {
    final st = t.standings();
    final idx = st.indexWhere((s) => s.player.id == id);
    final s = st[idx < 0 ? 0 : idx];

    final pWins = <String, int>{};
    final pDiff = <String, int>{};
    final oLoss = <String, int>{};
    final oDiff = <String, int>{};

    for (final m in t.matches) {
      if (!m.isDone) continue;
      final inA = m.teamA.contains(id);
      final inB = m.teamB.contains(id);
      if (!inA && !inB) continue;
      final own = inA ? m.scoreA! : m.scoreB!;
      final opp = inA ? m.scoreB! : m.scoreA!;
      final mine = inA ? m.teamA : m.teamB;
      final rivals = inA ? m.teamB : m.teamA;
      final mate = mine.firstWhere((x) => x != id);

      pWins[mate] = (pWins[mate] ?? 0) + (own > opp ? 1 : 0);
      pDiff[mate] = (pDiff[mate] ?? 0) + (own - opp);
      for (final r in rivals) {
        oLoss[r] = (oLoss[r] ?? 0) + (own < opp ? 1 : 0);
        oDiff[r] = (oDiff[r] ?? 0) + (own - opp);
      }
    }

    // Partner terbaik: paling sering menang bareng, lalu selisih poin terbaik.
    String? bestPartner;
    for (final k in pWins.keys) {
      if (bestPartner == null ||
          pWins[k]! > pWins[bestPartner]! ||
          (pWins[k]! == pWins[bestPartner]! &&
              pDiff[k]! > pDiff[bestPartner]!)) {
        bestPartner = k;
      }
    }

    // Lawan tersulit: paling sering mengalahkan kita, lalu selisih terburuk.
    String? toughest;
    for (final k in oLoss.keys) {
      if (toughest == null ||
          oLoss[k]! > oLoss[toughest]! ||
          (oLoss[k]! == oLoss[toughest]! && oDiff[k]! < oDiff[toughest]!)) {
        toughest = k;
      }
    }

    return SpotlightStats(
      standing: s,
      rank: idx < 0 ? 1 : idx + 1,
      avgScored: s.played == 0 ? 0 : s.points / s.played,
      bestPartner: bestPartner == null ? null : t.nameOf(bestPartner),
      toughestOpponent: toughest == null ? null : t.nameOf(toughest),
    );
  }
}