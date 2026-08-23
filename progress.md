# LOG PEKERJAAN - APK JagatFilm (Flutter Android)
## Tanggal: 22 Agustus 2026

---

## STATUS: AUTO DEPLOY AKTIF ✅ — SIGNED RELEASE APK

---

## LINK & REPO:
- **GitHub Repo:** https://github.com/mrharrasnaufal-eng/jgfm-app
- **GitHub Actions:** https://github.com/mrharrasnaufal-eng/jgfm-app/actions
- **APK URL:** https://jagatfilm.com/download/app-release.apk
- **Version JSON:** https://jagatfilm.com/app/version.json
- **Halaman Download:** https://jagatfilm.com/download/
- **Build type:** Signed Release (keystore configured)

---

## SIGNING KEY:
- **Keystore file:** `/root/android-keystore/upload-keystore.jks`
- **Alias:** `jagatfilm`
- **Password:** `JgFm2026SecureKey!` (store & key sama)
- **Validity:** 10000 hari (~27 tahun)
- **SHA-256:** `4D:8B:D0:BF:8F:22:5E:B5:1B:F6:1A:19:27:61:44:E6:32:9E:CA:6B:7D:F6:8F:70:29:8C:7F:5B:33:0E:3E:EC`
- **⚠️ JANGAN HAPUS FILE KEYSTORE! Jika hilang, user harus uninstall app.**

### GitHub Secrets (sudah diisi):
| Secret | Nilai |
|--------|-------|
| ANDROID_KEYSTORE_BASE64 | Base64 encoded keystore |
| ANDROID_KEYSTORE_PASSWORD | JgFm2026SecureKey! |
| ANDROID_KEY_ALIAS | jagatfilm |
| ANDROID_KEY_PASSWORD | JgFm2026SecureKey! |

---

## ALUR DEPLOY (OTOMATIS):
```
Push ke main → GitHub Actions build APK → SCP upload ke aaPanel → version.json auto update → App cek update saat dibuka
```

### GitHub Secrets yang dibutuhkan:
| Secret | Nilai |
|--------|-------|
| AAPANEL_HOST | IP server |
| AAPANEL_PORT | SSH port (22) |
| AAPANEL_USER | root |
| AAPANEL_SSH_KEY | Private key SSH |
| AAPANEL_DEPLOY_PATH | /www/wwwroot/jagatfilm.com |

---

## SEMUA YANG SUDAH DIKERJAKAN:

### 1. Analisis Website & API ✅
- Website live: https://jagatfilm.com (Next.js 16)
- API:
  - `GET /api/dramas` — List + search (page, limit, provider, q)
  - `GET /api/stream` — Stream URL (id, episode)
  - `GET /api/hls?url=` — HLS proxy
  - `GET /api/img?url=` — Image proxy
  - `GET /api/subtitle?url=` — Subtitle proxy
- Format ID: `{source}-{sourceId}`
- Data: 15000+ drama, 15+ provider

### 2. Project Flutter ✅
- Lokasi server: `/www/wwwroot/jagatfilm.com/apk/`
- Package ID: `com.jagatfilm.app`
- Version: `1.0.0+1`
- Min SDK: 21, Target SDK: 34

### 3. Dependencies (FINAL) ✅
```yaml
http: 1.2.1
cached_network_image: 3.3.1
video_player: 2.9.2
chewie: 1.8.5
google_sign_in: 6.2.1
shared_preferences: 2.2.3
provider: 6.1.2
shimmer: 3.0.0
flutter_staggered_grid_view: 0.7.0
url_launcher: 6.2.6
package_info_plus: 8.0.2
```

