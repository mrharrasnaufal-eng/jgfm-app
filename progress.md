# LOG PEKERJAAN - APK JagatFilm (Flutter Android)
## Tanggal: 22 Agustus 2026

---

## STATUS: BUILD BERHASIL ✅ — APK TERSEDIA

- **Artifact:** https://github.com/mrharrasnaufal-eng/jgfm-app/actions/runs/32603712311/artifacts/9483635275

---

## LINK & REPO:
- **GitHub Repo:** https://github.com/mrharrasnaufal-eng/jgfm-app
- **GitHub Actions:** https://github.com/mrharrasnaufal-eng/jgfm-app/actions
- **Halaman Download:** https://jagatfilm.com/download/
- **Direct APK:** https://jagatfilm.com/download/jagatfilm-v1.0.0.apk (belum diisi, nanti copy dari Actions artifacts)

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

### 3. Dependencies (FINAL) ✅
- ~~`better_player: 0.0.84`~~ ❌ DIHAPUS - Tidak kompatibel AGP terbaru
- `video_player: 2.9.2` — Video player (ExoPlayer di Android, support HLS)
- `chewie: 1.8.5` — UI controls untuk video_player
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
| Player | `lib/screens/player_screen.dart` | Chewie + video_player, HD/SD toggle, episode navigation |
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

### 6. GitHub Actions CI/CD ✅
- File: `.github/workflows/build-apk.yml`
- Trigger: push ke `main` atau manual (workflow_dispatch)
- Steps:
  1. Checkout source
  2. Setup Flutter (stable channel)
  3. **Regenerate Android project** (`flutter create --platforms=android --org com.jagatfilm .`)
  4. Install dependencies (`flutter pub get`)
  5. Analyze (`flutter analyze --no-fatal-infos --no-fatal-warnings`)
  6. Build debug APK (`flutter build apk --debug`)
  7. Upload artifact (`app-debug-apk`)

### 7. Halaman Download Web ✅
- Nginx dikonfigurasi serve `/download/` langsung (bukan proxy ke Next.js)
- Halaman HTML di `/www/wwwroot/jagatfilm.com/download/index.html`
- UI: Dark theme, info app, tombol download, fitur list

---

## HISTORY COMMIT:
| # | Commit | Pesan | Isi |
|---|--------|-------|-----|
| 1 | 8c00266 | initial flutter app | 31 files, semua source code |
| 2 | f606d7d | add github actions apk build | Workflow pertama |
| 3 | 5e12819 | fix flutter analyze errors | CardTheme → CardThemeData, analyze flags |
| 4 | 8d28bd6 | fix flutter gradle plugin configuration | Rewrite Gradle files format baru |
| 5 | cd795a2 | regenerate android project in github actions | Tambah step rm android + flutter create |
| 6 | 819966b | replace better_player with chewie video player | Ganti ke video_player + chewie |

---

## MASALAH YANG SUDAH DISELESAIKAN:

### Error 1: CardTheme type mismatch ✅
- **Masalah:** `CardTheme` tidak bisa di-assign ke `CardThemeData?` (Flutter terbaru)
- **Solusi:** Ganti `CardTheme(...)` → `CardThemeData(...)` di `lib/main.dart`

### Error 2: Flutter Gradle Plugin lama ✅
- **Masalah:** `android/app/build.gradle` pakai format imperative lama, Flutter terbaru butuh plugins block
- **Solusi:** Regenerate folder android di CI dengan `flutter create --platforms=android --org com.jagatfilm .`

### Error 3: better_player namespace error ✅
- **Masalah:** `better_player 0.0.84` tidak set namespace, tidak kompatibel AGP terbaru
- **Solusi:** Hapus better_player, ganti dengan `video_player` + `chewie`

---

## CARA DOWNLOAD APK (SETELAH BUILD BERHASIL):
1. Buka: https://github.com/mrharrasnaufal-eng/jgfm-app/actions
2. Klik run terbaru yang ✅ hijau
3. Scroll ke bawah → **Artifacts**
4. Download **app-debug-apk**
5. (Opsional) Copy ke server: `cp app-debug.apk /www/wwwroot/jagatfilm.com/download/jagatfilm-v1.0.0.apk`

---

## ⚠️ CATATAN PENTING:
1. **Flutter SDK TIDAK ada di server ini** — build dilakukan oleh GitHub Actions
2. **Android folder di-regenerate saat build** — jangan edit android/ langsung, akan ditimpa
3. **Auth backend (port 3001)** mungkin tidak jalan — login akan gagal tapi app tetap bisa browse & streaming
4. **Video streaming** bergantung pada proxy jagatfilm.com/api/hls — website harus tetap online
5. **Image** di-proxy via jagatfilm.com/api/img — jangan hapus route ini di website
6. **HLS playback** — video_player di Android menggunakan ExoPlayer yang support HLS native

---

## QUICK START Session Berikutnya:
1. Source code: `/www/wwwroot/jagatfilm.com/apk/`
2. Repo: https://github.com/mrharrasnaufal-eng/jgfm-app
3. Untuk edit: ubah file di `lib/`, commit, push → Actions auto-build
4. Untuk download APK: GitHub → Actions → Artifacts
5. Untuk trigger build manual: GitHub → Actions → Run workflow

---

## YANG BISA DITINGKATKAN:
1. **Release APK** — Tambah signing key untuk production build
2. **Offline mode** — Cache drama list ke SQLite lokal
3. **Download episode** — Download video untuk ditonton offline
4. **Push notification** — Drama baru / update episode
5. **History** — Riwayat tontonan + progress per episode
6. **Favorit/Bookmark** — Simpan drama favorit
7. **Splash screen** — Custom splash dengan logo JagatFilm
8. **App icon** — Custom launcher icon
9. **Deep linking** — Buka drama dari URL jagatfilm.com/drama/[id]
10. **Auto-update** — Check versi terbaru dari server
11. **Subtitle overlay** — Tambah subtitle rendering di player
