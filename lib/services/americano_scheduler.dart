import 'dart:math';
import '../models/tournament.dart';

class AmericanoScheduler {
  AmericanoScheduler._();

  // 1 lapangan = 4 pemain.
  static int maxCourts(int players) => max(1, players ~/ 4);

  // Jumlah ronde awal: minimal (pemain - 1) dan dipilih supaya semua
  // pemain main sama banyak. Contoh: 4 pemain = 3, 6 pemain = 6, 8 pemain
  // 2 lapangan = 7.
  static int suggestRounds(int players, int courts) {
    final n = max(players, 4);
    var r = n - 1;
    for (var i = 0; i < n; i++) {
      if ((r * 4 * courts) % n == 0) return r;
      r++;
    }
    return n - 1;
  }

  static List<TMatch> generate({
    required List<TPlayer> players,
    required int courts,
    required int rounds,
    int attempts = 300,
  }) {
    final rnd = Random();
    _Attempt? best;
    for (var a = 0; a < attempts; a++) {
      final r = _attempt(players, courts, rounds, rnd);
      if (best == null || r.cost < best.cost) best = r;
      if (best.cost == 0) break;
    }
    return best!.matches;
  }

  static String _k(String a, String b) =>
      a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

  static void _bump(Map<String, int> m, String k) => m[k] = (m[k] ?? 0) + 1;

  static _Attempt _attempt(
      List<TPlayer> players, int courts, int rounds, Random rnd) {
    final ids = players.map((p) => p.id).toList();
    final perRound = min(courts, ids.length ~/ 4);
    final played = {for (final id in ids) id: 0};
    final lastPlayed = {for (final id in ids) id: -1};
    final partner = <String, int>{};
    final opponent = <String, int>{};
    final matches = <TMatch>[];
    var cost = 0.0;

    for (var r = 0; r < rounds; r++) {
      // 1) Pilih yang main: paling sedikit main, lalu paling lama istirahat.
      final order = List<String>.from(ids)..shuffle(rnd);
      order.sort((a, b) {
        final c = played[a]!.compareTo(played[b]!);
        if (c != 0) return c;
        return lastPlayed[a]!.compareTo(lastPlayed[b]!);
      });
      final chosen = order.take(perRound * 4).toList();

      // 2) Cari pembagian grup + tim dengan biaya terendah.
      var bestCost = double.infinity;
      var bestTeams = <List<String>>[];
      for (var t = 0; t < 40; t++) {
        final perm = List<String>.from(chosen)..shuffle(rnd);
        var c = 0.0;
        final teams = <List<String>>[];
        for (var g = 0; g < perRound; g++) {
          final s = _bestSplit(perm.sublist(g * 4, g * 4 + 4), partner, opponent);
          c += s.cost;
          teams..add(s.a)..add(s.b);
        }
        if (c < bestCost) {
          bestCost = c;
          bestTeams = teams;
        }
      }

      // 3) Catat hasilnya.
      for (var c = 0; c < perRound; c++) {
        final ta = bestTeams[c * 2];
        final tb = bestTeams[c * 2 + 1];
        matches.add(TMatch(round: r + 1, court: c + 1, teamA: ta, teamB: tb));
        _bump(partner, _k(ta[0], ta[1]));
        _bump(partner, _k(tb[0], tb[1]));
        for (final x in ta) {
          for (final y in tb) {
            _bump(opponent, _k(x, y));
          }
        }
        for (final id in [...ta, ...tb]) {
          played[id] = played[id]! + 1;
          lastPlayed[id] = r;
        }
      }
      cost += bestCost;
    }

    final counts = played.values;
    final hi = counts.reduce((a, b) => a > b ? a : b);
    final lo = counts.reduce((a, b) => a < b ? a : b);
    cost += (hi - lo) * 100.0; // hukum jumlah main yang tidak rata
    return _Attempt(matches, cost);
  }

  // Dari 4 pemain ada 3 cara membagi tim; pilih yang paling jarang
  // mengulang pasangan (bobot 10) dan lawan (bobot 1).
  static _Split _bestSplit(
      List<String> p, Map<String, int> partner, Map<String, int> opp) {
    const options = [
      [0, 1, 2, 3],
      [0, 2, 1, 3],
      [0, 3, 1, 2],
    ];
    _Split? best;
    for (final o in options) {
      final a = p[o[0]], b = p[o[1]], c = p[o[2]], d = p[o[3]];
      final cost = 10.0 * (partner[_k(a, b)] ?? 0) +
          10.0 * (partner[_k(c, d)] ?? 0) +
          (opp[_k(a, c)] ?? 0) +
          (opp[_k(a, d)] ?? 0) +
          (opp[_k(b, c)] ?? 0) +
          (opp[_k(b, d)] ?? 0);
      if (best == null || cost < best.cost) {
        best = _Split(cost, [a, b], [c, d]);
      }
    }
    return best!;
  }
}

class _Split {
  final double cost;
  final List<String> a;
  final List<String> b;
  _Split(this.cost, this.a, this.b);
}

class _Attempt {
  final List<TMatch> matches;
  final double cost;
  _Attempt(this.matches, this.cost);
}