### 4. Screens/Halaman ✅
| Screen | File | Deskripsi |
|--------|------|-----------|
| Home | `home_screen.dart` | Grid drama, featured slider, filter provider, infinite scroll, cek update |
| Detail | `detail_screen.dart` | Info drama, genre tags, daftar episode |
| Search | `search_screen.dart` | Pencarian debounce 500ms |
| Player | `player_screen.dart` | Portrait fullscreen 9:16, Chewie, swipe episode, debug panel |
| Login | `login_screen.dart` | Google Sign In + Email/Password, SafeArea |
| Profile | `profile_screen.dart` | Info user, VIP badge, logout |

### 5. Fitur Video Player (Portrait) ✅
- **Portrait fullscreen** — Aspect ratio 9:16 (video vertikal)
- **Immersive mode** — Status bar tersembunyi
- **Swipe down** → next episode
- **Swipe up** → prev episode
- **HD/SD toggle** — Ganti kualitas
- **Debug panel** — Klik icon bug untuk lihat URL
- **HTTP headers** — User-Agent + Referer
- **URL handling:**
  - `.mp4` → direct play
  - `.m3u8` → lewat proxy `/api/hls`
- **Error handling** — Retry, switch quality, next episode

### 6. Fitur Auth ✅
- **Google Sign In** — Tombol di halaman login (butuh SHA-1 config)
- **Email/Password** — Register & login manual
- **Local fallback** — Jika backend down, auth lokal via SharedPreferences
- **Error handling** — ApiException 10 ditangani dengan pesan user-friendly

### 7. Fitur Self-Update ✅
- Cek `https://jagatfilm.com/app/version.json` saat app dibuka
- Dialog update jika versionCode server > app
- `force_update: true` → dialog tidak bisa ditutup
- Tombol "Update Sekarang" → buka browser download APK
- Error tidak crash app

### 8. CI/CD Auto Deploy ✅
- File: `.github/workflows/build-apk.yml`
- Steps:
  1. Checkout source
  2. Setup Java 17 + Flutter stable
  3. Regenerate Android project
  4. Restore config (internet permission, minSdk)
  5. `flutter pub get`
  6. `flutter analyze --no-fatal-infos --no-fatal-warnings`
  7. `flutter build apk --debug`
  8. Generate `version.json` dari `pubspec.yaml`
  9. Upload artifacts
  10. SCP deploy ke aaPanel
  11. SSH move files ke path benar

### 9. Nginx Config ✅
- `/app/` → serve `version.json` langsung (no-cache)
- `/download/` → serve APK langsung (no-cache, Content-Disposition attachment)

---

## HISTORY COMMIT:
| # | Hash | Pesan |
|---|------|-------|
| 1 | 8c00266 | initial flutter app |
| 2 | f606d7d | add github actions apk build |
| 3 | 5e12819 | fix flutter analyze errors |
| 4 | 8d28bd6 | fix flutter gradle plugin configuration |
| 5 | cd795a2 | regenerate android project in github actions |
| 6 | 819966b | replace better_player with chewie video player |
| 7 | 9eaa32f | fix: fullscreen player with swipe navigation + local auth fallback |
| 8 | 6157d49 | feat: add google sign in + email/password auth |
| 9 | 526e218 | fix video player source error and overflow |
| 10 | 1e4c805 | add self update checker |
| 11 | 3e3ccfc | fix app errors portrait video and auto apk deploy |
| 12 | e3a4603 | add signed release APK support with fallback debug |
| 13 | d036b6b | use signed release APK build with secrets |

---

## MASALAH YANG SUDAH DISELESAIKAN:

| # | Error | Solusi |
|---|-------|--------|
| 1 | CardTheme type mismatch | `CardTheme()` → `CardThemeData()` |
| 2 | Flutter Gradle Plugin lama | Regenerate android/ di CI |
| 3 | better_player namespace error | Ganti ke video_player + chewie |
| 4 | ApiException: 10 (Google) | User-friendly message, tidak crash |
| 5 | ExoPlaybackException Source error | httpHeaders, detect MP4 vs HLS |
| 6 | BOTTOM OVERFLOWED 26 PIXELS | SafeArea, Expanded, SingleChildScrollView |
| 7 | type 'String' not subtype 'int' | `_parseInt()` helper di model |
| 8 | Video landscape (salah) | Portrait lock + aspectRatio 9:16 |

