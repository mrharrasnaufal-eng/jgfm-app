# JagatFilm - Flutter Android App

Aplikasi streaming drama native Android menggunakan Flutter + better_player.

## Fitur
- ✅ Browse drama dari 15+ provider (15000+ judul)
- ✅ Streaming video HLS dengan quality switcher (HD/SD)
- ✅ Subtitle multi-bahasa
- ✅ Search drama
- ✅ Filter per provider
- ✅ Infinite scroll / pagination
- ✅ Login / Register
- ✅ Profil pengguna
- ✅ Dark theme UI modern

## Arsitektur
```
lib/
├── main.dart                # Entry point + routing
├── models/
│   ├── drama.dart           # Drama, DramaDetail, EpisodeInfo, StreamData
│   └── user.dart            # User model
├── services/
│   ├── api_service.dart     # HTTP calls ke jagatfilm.com API
│   └── auth_service.dart    # Auth + session management
├── screens/
│   ├── home_screen.dart     # Homepage + featured + grid
│   ├── detail_screen.dart   # Detail drama + episode list
│   ├── search_screen.dart   # Search dengan debounce
│   ├── login_screen.dart    # Login / Register form
│   ├── profile_screen.dart  # User profile
│   └── player_screen.dart   # Video player (better_player + HLS)
└── widgets/
    └── drama_card.dart      # Card reusable untuk grid
```

## API Endpoints (dari jagatfilm.com)
| Endpoint | Method | Params | Deskripsi |
|----------|--------|--------|-----------|
| `/api/dramas` | GET | page, limit, provider, q | List drama + search |
| `/api/stream` | GET | id, episode | Get stream URL (HLS/MP4) |
| `/api/hls` | GET | url, drmToken | HLS proxy (bypass CORS) |
| `/api/img` | GET | url | Image proxy |
| `/api/subtitle` | GET | url | Subtitle proxy |

## Cara Build APK

### Prasyarat
1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.0.0)
2. Install [Android Studio](https://developer.android.com/studio) + Android SDK
3. Atau gunakan `sdkmanager` untuk command-line tools

### Build Steps

```bash
# 1. Masuk ke folder project
cd apk

# 2. Get dependencies
flutter pub get

# 3. Build APK (release)
flutter build apk --release

# APK output: build/app/outputs/flutter-apk/app-release.apk

# 4. Atau build debug APK (lebih cepat, untuk testing)
flutter build apk --debug
```

### Build APK Split per ABI (file lebih kecil)
```bash
flutter build apk --split-per-abi --release
# Output:
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   (~15MB, untuk HP modern)
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (~13MB, untuk HP lama)
```

## Catatan Teknis
- Video streaming melalui proxy HLS di `jagatfilm.com/api/hls` untuk bypass CORS
- Image di-proxy via `jagatfilm.com/api/img` karena beberapa CDN provider memblokir akses langsung
- Auth backend di port 3001 (mungkin perlu dinyalakan terpisah)
- `better_player` menggunakan ExoPlayer untuk Android (support HLS native)

## Troubleshooting
- Jika build gagal karena `minSdk`, pastikan sudah set `minSdk 21` di `android/app/build.gradle`
- Jika video tidak mau play, cek koneksi internet dan pastikan proxy jagatfilm.com aktif
- Untuk debug network: gunakan `flutter run --verbose`
