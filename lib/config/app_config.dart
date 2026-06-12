/// Konfigurasi global aplikasi (titik tunggal untuk mengubah environment).
class AppConfig {
  AppConfig._();

  /// Base URL API Laravel Tripmo.
  ///
  /// - Produksi (Vercel):       https://tripmo-jade.vercel.app/api
  /// - Emulator Android lokal:  http://10.0.2.2:8000/api  (host `php artisan serve`)
  /// - iOS simulator / web:     http://127.0.0.1:8000/api
  ///
  /// Ganti sesuai target. Default memakai server produksi agar langsung jalan.
  static const String baseUrl = 'https://tripmo-jade.vercel.app/api';

  /// Jumlah item per halaman saat memuat feed.
  static const int feedPerPage = 20;

  /// Timeout default untuk request HTTP.
  static const Duration requestTimeout = Duration(seconds: 20);
}
