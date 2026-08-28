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

### ATURAN KONSISTENSI (JANGAN DILANGGAR):
- **SEBELUM kerja, BACA LOG INI DULU** — lihat apa yang sudah pernah berhasil dan gagal
- **Jangan masukkan kembali kode yang sudah pernah gagal** — jika `kotlinOptions` gagal, JANGAN pakai lagi di commit berikutnya
- **Jika suatu pendekatan berhasil di commit tertentu, pakai PERSIS sama** — jangan variasi
- **Catat setiap error dan solusinya** — referensi untuk kedepannya
- **Konfigurasi Gradle yang BENAR (sudah terbukti berhasil):**
  ```kotlin
  import org.jetbrains.kotlin.gradle.dsl.JvmTarget

  kotlin {
      compilerOptions {
          jvmTarget.set(JvmTarget.JVM_11)
      }
  }
  ```
  JANGAN pakai: `kotlinOptions { jvmTarget = ... }` — INI GAGAL/DEPRECATED

### ATURAN WORKFLOW:
- `flutter create` generate android/ → **overwrite build.gradle.kts** dengan template yang sudah TERBUKTI berhasil
- Signing: `signingConfigs` SEBELUM `buildTypes`
- Keystore: decode SEBELUM overwrite file
- Internet permission: tambah via sed JIKA belum ada
- Itu saja. Jangan eksperimen.

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
- **100% fullscreen portrait** — Video proporsional di tengah layar (AspectRatio, no zoom/crop)
- **Immersive mode** — Status bar & navigation bar tersembunyi
- **Single tap layar** → show/hide overlay (judul, progress bar, episode nav)
- **Double-tap tengah** → pause/play (visual feedback icon)
- **Double-tap kiri** → mundur 10 detik (visual feedback icon)
- **Double-tap kanan** → maju 10 detik (visual feedback icon)
- **Swipe atas** → next episode (langsung ganti, tetap fullscreen)
- **Swipe bawah** → prev episode
- **Progress bar** — Seekable slider di overlay bawah
- **Tombol prev/next** di overlay bawah
- **HD/SD toggle** di overlay atas
- **Direct URL** — VideoPlayer native HLS/MP4, TANPA proxy, TANPA Chewie controls
- **Error handling** — Retry, switch quality, next episode
- **Auto-hide overlay** — Hilang setelah 3 detik

---

## FITUR AUTH:
- **Email/Password** — Register & login manual
- **Local fallback** — Jika backend down, auth lokal via SharedPreferences
- ~~Google Sign In~~ — DICABUT (butuh Firebase setup)

---

## FITUR SELF-UPDATE:
- Cek `https://www.jagatfilm.com/app/version.json` saat app dibuka (URL www, cache-bust)
- Dialog jika ada versi baru
- `force_update: true` = dialog tidak bisa ditutup
- Tombol download buka browser
- Error tidak crash app
- Null response = tampilkan error, BUKAN "up to date"

---

## ADMIN PANEL (DEPLOYED):
- URL: https://masterpanel.jagatfilm.com
- Login: Google OAuth (mr.harrasnaufal@gmail.com) atau manual
- Config API: https://masterpanel.jagatfilm.com/api/config (public endpoint)
- Port: 3004, PM2 "masterpanel", Next.js 14
- Fitur: branding, popup, maintenance, announcement, force update
- **Aturan Popup:**
  - Muncul SEKALI per sesi (saat buka app pertama kali)
  - Otomatis hilang setelah X detik (popup_duration)
  - Buka app lagi besok → popup tampil lagi
  - Action: navigasi halaman dalam app (page:home/search/profile/update/login) atau external URL

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
| 19 | 7889511 | fix swipe direction, add update icon in home, version 1.0.2 |
| 20 | b0f61ae | fix: show only working providers on home screen |
| 21 | 97171c3 | v1.0.3: fix video zoom, gesture controls, fix update checker, fix crash |

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
| 18 | Video zoom/crop di player | FittedBox BoxFit.cover crop video & subtitle | AspectRatio+Center, VideoPlayer langsung (no Chewie controls) |
| 19 | Player controls terlalu kecil | Chewie default buttons scaled wrong di FittedBox | Custom gesture zones: double-tap kiri/tengah/kanan |
| 20 | Update checker selalu "up to date" | URL tanpa www → 301 redirect, null = "up to date" | URL www, cache-bust ?t=timestamp, null = error message |
| 21 | APK cached 4 jam di Cloudflare | Nginx no-cache tidak cukup untuk CF CDN | CDN-Cache-Control: no-store → cf-cache-status: BYPASS |
| 22 | Potential crash setelah update | Tidak ada migration check saat version berubah | _runMigration() di main.dart, detect build number change |

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

---

## UPDATE 23 AGUSTUS 2026 — APK v1.0.4+5 REMOTE CONFIG (LOCAL)

### Status
- Implementasi source, commit, GitHub Actions analyze/build, dan deploy APK v1.0.4+5 selesai.
- MasterPanel dan kedua endpoint config online (HTTP 200).

### Fitur yang Ditambahkan
1. Fetch config dari MasterPanel dengan fallback salinan `/app/config.json` dan default aman.
2. Remote splash dan logo dengan fallback icon bawaan jika URL/image gagal.
3. Maintenance mode dengan custom message dan tombol retry.
4. Announcement banner di Home.
5. Popup sekali per sesi, auto-close 2–30 detik, image/title/message, action internal atau external HTTP(S).
6. Minimum semantic version dan force-update non-dismissible, terintegrasi dengan update checker lama tanpa dialog ganda.
7. Sanitasi seluruh payload remote untuk mencegah URL/action berbahaya dan data malformed menyebabkan crash.

