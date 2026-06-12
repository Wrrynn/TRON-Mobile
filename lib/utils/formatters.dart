import 'package:intl/intl.dart';

/// Helper format tampilan (rupiah & tanggal).
class Format {
  Format._();

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String rupiah(int amount) => _rupiah.format(amount);

  /// Ubah "2026-06-04" menjadi "4 Jun 2026". Mengembalikan input apa adanya bila gagal.
  static String tanggal(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final date = DateTime.parse(iso);
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return iso;
    }
  }
}
