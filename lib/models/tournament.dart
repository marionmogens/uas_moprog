import 'dart:math' as math;

class TournamentFormat {
  TournamentFormat._();

  static const String americano = 'americano';
  static const String mexicano = 'mexicano';
  static const String knockout = 'knockout';

  static String label(String f) {
    switch (f) {
      case mexicano:
        return 'Classic Mexicano';
      case knockout:
        return 'Knockout';
      default:
        return 'Classic Americano';
    }
  }
}

class TPlayer {
  final String id;
  final String name;
  const TPlayer({required this.id, required this.name});

  factory TPlayer.fromJson(Map<String, dynamic> j) =>
      TPlayer(id: j['id'] as String, name: j['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class TMatch {
  final int round;
  final int court;
  final List<String> teamA; // 2 id pemain (kosong = belum ditentukan)
  final List<String> teamB;
  final int? scoreA;
  final int? scoreB;
  final bool bye; // knockout: tim A lolos otomatis (tanpa lawan)
  final bool third; // knockout: perebutan juara 3

  const TMatch({
    required this.round,
    required this.court,
    required this.teamA,
    required this.teamB,
    this.scoreA,
    this.scoreB,
    this.bye = false,
    this.third = false,
  });

  bool get isDone => scoreA != null && scoreB != null;
  bool get hasTeams => teamA.isNotEmpty && teamB.isNotEmpty;

  TMatch withScore(int a, int b) => TMatch(
      round: round, court: court, teamA: teamA, teamB: teamB,
      scoreA: a, scoreB: b, bye: bye, third: third);

  TMatch cleared() => TMatch(
      round: round, court: court, teamA: teamA, teamB: teamB,
      bye: bye, third: third);

  // Ganti tim (skor ikut terhapus).
  TMatch withTeams(List<String> a, List<String> b) => TMatch(
      round: round, court: court, teamA: a, teamB: b,
      bye: bye, third: third);

  factory TMatch.fromJson(Map<String, dynamic> j) => TMatch(
    round: j['round'] as int,
    court: j['court'] as int,
    teamA: (j['team_a'] as List<dynamic>).cast<String>(),
    teamB: (j['team_b'] as List<dynamic>).cast<String>(),
    scoreA: j['score_a'] as int?,
    scoreB: j['score_b'] as int?,
    bye: (j['bye'] ?? false) as bool,
    third: (j['third'] ?? false) as bool,
  );

  Map<String, dynamic> toJson() => {
    'round': round,
    'court': court,
    'team_a': teamA,
    'team_b': teamB,
    'score_a': scoreA,
    'score_b': scoreB,
    'bye': bye,
    'third': third,
  };
}

// Satu baris leaderboard.
class Standing {
  final TPlayer player;
  final int played, wins, ties, losses, points, conceded;
  const Standing({
    required this.player,
    required this.played,
    required this.wins,
    required this.ties,
    required this.losses,
    required this.points,
    required this.conceded,
  });
  int get diff => points - conceded;
}

class Tournament {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  final String id;
  final String name;
  final String format; // lihat TournamentFormat
  // Poin kemenangan: tim yang LEBIH DULU mencapai angka ini menang.
  final int targetPoints;
  final int courts;
  // Jumlah ronde yang direncanakan (Mexicano: ronde dibuat bertahap).
  final int totalRounds;
  final bool rankByWins; // false = urut poin, true = urut kemenangan
  final DateTime createdAt;
  final bool finished;
  final List<TPlayer> players;
  final List<TMatch> matches;

  const Tournament({
    required this.id,
    required this.name,
    required this.format,
    required this.targetPoints,
    required this.courts,
    required this.totalRounds,
    required this.rankByWins,
    required this.createdAt,
    required this.finished,
    required this.players,
    required this.matches,
  });

  Tournament copyWith({List<TMatch>? matches, bool? finished}) => Tournament(
    id: id,
    name: name,
    format: format,
    targetPoints: targetPoints,
    courts: courts,
    totalRounds: totalRounds,
    rankByWins: rankByWins,
    createdAt: createdAt,
    finished: finished ?? this.finished,
    players: players,
    matches: matches ?? this.matches,
  );

  String get formatLabel => TournamentFormat.label(format);

  // Ronde yang sudah dibuat.
  int get generatedRounds =>
      matches.fold<int>(0, (m, e) => math.max(m, e.round));

  // Ronde yang direncanakan (Mexicano bisa lebih banyak dari yang sudah dibuat).
  int get roundCount => format == TournamentFormat.mexicano
      ? math.max(totalRounds, generatedRounds)
      : generatedRounds;

  // Jumlah pertandingan yang harus dimainkan (bye tidak dihitung).
  int get matchCount => format == TournamentFormat.mexicano
      ? roundCount * courts
      : matches.where((m) => !m.bye).length;

  int get doneCount => matches.where((m) => m.isDone).length;

  bool get allDone {
    if (matches.isEmpty) return false;
    if (format == TournamentFormat.knockout) {
      return matches.every((m) => m.bye || m.isDone);
    }
    return doneCount == matches.length && generatedRounds >= roundCount;
  }

  // Mexicano: ronde saat ini selesai dan masih ada ronde yang belum dibuat.
  bool get needsNextRound {
    if (format != TournamentFormat.mexicano || matches.isEmpty) return false;
    final g = generatedRounds;
    if (g >= totalRounds) return false;
    return matches.where((m) => m.round == g).every((m) => m.isDone);
  }

  // Knockout: jumlah tim (dihitung dari babak 1).
  int get teamCount {
    var c = 0;
    for (final m in matches) {
      if (m.round != 1) continue;
      if (m.teamA.isNotEmpty) c++;
      if (m.teamB.isNotEmpty) c++;
    }
    return c;
  }

  String get dateLabel =>
      '${createdAt.day} ${_months[createdAt.month - 1]} ${createdAt.year}';

  String nameOf(String id) => players
      .firstWhere((p) => p.id == id,
      orElse: () => const TPlayer(id: '', name: '?'))
      .name;

  String teamLabel(List<String> ids) => ids.map(nameOf).join(' & ');

  // Pemain yang istirahat di ronde tertentu.
  List<TPlayer> restingIn(int round) {
    final playing = <String>{};
    for (final m in matches) {
      if (m.round == round) {
        playing.addAll(m.teamA);
        playing.addAll(m.teamB);
      }
    }
    return players.where((p) => !playing.contains(p.id)).toList();
  }

  // Leaderboard dihitung ulang dari match yang sudah ada skornya.
  // upToRound: hitung sampai ronde tertentu saja (untuk grafik peringkat).
  List<Standing> standings({int? upToRound}) {
    final points = <String, int>{};
    final conceded = <String, int>{};
    final wins = <String, int>{};
    final ties = <String, int>{};
    final losses = <String, int>{};
    final played = <String, int>{};
    for (final p in players) {
      points[p.id] = 0;
      conceded[p.id] = 0;
      wins[p.id] = 0;
      ties[p.id] = 0;
      losses[p.id] = 0;
      played[p.id] = 0;
    }

    void bump(Map<String, int> map, String id, int by) =>
        map[id] = (map[id] ?? 0) + by;

    for (final m in matches) {
      if (!m.isDone) continue;
      if (upToRound != null && m.round > upToRound) continue;
      void apply(List<String> team, int own, int opp) {
        for (final id in team) {
          bump(points, id, own);
          bump(conceded, id, opp);
          bump(played, id, 1);
          if (own > opp) {
            bump(wins, id, 1);
          } else if (own == opp) {
            bump(ties, id, 1);
          } else {
            bump(losses, id, 1);
          }
        }
      }

      apply(m.teamA, m.scoreA!, m.scoreB!);
      apply(m.teamB, m.scoreB!, m.scoreA!);
    }

    final list = players
        .map((p) => Standing(
      player: p,
      played: played[p.id] ?? 0,
      wins: wins[p.id] ?? 0,
      ties: ties[p.id] ?? 0,
      losses: losses[p.id] ?? 0,
      points: points[p.id] ?? 0,
      conceded: conceded[p.id] ?? 0,
    ))
        .toList();

    list.sort((a, b) {
      int c;
      if (rankByWins) {
        c = b.wins.compareTo(a.wins);
        if (c != 0) return c;
        c = b.points.compareTo(a.points);
      } else {
        c = b.points.compareTo(a.points);
        if (c != 0) return c;
        c = b.wins.compareTo(a.wins);
      }
      if (c != 0) return c;
      c = b.diff.compareTo(a.diff);
      if (c != 0) return c;
      return a.player.name.toLowerCase().compareTo(b.player.name.toLowerCase());
    });
    return list;
  }

  factory Tournament.fromJson(Map<String, dynamic> j) {
    final matches = (j['matches'] as List<dynamic>)
        .map((e) => TMatch.fromJson(e as Map<String, dynamic>))
        .toList();
    final maxRound = matches.fold<int>(0, (m, e) => math.max(m, e.round));
    return Tournament(
      id: j['id'] as String,
      name: j['name'] as String,
      format: (j['format'] ?? TournamentFormat.americano) as String,
      targetPoints: j['target_points'] as int,
      courts: j['courts'] as int,
      totalRounds: (j['total_rounds'] ?? maxRound) as int,
      rankByWins: (j['rank_by_wins'] ?? false) as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(j['created_at'] as int),
      finished: (j['finished'] ?? false) as bool,
      players: (j['players'] as List<dynamic>)
          .map((e) => TPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      matches: matches,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'format': format,
    'target_points': targetPoints,
    'courts': courts,
    'total_rounds': totalRounds,
    'rank_by_wins': rankByWins,
    'created_at': createdAt.millisecondsSinceEpoch,
    'finished': finished,
    'players': players.map((p) => p.toJson()).toList(),
    'matches': matches.map((m) => m.toJson()).toList(),
  };
}