### Test dan Validasi
- Unit test baru: `test/remote_config_test.dart`.
- Mencakup parsing/sanitasi, clamp durasi, endpoint fallback, defaults saat gagal, dan version comparison.
- `git diff --check`, import resolution, delimiter/whitespace, schema endpoint, serta audit independen lulus.
- GitHub Actions run `32644795604` berhasil menjalankan analyze, signed release build, dan deploy v1.0.4+5.

### File Utama
- Baru: `app_remote_config.dart`, `remote_config_service.dart`, `maintenance_screen.dart`, `remote_config_popup.dart`, `remote_config_test.dart`.
- Diubah: `main.dart`, `home_screen.dart`, `update_service.dart`, `pubspec.yaml` (`1.0.4+5`).

---

## UPDATE 23 AGUSTUS 2026 — APK v1.0.5+6 LAUNCHER ICON + SPLASH

### Status
- Commit `0aa9eae`, GitHub Actions run `32646131587` sukses, deployed v1.0.5+6.

### Launcher Icon
- Logo MasterPanel PNG RGBA 1024x1024 digunakan sebagai sumber.
- Legacy icon tersedia untuk mdpi, hdpi, xhdpi, xxhdpi, dan xxxhdpi.
- Adaptive foreground tersedia untuk semua density dengan padding aman; background `#081633`.
- Canonical assets disimpan di `branding/launcher_icon/`, termasuk artwork Play Store 512px.
- Workflow menerapkan ikon setelah `flutter create` agar resource custom tidak ditimpa default Flutter.

### Splash 5 Detik
- `minimumSplashDuration` di `main.dart` diubah menjadi `Duration(seconds: 5)`.
- Remote Config timeout diubah menjadi 2 detik per endpoint; primary dan fallback maksimal sekitar 4 detik agar selesai sebelum splash hilang.
- Setelah 5 detik, aplikasi melanjutkan ke maintenance gate atau halaman utama.
- Versi lokal dinaikkan menjadi `1.0.5+6`.

### Validasi Lokal
- PNG dimensions dan format seluruh density sesuai.
- Adaptive XML dan color XML valid.
- Canonical assets dan mirror Android byte-identical.
- Simulasi copy workflow berhasil mengganti ikon default.
- Workflow YAML valid.

---

## UPDATE 23 AGUSTUS 2026 — APK v1.0.6+7 SPLASH BERSIH

### Status
- Commit `28f7ef6`, GitHub Actions run `32647061863` sukses, deployed v1.0.6+7.

### Perubahan
- Splash screen sekarang hanya menampilkan `splash_image_url` fullscreen selama 5 detik.
- Dihapus: logo overlay di tengah splash, overlay gelap, dan CircularProgressIndicator.
- Fallback: jika URL splash kosong/gagal, tampil gradient gelap default.
- Setelah 5 detik, langsung masuk halaman utama atau maintenance gate.

### Verifikasi
- APK publik v1.0.6 versionCode 7.
- SHA-256 publik = server: `38c825d32266bb78b25e8bea23da95a79ce19b62a9ac66e96e07f89e1fa089fa`.
- Cloudflare `BYPASS`, `no-store`.
- MasterPanel `/api/config` HTTP 200.
- Git clean, `HEAD == origin/main` pada `28f7ef6`.

---

## UPDATE 23 AGUSTUS 2026 — APK v1.0.7+8 PRELOAD + MULTI-PROVIDER SHUFFLE

### Status
- Commit `0df62be`, GitHub Actions run `32652087031` sukses (analyze, build, artifact OK).
- ⚠️ Auto-deploy SSH gagal diam-diam (step success via `continue-on-error` tapi file server TIDAK berubah).
- **Deploy manual via artifact berhasil**: APK dan version.json diunduh dari artifact GitHub dan disalin langsung.

### Perubahan
- `PreloadService` baru: fetch 6 provider acak paralel saat splash, deduplicate, shuffle, precache popup image + 12 thumbnail.
- `main.dart`: preload berjalan paralel dengan sisa splash 5 detik; hasilnya diteruskan ke HomeScreen.
- `home_screen.dart`: menerima `preloadedDramas`; jika ada langsung tampil tanpa shimmer/loading. Mode "Semua" sekarang fetch multi-provider paralel dan shuffle — setiap buka app drama berbeda-beda.
- Pull-to-refresh juga shuffle ulang dari provider acak.

### Verifikasi
- APK publik v1.0.7 versionCode 8.
- SHA-256 publik = server: `ea024f2d2ce20d6e9067893644e989ff5b2fcb8099158fdf7571de628f5450e0`.
- Cloudflare `BYPASS`, `no-store`.
- MasterPanel `/api/config` HTTP 200.
- Git clean, `HEAD == origin/main` pada `0df62be`.

### ⚠️ ISSUE: Auto-Deploy SSH
- GitHub Actions step "Deploy to aaPanel" dan "Move files on server" dilaporkan sukses (karena `continue-on-error: true`).
- Namun file server TIDAK berubah (timestamp/size/hash tetap v1.0.6+7).
- Kemungkinan: SSH key di GitHub Secrets tidak lagi authorized, atau aaPanel firewall memblokir koneksi SSH dari runner GitHub baru.
- Perlu investigasi: cek authorized_keys server, test SSH dari luar, atau perbaiki secret `AAPANEL_SSH_KEY`.
- Sementara deploy manual via artifact (download zip + extract + copy) tetap bisa dilakukan.

