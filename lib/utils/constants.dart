class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  static const double card = 12;
  static const double pill = 16;
  static const double button = 8;
  static const double avatar = 50;
}

class AppFontSize {
  static const double h1 = 24;
  static const double h2 = 20;
  static const double h3 = 16;
  static const double body = 14;
  static const double caption = 12;
  static const double micro = 10;
}

class AppStrings {
  static const String appName = 'JagatFilm';
  static const String tabUntukmu = 'Untukmu';
  static const String tabTerbaru = 'Terbaru';
  static const String tabPeringkat = 'Peringkat';
  static const String tabKategori = 'Kategori';
  static const String navBeranda = 'Beranda';
  static const String navUntukAnda = 'Untuk Anda';
  static const String navKoin = 'Koin';
  static const String navDaftarku = 'Daftarku';
  static const String navProfil = 'Profil';
  static const String errorLoad = 'Gagal memuat data';
  static const String retry = 'Coba Lagi';
  static const String emptyState = 'Belum ada data';
  static const String segataHadir = 'Segera Hadir';
  static const String allProvider = 'Semua';
  static const String sortPopular = 'Terpopuler';
  static const String sortNewest = 'Terbaru';
}

/// Format view count to human readable (1542 → "1.5K", 1542000 → "1.5M")
String formatViews(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
  if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}K';
  }
  return count.toString();
}
