/// Holder global untuk base URL dari remote config (opsi a sentralisasi domain).
///
/// Diisi oleh main.dart setelah fetch remote config sukses. Default memakai
/// domain produksi, jadi app tetap jalan walau config belum ter-fetch.
class AppConfig {
  AppConfig._();

  /// Base URL API data (dramas/stream/img/subtitle).
  static String apiBaseUrl = 'https://jagatfilm.com';

  /// Base URL admin/panel (notifikasi).
  static String adminBaseUrl = 'https://masterpanel.jagatfilm.com';
}