---

## ⚠️ BACKUP POINT — v1.0.9+10 STABLE (23 Aug 2026, 21:30 UTC)

### VERSI STABLE TERAKHIR SEBELUM REDESIGN UI/UX

| Field | Nilai |
|-------|-------|
| **Versi** | 1.0.9+10 |
| **Commit** | `632c860b52009381888d944a0404165fd2af1de5` |
| **Commit msg** | feat: home provider configurable from admin panel |
| **APK SHA-256** | `f8ab35104f90582b4be415896e1116726d42a7baa1e2024712d3d17138fc6117` |
| **APK Size** | 60,506,548 bytes (~57.7 MB) |
| **APK Timestamp** | 23 Aug 2026, 17:29 UTC |
| **Backup Location** | `/www/wwwroot/jagatfilm.com/backup/apk-stable/app-release-v1.0.9+10-stable.apk` |
| **Branch** | `main` |

### Fitur yang sudah berjalan di v1.0.9:
- ✅ Signed release APK (upload-keystore.jks)
- ✅ Custom launcher icon (logo JagatFilm)
- ✅ Splash screen 5 detik (gambar fullscreen dari remote config)
- ✅ Remote config dari MasterPanel (popup, maintenance, announcement, branding, force update)
- ✅ Multi-provider drama preload saat splash
- ✅ Home provider configurable dari admin panel
- ✅ Video player gesture-based (double-tap pause, skip, BoxFit.contain)
- ✅ Update checker (version.json, no-cache)
- ✅ GitHub Actions CI/CD (analyze, signed build, deploy)
- ✅ Cloudflare BYPASS untuk APK

### ⚠️ INSTRUKSI ROLLBACK:
Jika redesign UI/UX (v2.0) bermasalah atau crash:
1. Copy backup APK ke download: `cp /www/wwwroot/jagatfilm.com/backup/apk-stable/app-release-v1.0.9+10-stable.apk /www/wwwroot/jagatfilm.com/download/app-release.apk`
2. Restore version.json: `cp /www/wwwroot/jagatfilm.com/backup/apk-stable/version-v1.0.9.json /www/wwwroot/jagatfilm.com/app/version.json`
3. Git: `cd /www/wwwroot/jagatfilm.com/apk && git checkout 632c860` (atau buat branch baru dari sini)
4. Purge Cloudflare cache

### Catatan:
- Mulai dari versi SETELAH ini (v2.0.0+11 dst), APK akan menjalani redesign total UI/UX terinspirasi DramaBox.
- Blueprint redesign: `/www/wwwroot/jagatfilm.com/apk/BLUEPRINT-UIUX.md`
- Jika redesign gagal di tahap mana pun, ROLLBACK ke v1.0.9 dan mulai ulang dari sini.
- JANGAN hapus folder backup ini.

---

## SESI 11 — REDESIGN UI/UX v2.0 (23 Aug 2026, 21:00–23:50 UTC)

### Rangkuman
Redesign total UI/UX APK terinspirasi DramaBox. Dari v1.0.9 ke v2.0.5.

---

### Fase 0: Backend Analytics (Selesai ✅)
**Tujuan:** Buat sistem tracking views sendiri agar tab Untukmu/Peringkat/Terbaru punya data real.

**Database (PostgreSQL masterpanel_db):**
- `drama_views` — lifetime view count per drama
- `drama_views_daily` — daily views untuk trending 7 hari
- `drama_first_seen` — timestamp pertama drama ditemukan (untuk tab Terbaru)

**Endpoint baru (website jagatfilm.com):**
- `POST /api/analytics/view` — APK record view saat user buka drama
- `GET /api/dramas/popular?limit=50&page=1` — sort by view_count DESC (+ cover)
- `GET /api/dramas/trending?days=7&limit=30` — views 7 hari terakhir (+ cover)
- `GET /api/dramas/newest?limit=30&page=1` — sort by first_seen_at DESC
- `GET /api/dramas/stats?ids=id1,id2,...` — batch view counts
- `GET /api/drama/detail?id=xxx` — episode list real dari provider (BARU, fix v2.0.2)

**Modifikasi:**
- `dramas/route.ts` mergeDramas() → auto-populate drama_first_seen saat drama baru ditemukan
- Seed: 22,298 drama di first_seen, 500 drama views random, 3500 daily records

**Dependency baru website:** `pg@8.13.1`, `@types/pg@8.11.10`

---

### Fase 1: Foundation APK (v2.0.0+11, commit `ec2dab6`)
**Build:** GitHub Actions #32669543604 ✅

**File baru:**
- `lib/theme/app_theme.dart` — dark theme centralized
- `lib/utils/constants.dart` — spacing, radius, font sizes, strings, formatViews()
- `lib/screens/main_shell.dart` — bottom nav 5 tab + IndexedStack
- `lib/screens/home_tabs/untukmu_tab.dart` — grid 3 kolom + infinite scroll
- `lib/screens/home_tabs/kategori_tab.dart` — filter provider/genre/sort
- `lib/widgets/badge_pill.dart`
- `lib/widgets/genre_pill.dart`
- `lib/widgets/section_header.dart`
- `lib/widgets/shimmer_grid.dart`
- `lib/widgets/drama_card_grid.dart`
- `lib/widgets/filter_pills.dart`

