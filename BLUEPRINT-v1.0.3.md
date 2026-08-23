# JagatFilm APK - Blueprint Update v1.0.3+4
### Tanggal diskusi: 23 Agustus 2026
### Status: COMPLETED ✅ — Pushed commit 97171c3 (23 Aug 2026)

---

## MASALAH YANG DITEMUKAN:

### 1. Video Player Zoom/Crop (CONFIRMED)
- BoxFit.cover di FittedBox → video di-zoom, subtitle terpotong
- File: lib/screens/player_screen.dart → _buildVideoFullscreen()

### 2. Video Player Controls Terlalu Kecil
- Saat tap di tengah layar, muncul 3 tombol (rewind, pause, forward) tapi SANGAT KECIL
- Tidak proporsional karena video di-zoom dalam FittedBox
- Owner ingin: double-tap di tengah = pause (bukan 3 tombol kecil)
- Perlu redesign kontrol player: gesture-based, bukan tombol kecil

### 3. App Crash Setelah Install Update
- User download APK baru → install → buka → MOGOK
- Terjadi berulang kali
- Kemungkinan: startup logic error, data migration, atau Android cache issue
- main.dart sudah ada runZonedGuarded tapi mungkin belum cover semua

### 4. Update Checker Tidak Sync (CONFIRMED - ROOT CAUSE FOUND)
- HP versi 1.0.2 build 3 == server version.json 1.0.2 versionCode 3 → SAMA
- Masalah: developer tidak bump version sebelum build baru
- URL tanpa www → 301 redirect → Flutter http mungkin tidak follow
- Jika getUpdateInfo() return null → langsung set "up to date" (SALAH)
- APK di-cache Cloudflare 4 jam (max-age=14400) → user bisa download APK lama

### 5. Cloudflare Cache Issue
- version.json: no-cache, must-revalidate (OK)
- app-release.apk: max-age=14400 (4 jam cache) → MASALAH user download APK lama

---

## BLUEPRINT v1.0.3+4:

### A. Fix Video Player — Fullscreen Tanpa Zoom
- Ganti BoxFit.cover → BoxFit.contain
- Video proporsional, subtitle utuh, black bars di sisi kosong
- Tetap portrait/fullscreen TikTok-style

### B. Redesign Player Controls (Gesture-based)
- Hapus/hide 3 tombol kecil default Chewie (rewind/pause/forward)
- Double-tap tengah = pause/play
- Double-tap kiri layar = mundur 10 detik
- Double-tap kanan layar = maju 10 detik
- Single tap = show/hide overlay (judul, episode, progress bar)
- Swipe atas = next episode (sudah ada)
- Swipe bawah = prev episode (sudah ada)
- Progress bar tetap ada di overlay bawah
- Referensi UX: TikTok, ReelShort, DramaBox

### C. Fix Update Checker
- Ganti URL ke https://www.jagatfilm.com/app/version.json (no redirect)
- Tambah ?t=timestamp untuk bypass cache
- Pisahkan: null = error (tampilkan "gagal cek"), version sama = "up to date"
- WAJIB bump version di pubspec.yaml setiap push update baru

### D. Fix Crash Setelah Update
- Review semua startup logic di main.dart, HomeScreen, AuthService
- Tambah migration check (clear incompatible cache saat version naik)
- Delay/skip checkForUpdate pada fresh install/upgrade
- Pastikan semua initState wrapped dalam try-catch
- Test scenario: install baru → langsung buka

### E. Fix Cloudflare Cache APK
- Set no-cache/no-store untuk /download/app-release.apk via Nginx config
- Atau: tambah query string ?v=versionCode di apk_url field
- Purge CF cache otomatis di workflow setelah deploy

### F. Workflow Improvement
- Setiap push: WAJIB bump pubspec.yaml version terlebih dahulu
- version.json auto-generated dari pubspec (sudah ada di workflow)
- Changelog dari commit message (auto-extract)

---

## FITUR BARU (DIRENCANAKAN):

