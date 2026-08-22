# LOG PEKERJAAN - APK JagatFilm (Flutter Android)
## Tanggal: 22 Agustus 2026

---

## STATUS: PROJECT SIAP BUILD ✅ (Flutter SDK diperlukan)

---

## APA YANG SUDAH DIKERJAKAN:

### 1. Analisis Website & API ✅
- Website live: https://jagatfilm.com (Next.js 16 + TypeScript)
- API Endpoints yang dipakai:
  - `GET /api/dramas` — List drama (page, limit, provider, q)
  - `GET /api/stream` — Get stream URL (id, episode)
  - `GET /api/hls?url=` — HLS proxy (bypass CORS)
  - `GET /api/img?url=` — Image proxy
  - `GET /api/subtitle?url=` — Subtitle proxy
- Auth Backend (port 3001):
  - `POST /api/auth/login` — Login (email, password)
  - `POST /api/auth/register` — Register (email, password, displayName)
  - `GET /api/auth/me` — Get profile (Bearer token)
- Data: 15000+ drama dari 15+ provider aktif
- Format ID drama: `{source}-{sourceId}` (contoh: shortmax-12345)

### 2. Setup Project Flutter ✅
- Lokasi: `/www/wwwroot/jagatfilm.com/apk/`
- Framework: Flutter >= 3.0.0
- Package ID: `com.jagatfilm.app`
- Min SDK: 21 (Android 5.0+)
- Target SDK: 34

### 3. Dependencies ✅
- `better_player: 0.0.84` — Video player HLS (ExoPlayer)
- `http: 1.2.1` — HTTP client
- `cached_network_image: 3.3.1` — Image caching
- `provider: 6.1.2` — State management
- `shared_preferences: 2.2.3` — Local storage
- `shimmer: 3.0.0` — Loading skeleton
- `flutter_staggered_grid_view: 0.7.0` — Grid layout
- `url_launcher: 6.2.6` — Open URLs

### 4. Screens/Halaman ✅
| Screen | File | Deskripsi |
|--------|------|-----------|
| Home | `lib/screens/home_screen.dart` | Featured slider, grid drama, filter provider, infinite scroll |
| Detail | `lib/screens/detail_screen.dart` | Info drama, genre tags, daftar episode |
| Search | `lib/screens/search_screen.dart` | Pencarian dengan debounce 500ms |
| Player | `lib/screens/player_screen.dart` | BetterPlayer HLS, HD/SD toggle, subtitle, navigasi episode |
| Login | `lib/screens/login_screen.dart` | Login/Register form dengan validasi |
| Profile | `lib/screens/profile_screen.dart` | Info user, VIP badge, logout |

### 5. Arsitektur ✅
```
lib/
├── main.dart              → Entry point + BottomNavigation + Theme
├── models/
│   ├── drama.dart         → Drama, DramaDetail, EpisodeInfo, StreamData, Subtitle
│   └── user.dart          → User model
├── services/
│   ├── api_service.dart   → HTTP calls ke jagatfilm.com/api/*
│   └── auth_service.dart  → Login/Register + SharedPreferences session
├── screens/               → 6 layar utama
└── widgets/
    └── drama_card.dart    → Card widget reusable
```

### 6. Konfigurasi Android ✅
- `android/build.gradle` — Project level (Kotlin 1.9.22, AGP 8.1.4)
- `android/app/build.gradle` — App level (minSdk 21, targetSdk 34, multidex, proguard)
- `android/settings.gradle` — Plugin loader
- `AndroidManifest.xml` — Internet permission, hardware acceleration, network security
- `network_security_config.xml` — HTTPS for jagatfilm.com
- `proguard-rules.pro` — Keep rules untuk Flutter + ExoPlayer
- `MainActivity.kt` — FlutterActivity
- `styles.xml` + `launch_background.xml` — Splash screen hitam

### 7. Fitur Video Player ✅
- HLS streaming via proxy `jagatfilm.com/api/hls`
- Quality switcher HD/SD
- Subtitle multi-bahasa (auto-select Indonesia)
- Fullscreen landscape support
- Episode navigation (prev/next + grid selector)
- Error handling + retry
- ExoPlayer backend (via better_player)

---

## CARA BUILD APK:

```bash
# Di mesin yang punya Flutter SDK:
cd /www/wwwroot/jagatfilm.com/apk

# 1. Get dependencies
flutter pub get

# 2. Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# 3. Atau split per arsitektur (file lebih kecil):
flutter build apk --split-per-abi --release
```

---

## LINK DOWNLOAD APK:
- **Halaman Download:** https://jagatfilm.com/download/
- **Direct APK:** https://jagatfilm.com/download/jagatfilm-v1.0.0.apk
- **File lokasi server:** `/www/wwwroot/jagatfilm.com/download/jagatfilm-v1.0.0.apk`
- **Nginx:** Sudah dikonfigurasi serve langsung (bukan proxy ke Next.js)

### Cara Update APK:
```bash
# Setelah build APK, copy ke folder download:
cp build/app/outputs/flutter-apk/app-release.apk /www/wwwroot/jagatfilm.com/download/jagatfilm-v1.0.0.apk
```

---

## ⚠️ CATATAN PENTING:
1. **Flutter SDK TIDAK ada di server ini** — perlu build di mesin lokal atau CI/CD
2. **Auth backend (port 3001)** mungkin tidak jalan — login akan gagal tapi app tetap bisa browse & streaming
3. **Video streaming** bergantung pada proxy jagatfilm.com/api/hls — website harus tetap online
4. **Image** di-proxy via jagatfilm.com/api/img — jangan hapus route ini di website

---

## QUICK START Session Berikutnya:
1. Semua source code di: `/www/wwwroot/jagatfilm.com/apk/`
2. Untuk edit UI/logic: edit file di `lib/screens/`
3. Untuk tambah fitur: tambah screen baru di `lib/screens/`, import di `main.dart`
4. Untuk build: `flutter build apk --release`
5. Untuk debug: `flutter run` (perlu device/emulator terhubung)

---

## YANG BISA DITINGKATKAN:
1. **Offline mode** — Cache drama list ke SQLite lokal
2. **Download episode** — Download video untuk ditonton offline
3. **Push notification** — Drama baru / update episode
4. **History** — Riwayat tontonan + progress per episode
5. **Favorit/Bookmark** — Simpan drama favorit
6. **Splash screen** — Custom splash dengan logo JagatFilm
7. **App icon** — Custom launcher icon (perlu file PNG)
8. **Signing key** — Buat keystore untuk release ke Play Store
9. **Deep linking** — Buka drama dari URL jagatfilm.com/drama/[id]
10. **Auto-update** — Check versi terbaru dari server