**File diubah:**
- `lib/main.dart` — routing ke MainShell, AppTheme.darkTheme
- `lib/screens/home_screen.dart` — refactored → TabBar 4 tab wrapper

---

### Fase 2: Content Pages (v2.0.1+12, commit `8148ea4`)
**Build:** GitHub Actions sukses ✅

**File baru:**
- `lib/screens/home_tabs/terbaru_tab.dart` — list vertikal drama terbaru
- `lib/screens/home_tabs/peringkat_tab.dart` — ranking list + filter tren/populer/terbaru
- `lib/screens/for_you_screen.dart` — feed card besar rekomendasi

**File diubah:**
- `lib/screens/search_screen.dart` — REWRITE: trending chips + history + debounce
- `lib/screens/home_screen.dart` — placeholder diganti real tabs
- `lib/screens/main_shell.dart` — ForYouScreen ganti placeholder

---

### Fix-fix Penting:

#### v2.0.2+13 (commit `976cee9`) — CRITICAL FIX
- **DetailScreen:** fetch episode list real dari `/api/drama/detail` (bukan generate 80 palsu)
- **UntukmuTab:** default provider `shortmax` (bukan 'all' yang campur provider rusak)
- **Endpoint baru:** `GET /api/drama/detail?id=xxx` di website

#### v2.0.3+14 (commit `275e3d8`)
- **Server:** endpoint popular/trending sekarang JOIN drama_first_seen untuk cover URL
- Peringkat thumbnail sekarang visible

#### v2.0.4+15 (commit `01043a7`)
- **KategoriTab:** exclude provider broken (flickshort, fundrama, vigloo, dramanova)
- **KategoriTab:** genre list sesuai data real API (Cinta, Balas Dendam, CEO, dll)

#### v2.0.5+16 (commit `2b4e110`) — FINAL FIX
- **Semua halaman** exclude broken providers: ForYou, Terbaru, Peringkat, Kategori, Search
- Provider yang di-exclude: flickshort (stream mati + judul asing), fundrama (stream mati), vigloo, dramanova

---

### Provider Status (23 Aug 2026):
| Provider | Stream | Judul ID | Status |
|----------|--------|----------|--------|
| shortmax | ✅ | ✅ | **Default home** |
| reelshort | ✅ | ⚠️ Mixed | OK |
| dramabox | ✅ | ✅ | OK |
| melolo | ✅ | ✅ | OK |
| netshort | ✅ | ✅ | OK |
| flickreels | ✅ | ⚠️ Mixed | OK |
| cashdrama | ✅ | ✅ | OK |
| bilitv | ✅ | ✅ | OK |
| flickshort | ❌ | ❌ Portugis | **EXCLUDED** |
| fundrama | ❌ | ✅ | **EXCLUDED** |
| vigloo | ❌ | - | **EXCLUDED** |
| dramanova | ❌ | - | **EXCLUDED** |

---

### Bottom Nav fix (commit `fdf0bf4`):
- SafeArea + systemNavigationBarColor #1A1A1A agar tidak overlap Android nav bar

---

### Status Akhir Sesi:
- **Versi live:** v2.0.5 build 16
- **Commit HEAD:** `2b4e110`
- **Semua tab fungsional:** Untukmu ✅, Terbaru ✅, Peringkat ✅, Kategori ✅, Untuk Anda ✅
- **Placeholder tersisa:** Koin (bottom nav), Daftarku (bottom nav) — Fase 3
- **Backup v1.0.9 aman** di `/www/wwwroot/jagatfilm.com/backup/apk-stable/`

### Belum dikerjakan (Fase 3+):
- Watchlist/Daftarku (local SharedPreferences)
- Profil redesign
- Koin UI (coming soon)
- Adsterra ads integration
- Notifikasi

---

## SESI 12 — FASE 3 + 4 + KOIN FUNGSIONAL (24 Aug 2026, 20:00–22:00 UTC)

---

### Fase 3: User Features (v2.1.0+17, commit `154fe90`)
**Build:** GitHub Actions #32772982669 ✅

**File baru:**
- `lib/models/watchlist_item.dart` — Model watchlist + progress
- `lib/models/watch_history.dart` — Model riwayat + timeAgo
- `lib/models/coin_transaction.dart` — Model transaksi koin
- `lib/services/watchlist_service.dart` — CRUD watchlist (SharedPreferences)
- `lib/services/history_service.dart` — Riwayat tontonan (max 50, SharedPrefs)
- `lib/services/coin_service.dart` — Mock koin service (kemudian di-rewrite)
- `lib/screens/watchlist_screen.dart` — Tab Sedang Ditonton + Riwayat
- `lib/screens/coin_screen.dart` — Reward center UI

**File diubah:**
- `lib/screens/profile_screen.dart` — REWRITE: avatar, koin banner, benefit grid, menu
- `lib/screens/main_shell.dart` — CoinScreen + WatchlistScreen ganti placeholder
- `lib/main.dart` — MultiProvider (4 services)
- `lib/screens/player_screen.dart` — Record history + update watchlist progress
- `lib/screens/detail_screen.dart` — Tombol bookmark/watchlist

---

### Fase 4: Polish & Monetization (v2.2.0+18, commit `d421bec`)
**Build:** GitHub Actions #32776696710 ✅

**Fitur:**
- `lib/services/ad_service.dart` — Adsterra interstitial + rewarded
- UntukmuTab: 3-col grid (9 items) → Provider Spotlight → Masonry 2-col + Genre Block
- PlayerScreen: interstitial ad setiap 3 episode
- CoinScreen: Tonton Iklan button aktif
- Hero animation (poster grid → detail)
- Page transition (slide right, easeOutCubic 300ms)

