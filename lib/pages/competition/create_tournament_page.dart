import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tournament.dart';
import '../../services/americano_scheduler.dart';
import '../../services/auth_service.dart';
import '../../services/knockout_logic.dart';
import '../../services/mexicano_scheduler.dart';
import '../../services/tournament_store.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/primary_button.dart';

class CreateTournamentPage extends StatefulWidget {
  const CreateTournamentPage({super.key});

  @override
  State<CreateTournamentPage> createState() => _CreateTournamentPageState();
}

class _CreateTournamentPageState extends State<CreateTournamentPage> {
  static const int _maxPlayers = 24;
  static const int _maxTeams = 32;
  static const List<int> _targets = [7, 11, 15, 21, 25];

  int _step = 0; // 0 = format, 1 = nama, 2 = pengaturan
  String _format = TournamentFormat.americano;

  final _nameCtrl = TextEditingController();
  final _playerCtrl = TextEditingController();
  final _courtsCtrl = TextEditingController(text: '1');
  final _roundsCtrl = TextEditingController(text: '3');
  final _p1Ctrl = TextEditingController();
  final _p2Ctrl = TextEditingController();

  final List<String> _players = []; // Americano & Mexicano
  final List<List<String>> _teams = []; // Knockout
  List<String> _suggested = [];

  int _target = 11;
  bool _roundsTouched = false;
  bool _rankByWins = false;
  bool _shuffleBracket = true;
  bool _thirdPlace = true;
  bool _saving = false;

  String get _uid => AuthService.instance.currentUser?.id ?? '';
  bool get _isKnockout => _format == TournamentFormat.knockout;

