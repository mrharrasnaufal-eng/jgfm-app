# LOG PEKERJAAN - APK JagatFilm (Flutter Android)
## Tanggal: 22-23 Agustus 2026

---

## STATUS: AUTO DEPLOY AKTIF ✅ — SIGNED RELEASE APK

---

## LINK & REPO:
- **GitHub Repo:** https://github.com/mrharrasnaufal-eng/jgfm-app
- **GitHub Actions:** https://github.com/mrharrasnaufal-eng/jgfm-app/actions
- **APK URL:** https://jagatfilm.com/download/app-release.apk
- **Version JSON:** https://jagatfilm.com/app/version.json
- **Halaman Download:** https://jagatfilm.com/download/
- **Build type:** Signed Release
- **Package name:** `com.jagatfilm.jagatfilm`

---

## SIGNING KEY:
- **Keystore file:** `/root/android-keystore/upload-keystore.jks`
- **Alias:** `jagatfilm`
- **Password:** `JgFm2026SecureKey!` (store & key sama)
- **Validity:** 10000 hari (~27 tahun)
- **SHA-256:** `4D:8B:D0:BF:8F:22:5E:B5:1B:F6:1A:19:27:61:44:E6:32:9E:CA:6B:7D:F6:8F:70:29:8C:7F:5B:33:0E:3E:EC`
- **⚠️ JANGAN HAPUS FILE KEYSTORE! Jika hilang, user harus uninstall app.**

---

## GITHUB SECRETS (SEMUA SUDAH DIISI ✅):

### Android Signing:
| Secret | Nilai |
|--------|-------|
| ANDROID_KEYSTORE_BASE64 | Base64 dari upload-keystore.jks |
| ANDROID_KEYSTORE_PASSWORD | JgFm2026SecureKey! |
| ANDROID_KEY_ALIAS | jagatfilm |
| ANDROID_KEY_PASSWORD | JgFm2026SecureKey! |

### aaPanel Deploy:
| Secret | Nilai |
|--------|-------|
| AAPANEL_HOST | 187.77.125.14 |
| AAPANEL_PORT | 22 |
| AAPANEL_USER | root |
| AAPANEL_SSH_KEY | /root/.ssh/id_rsa (sudah authorized) |
| AAPANEL_DEPLOY_PATH | /www/wwwroot/jagatfilm.com |

---

## 🚨 INSTRUKSI WAJIB — TIDAK BOLEH DILANGGAR:

### APP TIDAK BOLEH CRASH/MOGOK!

Owner (mrharrasnaufal) **sangat keberatan** dengan app yang crash. Setiap perubahan HARUS:

1. **JANGAN overwrite `build.gradle.kts` sepenuhnya** — Flutter generate file ini dengan plugin registration yang vital. Hanya INJECT signing config, jangan replace seluruh isi.

2. **JANGAN tambah dependency yang butuh native config tanpa config-nya** — Contoh: `google_sign_in` butuh `google-services.json`. Tanpa file itu = crash saat app dibuka. Kalau config belum siap, JANGAN tambahkan dependency.

3. **Semua code yang jalan saat app start HARUS di-wrap try-catch** — `main.dart`, `initState`, `loadUser`, `checkForUpdate` — semua harus safe. Error = log, BUKAN crash.

4. **JANGAN declare assets di pubspec.yaml jika folder kosong** — Flutter crash kalau asset tidak ditemukan.

5. **Test mental checklist SEBELUM push:**
   - [ ] Apakah ada import baru yang butuh native plugin tanpa config?
   - [ ] Apakah ada code yang bisa throw exception saat app start?
   - [ ] Apakah workflow mengubah file yang Flutter generate (selain inject)?
   - [ ] Apakah namespace/package name konsisten?
   - [ ] Apakah semua dependency punya versi yang kompatibel?

6. **Jika ragu, JANGAN push** — tanya dulu, jangan buang waktu owner.

### PENYEBAB CRASH YANG SUDAH TERJADI (JANGAN TERULANG):
- `google_sign_in` tanpa `google-services.json` → CRASH
- Overwrite `build.gradle.kts` → hilangkan plugin resolution → CRASH
- Empty assets folder declared di pubspec → CRASH
- Namespace mismatch → CRASH
- `package_info_plus` dipanggil tanpa try-catch → potential CRASH

### ATURAN WORKFLOW:
- `flutter create` generate android/ → **JANGAN hapus/replace file apapun kecuali inject signing**
- Signing: buat `key.properties` + inject via Python (append, bukan replace)
- Internet permission: tambah via sed JIKA belum ada
- Itu saja. Jangan sentuh yang lain.

---
```
Push ke main → GitHub Actions → Build signed APK → SCP ke aaPanel → version.json auto update → App cek update saat dibuka
```

---