---

### Fix: Iklan In-App (v2.2.1+19, commit `b2f5417`)
**Build:** GitHub Actions #32778685145 ✅

- Sebelumnya iklan redirect ke Chrome (tidak profesional)
- Fix: `webview_flutter: 4.8.0` ditambah ke pubspec
- AdService rewrite: WebView fullscreen in-app
- Interstitial: 5 detik countdown → tombol "Lewati"
- Rewarded: 8 detik countdown → tombol "Klaim +1 Koin"
- Semua navigasi tetap di dalam WebView, tidak buka browser

---

### Koin Fungsional — Backend + API (v2.3.0+20, commit `d97606f`)
**Build:** GitHub Actions #32782149598 ✅

**Database (PostgreSQL masterpanel_db):**
- `coin_wallets` — saldo per device_id, link ke user_id
- `coin_transactions` — riwayat earn/spend
- `coin_withdrawals` — request penarikan

**API Endpoints (jagatfilm.com):**
- `POST /api/coins/earn` — +1 koin per iklan (cooldown 30s, max 50/hari)
- `GET /api/coins/balance` — saldo by device_id
- `GET /api/coins/history` — riwayat transaksi
- `POST /api/coins/link` — merge device ke user saat login
- `POST /api/coins/withdraw` — penarikan (min 10.000 koin, wajib login)

**APK Changes:**
- CoinService rewrite: connect ke backend, device_id UUID auto-generate
- CoinScreen: saldo real dari server, +1 koin per ad
- LoginScreen: auto-link device coins ke user setelah login

**Rules Koin & Iklan:**
| Rule | Nilai |
|------|-------|
| 1 iklan | = 1 koin |
| 1.000 koin | = Rp 1.000 |
| Min withdrawal | = 10.000 koin (Rp 10.000) |
| Max iklan/hari | = 50 |
| Cooldown | = 30 detik |
| Login untuk earn | Tidak perlu (device_id) |
| Login untuk withdraw | WAJIB |

**Anti-Cheat:**
- Server validate cooldown + daily limit
- Device ID persist di SharedPreferences
- APK tidak bisa manipulasi saldo

**Model Bisnis:**
- Admin: ~Rp 3.2 per impression dari Adsterra
- User: 1 koin (Rp 1) per iklan
- Profit admin: ~Rp 2.2 per view
- User butuh 200 hari × 50 iklan untuk withdraw pertama
- Alternatif: koin untuk VIP/premium (tidak perlu cashout)

---

### Verifikasi Akhir Sesi 12:
- **Versi live:** v2.3.0 build 20
- **Commit HEAD:** `d97606f`
- **APK SHA-256:** deploy berhasil, SHA match server=public
- **Semua endpoint koin:** tested & working
- **Iklan:** render in-app, tidak redirect browser
- **Git:** clean, HEAD == origin/main
- **Placeholder tersisa:** VIP benefits, withdrawal UI di APK, MasterPanel halaman koin admin


---

## FIX IKLAN — SESI 12 LANJUTAN (24 Aug 2026, 22:00–23:00 UTC)

### v2.3.1+21 (commit `fe16821`) — Fake Skip Mechanism
- Interstitial: random 10-15 detik countdown
- Phase 1: countdown saja, tidak ada tombol
- Phase 2: fake skip icon (⏭) top-left → buka link iklan di browser
- Phase 3: user balik ke app → real skip (✕) muncul top-right
- Revenue boost: forced CPC click via fake skip

### v2.3.2+22 (commit `328c3b7`) — 2 Variants + Perbaikan UI
- **Variant A** (episode 3, 9, 15...): countdown → skip asli langsung (clean, user friendly)
- **Variant B** (episode 6, 12, 18...): countdown → fake skip → klik iklan → balik → skip asli
- Semua tombol di posisi **kanan atas** (tidak menimpa konten iklan)
- Countdown **mulai setelah iklan ter-load** (bukan saat screen dibuka)
- Fake skip: icon ⏭ + "Lewati" (warna redup, tanpa border)
- Real skip: icon ✕ + "Lewati" (warna terang, ada border putih)

### v2.3.3+23 (commit `26e6d3a`) — Fix Iklan Tidak Tampil
- **Masalah:** Iklan blank hitam + loading spinner berputar terus
- **Penyebab:** `loadHtmlString` + iframe di-block Android WebView security (origin `about:blank`)
- **Fix:** Ganti ke `loadRequest(Uri.parse(smartlinkUrl))` — load URL Adsterra langsung tanpa HTML wrapper/iframe
- **Hasil:** Iklan tampil langsung di WebView, countdown mulai setelah page loaded

### Verifikasi Akhir:
- Versi live: **v2.3.3 build 23**
- Commit HEAD: `26e6d3a`
- GitHub Actions: semua success
- Iklan: ✅ tampil di dalam app, tidak blank, tidak redirect browser
- Variant A: ✅ clean skip setelah countdown
- Variant B: ✅ fake skip → browser → balik → real skip

### RULES IKLAN FINAL (simpan untuk referensi):
```
Episode 3, 9, 15, 21... → Variant A (normal, skip langsung)
Episode 6, 12, 18, 24... → Variant B (fake skip, klik iklan dulu)
Durasi countdown: random 10-15 detik
Countdown mulai: setelah WebView finish load
Posisi tombol: selalu kanan atas
Rewarded (halaman koin): 8 detik, clean, +1 koin
WebView: loadRequest langsung ke Smartlink URL (BUKAN loadHtmlString+iframe)
```



