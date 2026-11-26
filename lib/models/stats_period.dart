// Pilihan periode untuk statistik pesanan. Periode dihitung dari TANGGAL MAIN.
enum StatsPeriod { all, last7, last30, thisMonth }

extension StatsPeriodX on StatsPeriod {
  String get label {
    switch (this) {
      case StatsPeriod.last7:
        return '7 hari terakhir';
      case StatsPeriod.last30:
        return '30 hari terakhir';
      case StatsPeriod.thisMonth:
        return 'Bulan ini';
      case StatsPeriod.all:
        return 'Semua';
    }
  }

  DateTime? get from {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    switch (this) {
      case StatsPeriod.last7:
        return today.subtract(const Duration(days: 6));
      case StatsPeriod.last30:
        return today.subtract(const Duration(days: 29));
      case StatsPeriod.thisMonth:
        return DateTime(n.year, n.month, 1);
      case StatsPeriod.all:
        return null;
    }
  }

  DateTime? get to {
    final n = DateTime.now();
    switch (this) {
      case StatsPeriod.last7:
      case StatsPeriod.last30:
        return DateTime(n.year, n.month, n.day);
      case StatsPeriod.thisMonth:
        return DateTime(n.year, n.month + 1, 0); // hari terakhir bulan ini
      case StatsPeriod.all:
        return null;
    }
  }
}