  @override
  void initState() {
    super.initState();
    _loadSuggested();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _playerCtrl.dispose();
    _courtsCtrl.dispose();
    _roundsCtrl.dispose();
    _p1Ctrl.dispose();
    _p2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuggested() async {
    final all = await TournamentStore.load(_uid);
    final names = <String>[];
    for (final t in all) {
      for (final p in t.players) {
        if (!names.contains(p.name)) names.add(p.name);
      }
    }
    if (!mounted) return;
    setState(() => _suggested = names);
  }

  // ---------------- Pemain (Americano & Mexicano) ----------------
  void _addName(String raw) {
    final n = raw.trim();
    if (n.isEmpty) return;
    if (_players.any((p) => p.toLowerCase() == n.toLowerCase())) {
      showMessage(context, 'Nama pemain sudah ada.', isError: true);
      return;
    }
    if (_players.length >= _maxPlayers) {
      showMessage(context, 'Maksimal $_maxPlayers pemain.', isError: true);
      return;
    }
    setState(() {
      _players.add(n);
      _playerCtrl.clear();
      _syncRounds();
    });
  }

  void _removeName(String n) {
    setState(() {
      _players.remove(n);
      _syncRounds();
    });
  }

  // ---------------- Tim (Knockout) ----------------
  void _addTeam() {
    final a = _p1Ctrl.text.trim();
    final b = _p2Ctrl.text.trim();
    if (a.isEmpty || b.isEmpty) {
      showMessage(context, 'Isi nama kedua pemain.', isError: true);
      return;
    }
    final used = <String>{
      for (final t in _teams) ...t.map((e) => e.toLowerCase()),
    };
    if (a.toLowerCase() == b.toLowerCase() ||
        used.contains(a.toLowerCase()) ||
        used.contains(b.toLowerCase())) {
      showMessage(context, 'Nama pemain sudah dipakai di tim lain.',
          isError: true);
      return;
    }
    if (_teams.length >= _maxTeams) {
      showMessage(context, 'Maksimal $_maxTeams tim.', isError: true);
      return;
    }
    setState(() {
      _teams.add([a, b]);
      _p1Ctrl.clear();
      _p2Ctrl.clear();
    });
  }

  // ---------------- Lapangan & ronde ----------------
  int get _courtsClamped {
    final maxC = AmericanoScheduler.maxCourts(_players.length);
    final c = int.tryParse(_courtsCtrl.text.trim()) ?? 1;
    return max(1, min(c, maxC));
  }

  int get _suggestedRounds =>
      AmericanoScheduler.suggestRounds(_players.length, _courtsClamped);

  void _syncRounds() {
    if (_roundsTouched) return;
    _roundsCtrl.text = _suggestedRounds.toString();
  }

  String get _fairText {
    final n = _players.length;
    if (n < 4) return 'Tambahkan minimal 4 pemain.';
    final rounds = int.tryParse(_roundsCtrl.text.trim()) ?? 0;
    if (rounds < 1) return 'Isi jumlah ronde.';
    final total = rounds * 4 * _courtsClamped;
    final lo = total ~/ n;
    final hi = (total + n - 1) ~/ n;
    return lo == hi
        ? 'Setiap pemain main tepat $lo kali.'
        : 'Pemain main $lo–$hi kali. Ubah jumlah ronde agar pembagian '
        'benar-benar sama.';
  }

  // ---------------- Buat turnamen ----------------
  Future<void> _create() async {
    if (_isKnockout) {
      await _createKnockout();
    } else {
      await _createRoundRobin();
    }
  }

  Future<void> _createRoundRobin() async {
    final name = _nameCtrl.text.trim();
    if (_players.length < 4) {
      showMessage(context, 'Minimal 4 pemain.', isError: true);
      return;
    }
    final maxC = AmericanoScheduler.maxCourts(_players.length);
    final courts = int.tryParse(_courtsCtrl.text.trim()) ?? 0;
    final rounds = int.tryParse(_roundsCtrl.text.trim()) ?? 0;
    if (courts < 1 || courts > maxC) {
      showMessage(context,
          'Jumlah lapangan harus 1–$maxC untuk ${_players.length} pemain.',
          isError: true);
      return;
    }
    if (rounds < 1 || rounds > 50) {
      showMessage(context, 'Jumlah ronde harus 1–50.', isError: true);
      return;
    }

    setState(() => _saving = true);
    final base = DateTime.now().microsecondsSinceEpoch;
    final players = [
      for (var i = 0; i < _players.length; i++)
        TPlayer(id: 'p${base}_$i', name: _players[i]),
    ];
    final matches = _format == TournamentFormat.mexicano
        ? MexicanoScheduler.firstRound(players, courts) // ronde lain menyusul
        : AmericanoScheduler.generate(
        players: players, courts: courts, rounds: rounds);

    final t = Tournament(
      id: 't$base',
      name: name,
      format: _format,
      targetPoints: _target,
      courts: courts,
      totalRounds: rounds,
      rankByWins: _rankByWins,
      createdAt: DateTime.now(),
      finished: false,
      players: players,
      matches: matches,
    );
    await TournamentStore.upsert(_uid, t);
    if (!mounted) return;
    Navigator.pop(context, t);
  }

  Future<void> _createKnockout() async {
    if (_teams.length < 2) {
      showMessage(context, 'Minimal 2 tim.', isError: true);
      return;
    }
    setState(() => _saving = true);

    final base = DateTime.now().microsecondsSinceEpoch;
    final order = List<List<String>>.of(_teams);
    if (_shuffleBracket) order.shuffle(Random());

    final players = <TPlayer>[];
    final teamIds = <List<String>>[];
    var k = 0;
    for (final team in order) {
      final ids = <String>[];
      for (final nm in team) {
        final id = 'p${base}_${k++}';
        players.add(TPlayer(id: id, name: nm));
        ids.add(id);
      }
      teamIds.add(ids);
    }

    final third = _thirdPlace && _teams.length >= 4;
    final matches = KnockoutLogic.build(teamIds, thirdPlace: third);
    final rounds =
    KnockoutLogic.totalRounds(KnockoutLogic.bracketSize(teamIds.length));

    final t = Tournament(
      id: 't$base',
      name: _nameCtrl.text.trim(),
      format: _format,
      targetPoints: _target,
      courts: 1,
      totalRounds: rounds,
      rankByWins: false,
      createdAt: DateTime.now(),
      finished: false,
      players: players,
      matches: matches,
    );
    await TournamentStore.upsert(_uid, t);
    if (!mounted) return;
    Navigator.pop(context, t);
  }

  // ---------------- UI ----------------
  String get _title {
    switch (_step) {
      case 0:
        return 'Pilih Format';
      case 1:
        return 'Nama Turnamen';
      default:
        return _isKnockout ? 'Tim & Pengaturan' : 'Pemain & Pengaturan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.pink.shade300,
          foregroundColor: Colors.white,
          title: Text(_title),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey(_step), child: _body()),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case 0:
        return _buildFormatStep();
      case 1:
        return _buildNameStep();
      default:
        return _isKnockout ? _buildKnockoutStep() : _buildSettingsStep();
    }
  }