---

## SESI 13 — NOTIFIKASI FASE 1 (LOCAL, TANPA FIREBASE) (26 Aug 2026)

### Status: IMPLEMENTASI SELESAI — BELUM DI-PUSH/DEPLOY (menunggu izin owner)

Fase 5 blueprint item "Push notifications" → dikerjakan Fase 1 (local notification tanpa Firebase).
Versi target: **v2.4.0+24** (dari v2.3.3+23).

### Backend — MasterPanel (masterpanel.jagatfilm.com, port 3004, PM2 "masterpanel")
- **Tabel PostgreSQL baru** `app_notifications` di `masterpanel_db`:
  `id, title, message, image_url, action, external_url, active, published_at, created_at` + index `(active, published_at DESC)`.
- **Endpoint baru:**
  - `GET /api/notifications` — public, list notif `active` (APK fetch). `?all=1` (admin) = semua.
  - `POST /api/notifications` — admin only (session), buat notif (sanitasi title/message/url/action).
  - `PUT /api/notifications/[id]` — admin, edit / toggle `active`.
  - `DELETE /api/notifications/[id]` — admin, hapus.
  - ⚠️ Next.js 14 → `params` adalah objek SINKRON (bukan Promise). Jangan pakai `await params`.
- **Dashboard `dashboard/notifications/page.tsx`** di-rewrite dari mockup jadi CRUD fungsional
  (form judul/pesan/gambar/aksi/aktif, tabel dengan toggle active + edit + hapus).
- **Verifikasi backend:** `npm run build` SUKSES (routes + page compiled). PM2 restart.
  `GET /api/notifications` → HTTP 200 `{"success":true,"data":[]}`. Uji insert: notif `active`
  tampil, `inactive` disembunyikan dari public. Cleanup OK.

### APK (lib/)
- **`pubspec.yaml`:** `flutter_local_notifications: 17.2.4` (17.x = versi terakhir yang TIDAK butuh
  core library desugaring; 18.0.0+ butuh desugaring → harus ubah `build.gradle.kts` = risiko, DIHINDARI).
  `permission_handler` TIDAK dipakai — `flutter_local_notifications` sudah request POST_NOTIFICATIONS
  sendiri via `requestNotificationsPermission()`, jadi native surface minimal.
- **`lib/services/notification_service.dart` (BARU):**
  - `AppNotification` model dengan parse tersanitasi (whitelist action, validasi http url).
  - `NotificationService` singleton: `init()` (init plugin + createNotificationChannel + request izin),
    `checkAndShow()` (fetch `https://masterpanel.jagatfilm.com/api/notifications`, dedupe via
    SharedPreferences `shown_notification_ids` max 200, tampilkan BigTextStyle), `consumePendingAction()`.
  - Payload tap = `action` (`page:xxx`) atau `external:<url>`. SEMUA dibungkus try-catch.
- **`lib/main.dart`:** import service; `_runNotificationCheck()` dipanggil `unawaited()` di akhir
  `_presentSessionNotices` (setelah cek update, non-blocking); `_handleNotificationAction` map
  `external:<url>` → `launchUrl`, `page:*` → `_handlePopupAction` yang sudah ada.
- **`.github/workflows/build-apk.yml`:** inject `POST_NOTIFICATIONS` ke manifest via `sed`
  (pola sama persis dengan INTERNET). `build.gradle.kts` TIDAK diubah (no desugaring, no compileSdk bump).

### Verifikasi Lokal
- pubspec YAML valid (v2.4.0+24). workflow YAML valid, POST_NOTIFICATIONS injection ada.
- Brace/paren/bracket balanced di notification_service.dart & main.dart. LSP no diagnostics.
- Nama API plugin dikonfirmasi benar untuk 17.x.
- Checklist anti-crash lulus: tidak ada dep yang butuh native config (beda dgn google_sign_in),
  semua kode startup try-catch + unawaited, build.gradle.kts utuh, namespace tetap, tidak ada asset kosong.

### ⚠️ BLOCKER Verifikasi
- Flutter/Dart SDK TIDAK terpasang di server (dicek: which, /opt, /usr/local, ~, /root, find /).
  `flutter analyze` / `flutter build` HANYA bisa jalan di GitHub Actions. Belum dijalankan karena belum push.

### Belum dilakukan (menunggu owner)
- `git commit` + `git push` (perlu izin eksplisit).
- Setelah push WAJIB (AGENTS.md): pantau GH Actions run by commit SHA sampai `success`
  (analyze, signed build, artifact), lalu verifikasi publik: `version.json` v2.4.0/versionCode 24,
  APK server=public HTTP 200 + SHA-256 identik, cache BYPASS/no-store, signing block, git clean HEAD==origin/main.
- Uji manual di device: buat notif di panel → buka app → notif muncul di status bar → tap → navigasi benar.

### FIX BUILD (v2.4.0+25) — Core Library Desugaring
- **Commit pertama `60302c7` (v2.4.0+24):** GitHub Actions run `33003678437` → analyze SUKSES,
  tapi **Build Release APK GAGAL** di task `:app:checkReleaseAarMetadata`:
  `Dependency ':flutter_local_notifications' requires core library desugaring to be enabled`.
  (Asumsi awal "hanya 18+ butuh desugaring" ternyata SALAH — transitive
  `flutter_local_notifications_android` di Flutter stable mewajibkan desugaring walau plugin di 17.2.4.)