## DEPENDENCIES (FINAL - tanpa google_sign_in):
```yaml
http: 1.2.1
cached_network_image: 3.3.1
video_player: 2.9.2
chewie: 1.8.5
shared_preferences: 2.2.3
provider: 6.1.2
shimmer: 3.0.0
flutter_staggered_grid_view: 0.7.0
url_launcher: 6.2.6
package_info_plus: 8.0.2
```

**TIDAK ADA:**
- ~~google_sign_in~~ → DICABUT karena crash tanpa google-services.json
- ~~better_player~~ → DICABUT karena tidak kompatibel AGP terbaru
- ~~assets/images/~~ → DIHAPUS karena folder kosong bisa crash

---

## GOOGLE SIGN IN — DICABUT (SEMENTARA):

### Alasan:
Package `google_sign_in` register native plugin saat app start. Tanpa `google-services.json` yang di-embed di APK, app langsung crash bahkan sebelum user lihat tampilan.

### Cara mengembalikan nanti:
1. Buat project di Firebase Console (https://console.firebase.google.com)
2. Daftarkan app Android: package name `com.jagatfilm.jagatfilm`
3. Daftarkan SHA-1 fingerprint keystore:
   ```bash
   keytool -list -v -keystore /root/android-keystore/upload-keystore.jks -storepass 'JgFm2026SecureKey!'
   ```
4. Download `google-services.json` dari Firebase
5. Encode: `base64 -w 0 google-services.json > google-services-base64.txt`
6. Tambah GitHub Secret: `GOOGLE_SERVICES_JSON` = isi base64
7. Di workflow, decode ke `android/app/google-services.json`
8. Tambah kembali `google_sign_in: 6.2.1` ke pubspec.yaml
9. Restore code Google login di auth_service.dart dan login_screen.dart

---

## SCREENS/HALAMAN:
| Screen | File | Deskripsi |
|--------|------|-----------|
| Home | `home_screen.dart` | Grid drama, featured slider, filter provider, infinite scroll, cek update |
| Detail | `detail_screen.dart` | Info drama, genre tags, daftar episode |
| Search | `search_screen.dart` | Pencarian debounce 500ms |
| Player | `player_screen.dart` | Portrait fullscreen 9:16, Chewie, swipe episode, debug panel |
| Login | `login_screen.dart` | Email/Password only (Google dicabut) |
| Profile | `profile_screen.dart` | Info user, VIP badge, logout |

---

## FITUR VIDEO PLAYER (TikTok-style):
- **100% fullscreen portrait** — Video memenuhi seluruh layar, tidak ada area lain
- **Immersive mode** — Status bar & navigation bar tersembunyi
- **Tap layar** → show/hide overlay (judul, controls)
- **Swipe bawah** → next episode (langsung ganti, tetap fullscreen)
- **Swipe atas** → prev episode
- **Tombol prev/next** di overlay bawah
- **HD/SD toggle** di overlay atas
- **Direct URL** — ExoPlayer native HLS/MP4, TANPA proxy (CORS bukan masalah di mobile)
- **Error handling** — Retry, switch quality, next episode, geser untuk skip
- **Auto-hide overlay** — Hilang setelah 3 detik

---

## FITUR AUTH:
- **Email/Password** — Register & login manual
- **Local fallback** — Jika backend down, auth lokal via SharedPreferences
- ~~Google Sign In~~ — DICABUT (butuh Firebase setup)

---

## FITUR SELF-UPDATE:
- Cek `https://jagatfilm.com/app/version.json` saat app dibuka
- Dialog jika ada versi baru
- `force_update: true` = dialog tidak bisa ditutup
- Tombol download buka browser
- Error tidak crash app

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
| 14 | d13685a | fix signed release gradle overwrite |
| 15 | 7ff73c8 | fix gradle kotlin dsl deprecation errors |
| 16 | 9eaa32f → 1eec02c | fix app crash: error handling, lazy google init, internet permission |
| 17 | f1084a4 | fix crash: remove google_sign_in, fix assets, fix namespace |
| 18 | d6379e1 | fix: fullscreen tiktok-style player, direct video URL, episode count |

---

## MASALAH YANG SUDAH DISELESAIKAN:

| # | Error | Penyebab | Solusi |
|---|-------|----------|--------|
| 1 | CardTheme type mismatch | Flutter API berubah | `CardTheme()` → `CardThemeData()` |
| 2 | Flutter Gradle Plugin lama | Format imperative | Regenerate android/ di CI |
| 3 | better_player namespace | Tidak kompatibel AGP | Ganti ke video_player + chewie |
| 4 | ApiException: 10 (Google) | SHA-1 belum didaftarkan | Dicabut sementara |
| 5 | ExoPlaybackException | URL tanpa headers | httpHeaders, detect MP4 vs HLS |
| 6 | BOTTOM OVERFLOWED 26px | Layout tidak responsive | SafeArea, Expanded, ScrollView |
| 7 | String not subtype int | API return String bukan int | `_parseInt()` helper |
| 8 | Video landscape (salah) | Drama vertikal | Portrait lock + 9:16 |
| 9 | SigningConfig not found | Gradle DSL order salah | Overwrite build.gradle.kts |
| 10 | Kotlin DSL deprecation | kotlinOptions deprecated | `kotlin { compilerOptions }` |
| 11 | APP CRASH saat dibuka | google_sign_in tanpa config | Hapus google_sign_in |
| 12 | APP CRASH asset | Empty assets folder declared | Hapus assets dari pubspec |
| 13 | Namespace mismatch | Package name tidak konsisten | Fix ke com.jagatfilm.jagatfilm |
| 14 | Video tidak fullscreen | Layout split video+grid | TikTok-style: video 100% layar, overlay controls |
| 15 | Swipe tidak berfungsi | GestureDetector hanya di area video kecil | GestureDetector di seluruh layar |
| 16 | Video Source error | URL diproxy lewat /api/hls (browser-only) | Pakai URL langsung (ExoPlayer native HLS/MP4) |
| 17 | Episode selalu 20 | Default fallback 20 jika totalEpisodes=0 | Default 80 (short drama umumnya 60-100 ep) |

---

## ARSITEKTUR FINAL:
```
lib/
├── main.dart                    → Entry point, portrait lock, runZonedGuarded
├── models/
│   ├── drama.dart               → Drama, DramaDetail, EpisodeInfo, StreamData (_parseInt)
│   └── user.dart                → User model
├── services/
│   ├── api_service.dart         → HTTP calls ke jagatfilm.com/api/*
│   ├── auth_service.dart        → Email auth + local fallback (no Google)
│   └── update_service.dart      → Self-update checker
├── screens/
│   ├── home_screen.dart         → Homepage + trigger update check
│   ├── detail_screen.dart       → Detail drama + episode list
│   ├── search_screen.dart       → Search debounce
│   ├── player_screen.dart       → Portrait video player + swipe
│   ├── login_screen.dart        → Email/password login/register
│   └── profile_screen.dart      → User profile
└── widgets/
    └── drama_card.dart          → Reusable card
```

---

## NGINX CONFIG (sudah dikonfigurasi):
- `/app/` → serve `version.json` (no-cache, JSON content-type)
- `/download/` → serve APK (no-cache, attachment disposition)

---

## CARA UPDATE APP:

### 1. Edit code:
```bash
cd /www/wwwroot/jagatfilm.com/apk
# Edit file di lib/
```

### 2. Update version di pubspec.yaml:
```yaml
version: 1.0.1+2   # nama+code (code harus naik)
```

### 3. Commit & push:
```bash
git add .
git commit -m "deskripsi"
git remote set-url origin https://TOKEN@github.com/mrharrasnaufal-eng/jgfm-app.git
git push
git remote set-url origin https://github.com/mrharrasnaufal-eng/jgfm-app.git
```

### 4. Otomatis terjadi:
- GitHub Actions build signed release APK
- Upload ke server → /download/app-release.apk
- Update /app/version.json
- User buka app → notif update → download

---

## ⚠️ CATATAN PENTING:
1. **Keystore** di `/root/android-keystore/upload-keystore.jks` — JANGAN HAPUS
2. **SSH key** di `/root/.ssh/id_rsa` — untuk auto deploy
3. **Google Sign In** dicabut sementara — butuh Firebase setup untuk kembali
4. **Video streaming** — pakai URL langsung (bukan proxy). Proxy `/api/hls` hanya untuk browser (CORS).
5. **Auth backend (port 3001)** tidak jalan — app pakai local auth
6. **Package name** = `com.jagatfilm.jagatfilm` — jangan ubah
7. **GitHub token** — untuk push dari server (jangan simpan di file repo)
8. **Video error masih bisa muncul** — tergantung provider. Beberapa provider blokir akses dari IP non-browser. User bisa swipe ke episode lain atau coba kualitas berbeda.

---

## QUICK START SESSION BERIKUTNYA:
1. Source: `/www/wwwroot/jagatfilm.com/apk/`
2. Repo: https://github.com/mrharrasnaufal-eng/jgfm-app
3. Edit → commit → push → otomatis build & deploy
4. Monitor: https://github.com/mrharrasnaufal-eng/jgfm-app/actions
5. APK final: https://jagatfilm.com/download/app-release.apk
6. Version: https://jagatfilm.com/app/version.json

---

## YANG BISA DITINGKATKAN:
1. **Google Sign In** — Setup Firebase, embed google-services.json
2. **Release signing** — Sudah ✅
3. **Backend auth** — Nyalakan port 3001 atau buat endpoint baru
4. **Offline cache** — SQLite drama list
5. **Download episode** — Simpan video offline
6. **History tontonan** — Progress per episode
7. **Favorit/Bookmark** — Simpan drama
8. **Custom app icon** — Buat launcher icon
9. **Splash screen** — Branded splash
10. **Deep linking** — Buka drama dari URL
11. **Push notification** — Drama baru