---

## ARSITEKTUR FINAL:
```
lib/
├── main.dart                    → Entry point, portrait lock, theme
├── models/
│   ├── drama.dart               → Drama, DramaDetail, EpisodeInfo, StreamData (safe parsing)
│   └── user.dart                → User model
├── services/
│   ├── api_service.dart         → HTTP calls ke jagatfilm.com/api/*
│   ├── auth_service.dart        → Google + Email auth + local fallback
│   └── update_service.dart      → Self-update checker dari version.json
├── screens/
│   ├── home_screen.dart         → Homepage + trigger update check
│   ├── detail_screen.dart       → Detail drama + episode list
│   ├── search_screen.dart       → Search debounce
│   ├── player_screen.dart       → Portrait video player + swipe
│   ├── login_screen.dart        → Google + Email login/register
│   └── profile_screen.dart      → User profile
└── widgets/
    └── drama_card.dart          → Reusable card
```

---

## CARA UPDATE APP KE VERSI BARU:

### 1. Edit code di server:
```bash
cd /www/wwwroot/jagatfilm.com/apk
# Edit file di lib/
```

### 2. Update version di pubspec.yaml:
```yaml
version: 1.0.1+2   # format: name+code
```

### 3. Commit & push:
```bash
git add .
git commit -m "deskripsi perubahan"
git remote set-url origin https://TOKEN@github.com/mrharrasnaufal-eng/jgfm-app.git
git push
git remote set-url origin https://github.com/mrharrasnaufal-eng/jgfm-app.git
```

### 4. Otomatis:
- GitHub Actions build APK
- Upload ke `/www/wwwroot/jagatfilm.com/download/app-release.apk`
- Update `/www/wwwroot/jagatfilm.com/app/version.json`
- User buka app → dapat notif update

### 5. Manual (jika auto deploy belum setup secrets):
- Download dari GitHub Actions → Artifacts
- `cp app-debug.apk /www/wwwroot/jagatfilm.com/download/app-release.apk`
- Edit `/www/wwwroot/jagatfilm.com/app/version.json`

---

## ⚠️ CATATAN PENTING:
1. **APK saat ini DEBUG** — belum signed. Untuk Play Store perlu keystore.
2. **Google Sign In** butuh SHA-1 didaftarkan di Google Cloud Console.
3. **Auth backend (port 3001)** tidak jalan — app pakai local auth.
4. **Video streaming** bergantung proxy jagatfilm.com — website harus online.
5. **Jangan switch debug→release** tanpa peringatan ke user (signature beda, perlu uninstall).
6. **GitHub Secrets** harus di-set di repo Settings → Secrets untuk auto deploy.
7. **Semua video drama vertikal** — player sudah portrait 9:16.

---

## QUICK START SESSION BERIKUTNYA:
1. Source: `/www/wwwroot/jagatfilm.com/apk/`
2. Repo: https://github.com/mrharrasnaufal-eng/jgfm-app
3. Edit → commit → push → otomatis deploy
4. Version control: ubah `version:` di `pubspec.yaml`
5. Monitor build: https://github.com/mrharrasnaufal-eng/jgfm-app/actions

---

## YANG BISA DITINGKATKAN:
1. **Release signing** — Buat keystore untuk production APK
2. **Google Sign In config** — Daftarkan SHA-1 di Google Cloud Console
3. **Backend auth** — Nyalakan atau buat endpoint auth baru di jagatfilm.com
4. **Offline cache** — SQLite drama list
5. **Download episode** — Simpan video offline
6. **History tontonan** — Progress per episode
7. **Favorit/Bookmark** — Simpan drama
8. **Custom app icon** — Buat launcher icon
9. **Splash screen** — Branded splash
10. **Deep linking** — Buka drama dari URL