- **Fix (v2.4.0+25):** Aktifkan core library desugaring di template `build.gradle.kts` (workflow):
  - `compileOptions { isCoreLibraryDesugaringEnabled = true }`
  - `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }`
  - Perubahan ADITIF minimal; signing/namespace/minSdk 23/buildTypes TIDAK berubah.
  - `desugar_jdk_libs 2.1.4` butuh AGP 8.0+ (Flutter stable pakai AGP 8.1+ untuk compileSdk 35) → kompatibel.
- ⚠️ CATATAN untuk sesi berikutnya: `build.gradle.kts` yang BENAR sekarang WAJIB menyertakan
  desugaring selama `flutter_local_notifications` dipakai. Jangan hapus dua baris itu.

### ✅ DEPLOY BERHASIL & TERVERIFIKASI (v2.4.0+25, 26 Aug 2026 ~19:25 UTC)
- **Commit HEAD:** `f3552a4` (fix desugaring). Commit fitur: `60302c7`.
- **GitHub Actions run `33004336746`:** conclusion **success**. SEMUA step hijau termasuk
  analyze, Build Release APK, artifact, Deploy to aaPanel, Move files on server.
- **Auto-deploy SSH kali ini BERHASIL** (beda dari isu lama v1.0.7+8) — file server ter-update.
- **Verifikasi publik:**
  - `version.json` publik & server: version `2.4.0`, versionCode `25`. ✅
  - APK server & publik: HTTP 200, size 62.209.208 bytes, timestamp 19:24 UTC. ✅
  - **SHA-256 publik = server:** `b75507bfd70a63f4f10683fab251389c10b9abe07454fd9f17077ce937c94609`. ✅
  - Cache: `cache-control: no-store`, `cdn-cache-control: no-store`, `cf-cache-status: BYPASS`. ✅
  - ZIP integrity OK; APK Signing Block v2/v3 ada; AndroidManifest ada. ✅
  - Manifest APK berisi `POST_NOTIFICATIONS` + `INTERNET` + `usesCleartextTraffic` + package `com.jagatfilm.jagatfilm`. ✅
  - `masterpanel.jagatfilm.com/api/config` HTTP 200; `/api/notifications` HTTP 200 `{"success":true,"data":[]}`. ✅
  - Git clean, `HEAD == origin/main` pada `f3552a4`. ✅
- **Versi live sekarang: v2.4.0 build 25.**
- **Belum dites manual (butuh device):** buat notif di panel admin → buka app → notif muncul di
  status bar → tap → navigasi ke halaman/URL sesuai action. (Backend & pipeline sudah terverifikasi.)
- ⚠️ **TOKEN GitHub `ghp_9iA3gdWev...` terekspos lagi di sesi ini — owner WAJIB revoke/rotate sekarang.**


---

## SESI 13 LANJUTAN — NOTIFIKASI CUSTOM DRAMABOX-STYLE (26 Aug 2026)

### Status: ❌ GAGAL — Custom layout TIDAK tampil saat app tertutup

### Apa yang sudah dibuat:
- Layout XML custom (notification_collapsed + notification_expanded) dengan poster kiri + teks tengah + tombol pink "Tonton"
- CustomNotificationHelper.kt (RemoteViews + image download + PendingIntent)
- MainActivity.kt (MethodChannel bridge Dart→native)
- NotificationService Dart memanggil native via MethodChannel, fallback ke flutter_local_notifications
- Build SUKSES (v2.5.2+28, run 33015024909)

### Kenapa gagal:
- **MethodChannel hanya bisa dipanggil saat Flutter engine aktif** (app terbuka/foreground)
- Saat app tertutup, FCM menampilkan notifikasi menggunakan **style default Android** dari field `notification` di payload — BUKAN custom layout
- Untuk custom layout saat app tertutup, butuh:
  1. Kirim FCM sebagai **data-only message** (tanpa field `notification`)
  2. Buat `FirebaseMessagingService` native Kotlin yang handle message di background
  3. Dari service itu, panggil `CustomNotificationHelper` untuk tampilkan custom layout
  4. Register service di AndroidManifest

### Yang owner inginkan (BELUM TERPENUHI):
Notifikasi **persis seperti DramaBox** di status bar smartphone:

**Collapsed (bar kecil):**
- Ikon app (kiri) — logo JagatFilm rounded
- Poster/thumbnail drama (vertikal, sebelah ikon)
- Judul drama (tebal, hitam, max 1 baris)
- Deskripsi (abu-abu, emoji 🔥 + teks, max 1 baris)
- Tombol "Tonton" (pink #FF2D55, rounded, teks putih) di kanan
- Chevron expand di ujung kanan

**Expanded (diperluas setelah swipe/klik):**
- Header: ikon app + "JagatFilm sekarang 🔔" + chevron atas
- Poster drama penuh (vertikal, kiri)
- Judul lengkap (kanan, tebal)
- Deskripsi lengkap (kanan)
- Tombol "Tonton" pink full-width membentang di bawah

**Persyaratan tambahan:**
- HARUS tampil saat app **tertutup** (push dari server)
- Tap notifikasi/tombol → navigasi ke halaman target (search/home/drama/external URL)
- Poster di-download dari image_url yang dimasukkan admin

### Solusi yang belum diimplementasi:
1. Endpoint push kirim **data-only message** (hapus field `notification` dari FCM payload)
2. Buat `JagatFilmMessagingService.kt` extends `FirebaseMessagingService`
   - Override `onMessageReceived` → parse data → panggil `CustomNotificationHelper.show()`
   - Ini berjalan di background tanpa Flutter engine
3. Register service di AndroidManifest:
   ```xml
   <service android:name=".JagatFilmMessagingService" android:exported="false">
     <intent-filter>
       <action android:name="com.google.firebase.MESSAGING_EVENT"/>
     </intent-filter>
   </service>
   ```
4. Workflow: copy service file + inject manifest entry via sed

### Catatan:
- File native yang sudah dibuat (android-native/) masih ada di repo dan BISA dipakai
- Yang kurang hanya FirebaseMessagingService native + data-only FCM + manifest entry
- Ini BUKAN limitasi Flutter yang tidak bisa diatasi — hanya perlu pendekatan berbeda


---

## SESI 14 — CUSTOM NOTIFIKASI NATIVE (FCM DATA-ONLY) v2.6.0+29 (28 Aug 2026)

### Backup sebelum mulai
- APK v2.5.2+28 dibackup: `backup/apk-stable/app-release-v2.5.2+28-stable.apk` + `version-v2.5.2.json`
  + `BACKUP-INFO-v2.5.2.md`. Git tag `v2.5.2+28` di commit `366ec22`. SHA-256
  `9d4118561db36ddc928aceef4f147f7ed4954156eae9e7630825d2af6fa16360`.
- CONTEXT.md di-update dengan entri backup baru.

### Riset (sumber: Android dev docs, Stack Overflow, Qonversion, Pushe/Yandex docs)
- Custom layout saat app tertutup HANYA mungkin dengan **data-only FCM** (tanpa key `notification`).
  Payload `notification` → system tray pakai style default, custom UI dilewati.
- Android 12+ (targetSdk 31+): tinggi collapsed custom content dibatasi **48dp** (turun dari 106dp)
  → layout collapsed lama 64dp HARUS diubah.
- Teks custom layout WAJIB pakai warna adaptif (`?android:attr/textColorPrimary/Secondary`),
  bukan warna fixed — background notifikasi bervariasi per OEM.
- Transaksi RemoteViews dibatasi ~1MB → poster dari `image_url` WAJIB di-downsample
  (full-size bitmap = TransactionTooLargeException).
- Header (ikon app + chevron expand + "sekarang") otomatis dari `DecoratedCustomViewStyle`.
- firebase_messaging 15.1.6: `FlutterFirebaseMessagingService.onMessageReceived` KOSONG (placeholder,
  delivery Dart via `FlutterFirebaseMessagingReceiver` c2dm.intent.RECEIVE) → aman di-remove
  dari manifest dengan `tools:node="remove"` dan diganti service sendiri yang extends class tsb.

### Implementasi (APK)
1. `notification_collapsed.xml`: tinggi 48dp, padding 4dp, poster 28x40dp, tombol 24dp,
   warna teks adaptif.
2. `notification_expanded.xml`: warna teks adaptif (struktur tetap).
3. `CustomNotificationHelper.kt`: poster di-downsample (max 400px, inSampleSize),
   intent tap sekarang eksplisit ke `MainActivity` dengan extra `notification_action`.
4. `JagatFilmMessagingService.kt` (BARU): extends `FlutterFirebaseMessagingService` —
   `super.onMessageReceived` lalu tampilkan custom notification UNTUK data-only saat app
   TIDAK foreground (flag `MainActivity.isAppForeground`). Network/bitmap via
   `goAsync()` + `Dispatchers.IO` (window ~20 detik). Foreground tetap ditangani Dart
   (hindari dobel notifikasi).
5. `MainActivity.kt`: flag foreground (onResume/onPause), baca extra `notification_action`
   di onCreate/onNewIntent → tulis ke file `FlutterSharedPreferences` key
   `flutter.pending_notification_action` (prefix shared_preferences) → alur
   `NotificationService.consumePendingAction()` yang SUDAH ADA berjalan tanpa ubah Dart.
6. `build-apk.yml`: copy `JagatFilmMessagingService.kt` + step baru "Register custom FCM
   service in manifest" (python3): tambah `xmlns:tools`, remove
   `FlutterFirebaseMessagingService` via `tools:node="remove"`, daftarkan
   `.JagatFilmMessagingService` (exported=false, MESSAGING_EVENT).
7. `pubspec.yaml`: version **2.6.0+29**.

### Implementasi (MasterPanel) — JANGAN deploy sebelum APK live!
- `src/app/api/notifications/push/route.ts`: payload jadi **data-only** (hapus key
  `notification` + `android.notification`), data = title/message/image_url/action/external_url,
  `android.priority: high`. image_url divalidasi http(s).
- ⚠️ URUTAN DEPLOY: APK v2.6.0+29 rilis & terverifikasi DULU, baru deploy MasterPanel.
  APK lama (<2.6.0) tidak menampilkan data-only saat app tertutup (background handler
  hanya log) — push akan "hilang" bagi user yang belum update.

### Matriks perilaku setelah ini live (server data-only)
| Status app | Tampilan notifikasi |
|---|---|
| Foreground | Dart onMessage → flutter_local_notifications (style standar) |
| Background / tertutup | `JagatFilmMessagingService` → custom DramaBox-style ✅ |

### Catatan
- Tap notifikasi custom saat app tertutup → cold start → MainActivity tulis prefs →
  konsumsi action di startup (navigasi). Tap saat app background (warm) → action tersimpan,
  dikonsumsi pada startup berikutnya — KONSISTEN dengan perilaku semua notifikasi saat ini.