### G. Analytics / Tracking Pengunjung APK
- Owner ingin tahu: jumlah user, detail device, session, retention
- Opsi yang dipertimbangkan:
  1. Firebase Analytics — gratis, lengkap, tapi butuh google-services.json (risk crash)
  2. Custom analytics API — kirim event ke server sendiri (aman, full kontrol)
  3. Mixpanel/Amplitude — third party, freemium
- Rekomendasi: Custom analytics endpoint (paling aman, no native dependency risk)
  - POST /app/analytics → log device, version, screen, event
  - Dashboard sederhana untuk lihat data
- Data yang di-track: device model, OS version, app version, screen views, play events

### H. Admin Panel (Remote Config untuk APK) — ✅ DEPLOYED
- URL: https://masterpanel.jagatfilm.com
- Login: Google OAuth (mr.harrasnaufal@gmail.com) atau manual (masteradminjagatfilm)
- Tech: Next.js 14, port 3004, PM2 "masterpanel"
- Config API: https://masterpanel.jagatfilm.com/api/config (public, APK fetch)
- Fitur dashboard:
  - 🎨 Branding: logo_url, splash_image_url
  - 📢 Popup: enabled, title, message, image, action (page:home/search/profile/update/login atau external URL), duration (detik)
  - 🔧 Maintenance: mode on/off, custom message
  - 📋 Announcement: teks banner
  - 📱 Update Control: force_update, min_version

#### ATURAN POPUP DI APK:
- Popup muncul **SEKALI saat buka app** (per sesi)
- Otomatis **hilang setelah X detik** (dari popup_duration di config)
- Kalau user tutup app dan buka lagi → popup tampil lagi sekali
- TIDAK muncul berkali-kali selama 1 sesi
- Action: navigasi ke halaman dalam app (page:xxx) BUKAN buka URL external
- Kalau action = "external" → baru buka browser
- Integrasi APK: ✅ diimplementasikan lokal untuk v1.0.4+5; pending commit, CI build, deploy, dan tes perangkat.
- Endpoint utama: `https://masterpanel.jagatfilm.com/api/config`.
- Endpoint fallback: `https://www.jagatfilm.com/app/config.json`.
- Jika kedua endpoint gagal/JSON rusak: APK memakai default aman (maintenance, popup, dan force update mati).
- Keputusan: Custom web panel (bukan Firebase Remote Config).

### I. Google Sign-In (Tanpa Firebase)
- JANGAN pakai Firebase Auth atau google_sign_in package (history crash)
- Gunakan OAuth 2.0 Web Flow:
  - Buka Google OAuth URL di WebView/browser
  - User login → dapat authorization code
  - Backend verify & exchange → dapat user info (email, nama, foto)
  - Simpan session di app
- Butuh: Google Cloud Console → OAuth 2.0 credentials (Web Application type)
- Zero native dependency — murni HTTP, tidak bisa crash
- Implementasi: versi selanjutnya (setelah v1.0.3 stable)

#### ⚠️ ATURAN GOOGLE OAUTH:
- **Owner yang buat project di Google Cloud Console & OAuth credentials**
- **Kiro (AI) yang handle semua kode & integrasi — WAJIB tidak boleh crash**
- **Jika butuh sesuatu dari owner (credentials, Client ID, redirect URI, dll) → TANYA & SURUH OWNER BUAT DULU**
- **JANGAN assume credentials sudah ada — selalu konfirmasi**
- **Tanggung jawab Kiro: kode aman, no crash, no native dependency risk**
- **Tanggung jawab Owner: setup Google Cloud Console, buat OAuth credentials, kasih Client ID & Secret**

---

## PRIORITAS EKSEKUSI v1.0.3:
1. Bump version ke 1.0.3+4 di pubspec.yaml
2. Fix video player (BoxFit.contain) — no zoom
3. Redesign player controls (gesture-based, double-tap)
4. Fix update checker (URL www, null handling, cache bust)
5. Fix crash after update (startup safety, migration)
6. Fix Cloudflare cache (Nginx header / query string)
7. Push → Build → Deploy → Test di HP