  // ----- Langkah 1: pilih format -----
  Widget _buildFormatStep() {
    void pick(String f) => setState(() {
      _format = f;
      _step = 1;
    });
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Mau main dengan format apa?',
            style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 12),
        _FormatCard(
          icon: Icons.shuffle,
          title: 'Americano',
          desc: 'Ganti pasangan setiap ronde. Tiap pemain mengumpulkan poin '
              'sendiri-sendiri, lalu dibuat leaderboard.',
          onTap: () => pick(TournamentFormat.americano),
        ),
        _FormatCard(
          icon: Icons.swap_vert,
          title: 'Mexicano',
          desc: 'Ronde 1 diacak. Ronde berikutnya dibentuk ulang dari '
              'peringkat saat itu, jadi lawannya makin seimbang.',
          onTap: () => pick(TournamentFormat.mexicano),
        ),
        _FormatCard(
          icon: Icons.account_tree_outlined,
          title: 'Knockout',
          desc: 'Tim tetap berdua, sistem gugur: kalah langsung tersingkir '
              'sampai tersisa satu juara.',
          onTap: () => pick(TournamentFormat.knockout),
        ),
      ],
    );
  }

  // ----- Langkah 2: nama turnamen -----
  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text('🏆', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          const Text('Nama Turnamen',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(TournamentFormat.label(_format),
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _nextFromName(),
            decoration: _dec('Nama turnamen', hint: 'Mis. Thursday Padel'),
          ),
          const Spacer(),
          PrimaryButton(label: 'Lanjut', onPressed: _nextFromName),
        ],
      ),
    );
  }

  void _nextFromName() {
    if (_nameCtrl.text.trim().isEmpty) {
      showMessage(context, 'Nama turnamen wajib diisi.', isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _step = 2);
  }

  // ----- Langkah 3 (Americano & Mexicano): pemain + pengaturan -----
  Widget _buildSettingsStep() {
    final isMex = _format == TournamentFormat.mexicano;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${_nameCtrl.text.trim()} · ${TournamentFormat.label(_format)}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 16),
        const Text('Pemain',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _playerCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: _addName,
                decoration: _dec('Nama pemain'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style:
              IconButton.styleFrom(backgroundColor: Colors.pink.shade300),
              onPressed: () => _addName(_playerCtrl.text),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Pemain terpilih',
                style: TextStyle(color: Colors.grey.shade700)),
            const Spacer(),
            Text('${_players.length}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Icon(Icons.group_outlined, size: 18),
          ],
        ),
        const SizedBox(height: 8),
        if (_players.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Belum ada pemain',
                style: TextStyle(color: Colors.grey.shade500)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in _players)
                InputChip(label: Text(p), onDeleted: () => _removeName(p)),
            ],
          ),
        if (_suggested.any((s) => !_players.contains(s))) ...[
          const SizedBox(height: 12),
          Text('Saran pemain', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final s in _suggested)
                if (!_players.contains(s))
                  ActionChip(
                    avatar: const Icon(Icons.person_add_alt_1, size: 16),
                    label: Text(s),
                    onPressed: () => _addName(s),
                  ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        const Text('Pengaturan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _pointsDropdown(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _numField(
                _courtsCtrl,
                'Jumlah lapangan',
                helper: 'Maks ${AmericanoScheduler.maxCourts(_players.length)}',
                onChanged: (_) => setState(_syncRounds),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _numField(
                _roundsCtrl,
                'Jumlah ronde',
                helper: 'Saran: $_suggestedRounds',
                onChanged: (_) => setState(() => _roundsTouched = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Dropdown<bool>(
          icon: Icons.leaderboard_outlined,
          label: 'Peringkat berdasarkan',
          value: _rankByWins,
          items: const [false, true],
          text: (v) => v ? 'Kemenangan (lalu poin)' : 'Total poin',
          onChanged: (v) => setState(() => _rankByWins = v),
        ),
        const SizedBox(height: 10),
        _infoBox(Icons.balance, _fairText),
        if (isMex) ...[
          const SizedBox(height: 8),
          _infoBox(
              Icons.info_outline,
              'Ronde 1 diacak. Ronde berikutnya dibuat otomatis dari '
                  'peringkat setelah semua skor ronde sebelumnya terisi.'),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Buat & Mulai',
          loading: _saving,
          onPressed: _create,
        ),
      ],
    );
  }

  // ----- Langkah 3 (Knockout): tim + pengaturan -----
  Widget _buildKnockoutStep() {
    final size = _teams.length < 2 ? 0 : KnockoutLogic.bracketSize(_teams.length);
    final byes = size == 0 ? 0 : size - _teams.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${_nameCtrl.text.trim()} · ${TournamentFormat.label(_format)}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 16),
        const Text('Tim',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _p1Ctrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: _dec('Pemain 1'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _p2Ctrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTeam(),
                decoration: _dec('Pemain 2'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style:
              IconButton.styleFrom(backgroundColor: Colors.pink.shade300),
              onPressed: _addTeam,
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Tim terdaftar',
                style: TextStyle(color: Colors.grey.shade700)),
            const Spacer(),
            Text('${_teams.length}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Icon(Icons.groups_outlined, size: 18),
          ],
        ),
        const SizedBox(height: 8),
        if (_teams.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Belum ada tim',
                style: TextStyle(color: Colors.grey.shade500)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var i = 0; i < _teams.length; i++)
                InputChip(
                  label: Text('${i + 1}. ${_teams[i][0]} & ${_teams[i][1]}'),
                  onDeleted: () => setState(() => _teams.removeAt(i)),
                ),
            ],
          ),
        const SizedBox(height: 24),
        const Text('Pengaturan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _pointsDropdown(),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.pink.shade400,
          title: const Text('Acak undian bagan'),
          subtitle: const Text(
              'Mati = urutan input jadi seed (tim pertama paling unggul).',
              style: TextStyle(fontSize: 12)),
          value: _shuffleBracket,
          onChanged: (v) => setState(() => _shuffleBracket = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.pink.shade400,
          title: const Text('Perebutan juara 3'),
          subtitle: Text(
              _teams.length >= 4
                  ? 'Dua tim yang kalah di semifinal bertanding.'
                  : 'Butuh minimal 4 tim.',
              style: const TextStyle(fontSize: 12)),
          value: _thirdPlace && _teams.length >= 4,
          onChanged: _teams.length >= 4
              ? (v) => setState(() => _thirdPlace = v)
              : null,
        ),
        const SizedBox(height: 8),
        _infoBox(
          Icons.account_tree_outlined,
          _teams.length < 2
              ? 'Tambahkan minimal 2 tim.'
              : 'Bagan $size slot · ${KnockoutLogic.totalRounds(size)} babak'
              '${byes > 0 ? ' · $byes tim dapat BYE (lolos otomatis)' : ''}.',
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Buat & Mulai',
          loading: _saving,
          onPressed: _create,
        ),
      ],
    );
  }

  // ---------------- Widget bantu ----------------
  Widget _pointsDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Dropdown<int>(
          icon: Icons.flag_outlined,
          label: 'Poin kemenangan',
          value: _target,
          items: _targets,
          text: (v) => 'Lebih dulu sampai $v poin',
          onChanged: (v) => setState(() => _target = v),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
          child: Text(
            'Tim yang lebih dulu mencapai $_target poin memenangkan pertandingan.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _infoBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.pink.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.pink.shade400),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _numField(TextEditingController c, String label,
      {String? helper, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: _dec(label).copyWith(helperText: helper),
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

// =====================================================================
class _FormatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _FormatCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: Colors.pink.shade50, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.pink.shade400),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(desc,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) text;
  final ValueChanged<T> onChanged;

  const _Dropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.pink.shade300),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          items: [
            for (final e in items)
              DropdownMenuItem<T>(value: e, child: Text(text(e))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}