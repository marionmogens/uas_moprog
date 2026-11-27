import 'dart:math';
import '../models/tournament.dart';

class KnockoutLogic {
  KnockoutLogic._();

  // Ukuran bagan = pangkat 2 terdekat (5 tim -> 8, 12 tim -> 16).
  static int bracketSize(int teams) {
    var s = 2;
    while (s < teams) {
      s *= 2;
    }
    return s;
  }

  static int totalRounds(int size) {
    var r = 0;
    var s = size;
    while (s > 1) {
      s ~/= 2;
      r++;
    }
    return r;
  }

  // Urutan seed standar: seed 1 dan 2 baru bertemu di final, dst.
  // size 8 -> [1, 8, 4, 5, 2, 7, 3, 6]
  static List<int> _seedOrder(int size) {
    var order = [1];
    while (order.length < size) {
      final sum = order.length * 2 + 1;
      final next = <int>[];
      for (final s in order) {
        next
          ..add(s)
          ..add(sum - s);
      }
      order = next;
    }
    return order;
  }

  // teams: daftar tim (tiap tim = 2 id pemain), urutan = seed.
  // Seed yang tidak punya lawan di babak 1 mendapat BYE.
  static List<TMatch> build(List<List<String>> teams,
      {bool thirdPlace = false}) {
    final n = teams.length;
    final size = bracketSize(n);
    final rounds = totalRounds(size);
    final order = _seedOrder(size);
    final ms = <TMatch>[];

    for (var i = 0; i < size ~/ 2; i++) {
      final a = order[2 * i];
      final b = order[2 * i + 1];
      if (b > n) {
        ms.add(TMatch(
            round: 1,
            court: i + 1,
            teamA: teams[a - 1],
            teamB: const <String>[],
            bye: true));
      } else {
        ms.add(TMatch(
            round: 1, court: i + 1, teamA: teams[a - 1], teamB: teams[b - 1]));
      }
    }
    for (var r = 2; r <= rounds; r++) {
      final count = size >> r;
      for (var i = 0; i < count; i++) {
        ms.add(TMatch(
            round: r,
            court: i + 1,
            teamA: const <String>[],
            teamB: const <String>[]));
      }
    }
    if (thirdPlace && rounds >= 2) {
      ms.add(TMatch(
          round: rounds,
          court: 2,
          teamA: const <String>[],
          teamB: const <String>[],
          third: true));
    }
    return propagate(ms);
  }

  static List<String>? winnerOf(TMatch m) {
    if (m.bye) return m.teamA;
    if (!m.isDone) return null;
    return m.scoreA! > m.scoreB! ? m.teamA : m.teamB;
  }

  static List<String>? loserOf(TMatch m) {
    if (m.bye || !m.isDone) return null;
    return m.scoreA! > m.scoreB! ? m.teamB : m.teamA;
  }

  static bool _same(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Hitung ulang siapa yang maju ke babak berikutnya dari hasil yang ada.
  // Kalau tim di sebuah pertandingan berubah, skornya otomatis direset.
  static List<TMatch> propagate(List<TMatch> input) {
    final ms = List<TMatch>.of(input);
    final rounds = ms.fold<int>(0, (m, e) => max(m, e.round));
    final thirdIdx = ms.indexWhere((m) => m.third);

    List<int> idxOf(int r) => [
      for (var i = 0; i < ms.length; i++)
        if (ms[i].round == r && !ms[i].third) i,
    ];

    void setSlot(int target, int side, List<String> team) {
      final old = ms[target];
      final a = side == 0 ? team : old.teamA;
      final b = side == 1 ? team : old.teamB;
      if (!_same(a, old.teamA) || !_same(b, old.teamB)) {
        ms[target] = old.withTeams(a, b);
      }
    }

    for (var r = 1; r < rounds; r++) {
      final cur = idxOf(r);
      final nxt = idxOf(r + 1);
      for (var i = 0; i < cur.length; i++) {
        final m = ms[cur[i]];
        setSlot(nxt[i ~/ 2], i % 2, winnerOf(m) ?? const <String>[]);
        if (r == rounds - 1 && thirdIdx >= 0) {
          setSlot(thirdIdx, i % 2, loserOf(m) ?? const <String>[]);
        }
      }
    }
    return ms;
  }

  static String roundLabel(int round, int rounds) {
    final left = 1 << (rounds - round + 1); // jumlah tim yang masih bertarung
    switch (left) {
      case 2:
        return 'Final';
      case 4:
        return 'Semifinal';
      case 8:
        return 'Perempat Final';
      default:
        return 'Babak $left Besar';
    }
  }
}