## BACKLOG (v1.1.0+):
- [ ] Analytics integration (custom endpoint, bukan Firebase)
- [~] Admin panel deployed + integrasi Remote Config APK v1.0.4+5 sudah lokal; pending CI/deploy
- [ ] Google Sign-In via OAuth 2.0 Web Flow (tanpa Firebase, tanpa google_sign_in package)
- [ ] PWA & Offline Support
- [ ] Watch History & Favorit (localStorage)
- [ ] Redis Cache (ganti file cache website)
- [ ] Monetisasi (Adsterra/AdSense)

---

## CATATAN PENTING:
- JANGAN pakai Firebase SDK langsung (risk crash tanpa google-services.json)
- JANGAN pakai kotlinOptions (deprecated, pakai compilerOptions)
- JANGAN overwrite build.gradle.kts yang Flutter generate
- Setiap update WAJIB bump version di pubspec.yaml SEBELUM push
- Test mental checklist SEBELUM push (lihat progress.md aturan)

## PEMBAGIAN TUGAS:
| Siapa | Tanggung Jawab |
|-------|---------------|
| Kiro (AI) | Semua kode, integrasi, konfigurasi. WAJIB tidak crash. |
| Owner | Setup external services (Google Cloud, subdomain, DNS, credentials) |

### Aturan Kiro:
- Jika butuh sesuatu yang harus owner setup → TANYA DULU, suruh owner buat
- JANGAN assume resource/credentials sudah ada
- JANGAN langsung pilih subdomain/URL tanpa konfirmasi owner
- Semua kode yang disentuh HARUS aman — crash = gagal
- Jika ragu apakah suatu dependency aman → JANGAN pakai, cari alternatif

---

## UPDATE v1.0.4+5 — MASTERPANEL REMOTE CONFIG
### Status: IMPLEMENTED LOCALLY ✅ — BELUM COMMIT/DEPLOY
### Tanggal: 23 Agustus 2026

### Implementasi APK
- `AppRemoteConfig`: parsing dan sanitasi URL HTTP(S), bool, text, action, durasi 2–30 detik, serta minimum version.
- `RemoteConfigService`: primary MasterPanel → fallback `www.jagatfilm.com/app/config.json` → default aman.
- Startup menampilkan splash remote secara aman; image error kembali ke branding bawaan.
- Maintenance gate memblokir shell aplikasi dan menyediakan tombol retry config.
- Logo dan announcement dari panel tampil di Home.
- Popup tampil maksimal sekali per proses/sesi, auto-close, dan mendukung `page:home/search/profile/update/login` atau external HTTP(S).
- `force_update` + `min_version` memakai perbandingan versi numerik; dialog force non-dismissible dan URL APK memiliki fallback.
- Auto update lama tetap aktif tetapi diurutkan setelah minimum-version dan popup agar dialog tidak bertumpuk.
- Versi lokal dinaikkan dari `1.0.3+4` ke `1.0.4+5`.

### File Baru
- `lib/models/app_remote_config.dart`
- `lib/services/remote_config_service.dart`
- `lib/screens/maintenance_screen.dart`
- `lib/widgets/remote_config_popup.dart`
- `test/remote_config_test.dart`

### Validasi
- Kedua endpoint config: HTTP 200, seluruh 14 key tersedia.
- `git diff --check`: lulus.
- Relative Dart imports: seluruhnya resolve.
- Delimiter/trailing-whitespace check: lulus pada semua file yang disentuh.
- Audit independen: `NO_BLOCKING_ISSUES`.
- Test ditambahkan untuk parsing/sanitasi, fallback endpoint, default aman, dan semantic version comparison.
- ⚠️ Flutter/Dart SDK dan Docker/Podman tidak tersedia di VPS; `dart format`, `flutter analyze`, `flutter test`, dan build harus dijalankan GitHub Actions setelah commit/push.

### Langkah Rilis Berikutnya
1. Review diff final.
2. Commit source secara eksplisit setelah persetujuan owner.
3. Push `main` agar GitHub Actions menjalankan analyze + signed release build + deploy.
4. Verifikasi APK `1.0.4+5` di HP: fresh install, upgrade dari 1.0.3, popup sekali, maintenance retry, action, dan force update.
