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
- Integrasi APK: ✅ deployed pada v1.0.4+5 (commit `f237ba1`, CI analyze/build/deploy sukses).
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
- [ ] Notifikasi lokal dari panel admin (flutter_local_notifications + permission_handler, TANPA Firebase)
- [ ] Analytics integration (custom endpoint, bukan Firebase)
- [x] Admin panel + integrasi Remote Config APK — deployed v1.0.4+5
- [ ] Google Sign-In via OAuth 2.0 Web Flow (tanpa Firebase, tanpa google_sign_in package)
- [ ] PWA & Offline Support
- [ ] Watch History & Favorit (localStorage)
- [ ] Redis Cache (ganti file cache website)
- [ ] Monetisasi (Adsterra/AdSense)
- [ ] FCM Push Notification (Fase 2, butuh Firebase setup dari owner)

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
### Status: DEPLOYED ✅ — v1.0.4+5, commit `f237ba1`
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
- GitHub Actions run `32644795604`: analyze, signed release build, dan deploy sukses.
- APK publik v1.0.4+5 terverifikasi identik dengan file server dan Cloudflare `BYPASS`.

### Validasi Perangkat yang Masih Disarankan
1. Fresh install v1.0.4+5.
2. Upgrade dari v1.0.3.
3. Uji popup sekali per sesi, maintenance retry, action, dan force update secara terkontrol.

---

## UPDATE v1.0.5+6 — CUSTOM LAUNCHER ICON + SPLASH 5 DETIK
### Status: IMPLEMENTED LOCALLY ✅ — BELUM COMMIT/DEPLOY
### Tanggal: 23 Agustus 2026

### Launcher Icon
- Sumber: logo HTTPS dari MasterPanel, PNG RGBA 1024x1024.
- Legacy mipmap: 48/72/96/144/192 px untuk mdpi sampai xxxhdpi.
- Adaptive foreground: 108/162/216/324/432 px dengan padding 72%.
- Adaptive background: `#081633`.
- Artwork Play Store: 512x512.
- Canonical resource: `branding/launcher_icon/res/`.
- Workflow menyalin resource setelah `flutter create`, sehingga ikon tidak kembali ke default Flutter.

### Splash Screen
- Branded Flutter splash tampil selama minimal 5 detik sejak startup.
- Fetch config dibatasi 2 detik per endpoint (primary + fallback), sehingga dua percobaan selesai dalam jendela splash 5 detik.
- Setelah durasi selesai, splash hilang dan aplikasi masuk ke maintenance gate atau shell utama sesuai Remote Config.
- Error config/image tetap menggunakan fallback aman dan tidak menyebabkan crash.

### Status Rilis
- Versi: `1.0.5+6` → deployed, commit `0aa9eae`, Actions run `32646131587` sukses.
- Versi: `1.0.6+7` → deployed, commit `28f7ef6`, Actions run `32647061863` sukses.
  - Fix: splash screen bersih tanpa logo overlay, tanpa spinner, murni `splash_image_url` fullscreen 5 detik.

---

## BLUEPRINT: NOTIFIKASI APK (DIRENCANAKAN)
### Tanggal diskusi: 23 Agustus 2026
### Status: PLANNING — belum dikerjakan

### Konsep
- User menerima notifikasi di notification bar HP tentang drama baru, event, dan promosi.
- Admin kirim notifikasi dari MasterPanel; app menampilkannya sebagai local notification.
- Mirip DramaBox/ReelShort: saat install pertama, minta izin notifikasi mengambang.

### Fase 1 — Local Notification (TANPA Firebase, aman)

#### Alur:
1. Install/update pertama → dialog izin `POST_NOTIFICATIONS` (Android 13+).
2. Panel admin (`masterpanel.jagatfilm.com`) buat notifikasi: judul, pesan, gambar, action, tanggal.
3. Endpoint baru: `GET /api/notifications` → daftar notifikasi aktif.
4. Setiap app dibuka → fetch daftar notifikasi → bandingkan dengan yang sudah ditampilkan (simpan ID di SharedPreferences).
5. Notifikasi baru → tampilkan local notification di status bar via `flutter_local_notifications`.
6. User tap → buka app ke halaman target (page:home/search/detail/update/login atau URL external).

#### Dependency APK:
- `flutter_local_notifications` — package stabil, tidak butuh Firebase/google-services.json.
- `permission_handler` — untuk request POST_NOTIFICATIONS secara eksplisit.
- TIDAK menambahkan Firebase SDK, FCM, atau google-services.json.

#### Panel Admin (MasterPanel):
- Halaman baru: Kelola Notifikasi
- CRUD: judul, pesan, image_url, action (sama seperti popup: page:xxx atau external URL), tanggal publish, aktif/nonaktif.
- Endpoint: `GET /api/notifications` (public, APK fetch), `POST/PUT/DELETE /api/notifications` (admin only).

#### Data notifikasi:
```json
{
  "id": "notif-001",
  "title": "Drama Baru! 🎬",
  "message": "Tonton serial terbaru minggu ini",
  "image_url": "https://...",
  "action": "page:home",
  "published_at": "2026-08-23T10:00:00Z",
  "active": true
}
```

#### Batasan Fase 1:
- Notifikasi hanya muncul saat user buka app (bukan real-time saat app tertutup).
- Cukup untuk promosi berkala dan event.
- Aman: jika endpoint gagal/offline, tidak ada notifikasi → tidak crash.

### Fase 2 — FCM Real-Time Push (nanti, butuh owner)

#### Prasyarat (owner harus setup):
1. Buat Firebase project di console.firebase.google.com.
2. Daftarkan app Android: `com.jagatfilm.jagatfilm`.
3. Daftarkan SHA-1 fingerprint keystore.
4. Download `google-services.json`.
5. Encode base64 dan tambah sebagai GitHub Secret.
6. Beri Client ID / Server Key ke Kiro.

#### Fitur:
- Push notification real-time saat app tertutup/background.
- Panel admin trigger FCM ke semua device atau segment tertentu.
- Topik/channel: drama baru, event, promo.

#### ⚠️ Aturan:
- JANGAN implementasi Fase 2 sebelum owner selesai setup Firebase.
- JANGAN tambahkan `firebase_messaging` tanpa `google-services.json` → CRASH.
- Fase 1 harus stabil dulu sebelum Fase 2.

### Prioritas Eksekusi Fase 1:
1. Tambah dependency `flutter_local_notifications` dan `permission_handler` ke pubspec.
2. Buat permission request dialog saat pertama buka.
3. Buat endpoint `/api/notifications` di MasterPanel.
4. Buat halaman kelola notifikasi di dashboard MasterPanel.
5. Buat service di APK: fetch, filter yang belum ditampilkan, trigger local notification.
6. Action handler: tap notifikasi → navigasi ke halaman/URL.
7. Bump versi, push, build, deploy, tes.

### Pembagian Tugas:
| Siapa | Tanggung Jawab |
|-------|---------------|
| Kiro (AI) | Semua kode APK + panel: permission, service, endpoint, UI dashboard, notifikasi lokal |
| Owner | Fase 2: setup Firebase project, google-services.json, beri credentials ke Kiro |

---

## BLUEPRINT: ADMIN PANEL V2 + EKONOMI KOIN (DIRENCANAKAN)
### Tanggal diskusi: 23 Agustus 2026
### Status: PLANNING — belum dikerjakan

### Keputusan Teknologi
- **Ad Network:** Adsterra (utama, approve cepat). AdMob sebagai backup setelah traffic stabil.
- **Database:** PostgreSQL lokal (port 5432, sudah tersedia di VPS). Gratis, nol latency, nol limit.
- **Panel:** MasterPanel Next.js 14 di `masterpanel.jagatfilm.com` (sudah ada, akan di-redesign).
- **Backend API:** endpoint baru di MasterPanel atau service terpisah di port lain jika perlu.

### Model Bisnis
- User nonton rewarded ads → dapat koin.
- Revenue admin: $1 per 1000 tayangan iklan.
- Revenue sharing ke user: $0.25–$0.50 per 1000 tayangan (dalam bentuk koin).
- Koin bisa dicairkan ke Rupiah (e-wallet/transfer).
- Admin untung selisih antara revenue iklan dan pembayaran ke user.

### Struktur Panel Admin (MasterPanel V2)
```
├── 📊 Dashboard Overview
│   ├── Total users, DAU, revenue hari ini
│   ├── Koin beredar vs dicairkan
│   └── Grafik ringkas
├── 📢 Notifikasi
│   ├── CRUD notifikasi (judul, pesan, gambar, action, jadwal)
│   └── Riwayat notifikasi terkirim
├── 🎬 Konten
│   ├── Featured Drama (pilih manual untuk slider)
│   ├── Banner Management
│   └── Provider On/Off
├── 💰 Ekonomi Koin
│   ├── Konfigurasi Rate (koin per iklan, rate Rp per koin)
│   ├── Rewarded Ads Settings (placement, frekuensi, cooldown)
│   ├── Withdrawal Config (minimum, fee, max per hari)
│   └── Withdrawal Requests (approve/reject, history)
├── 📋 Tugas Harian
│   ├── CRUD Misi (nonton X drama, login, share, invite, dll)
│   ├── Reward per misi
│   └── Reset schedule (harian/mingguan)
├── 👥 User Management
│   ├── Daftar user + saldo koin
│   ├── Ban/unban
│   ├── Manual adjustment koin
│   └── Transaction history per user
├── 📈 Analytics
│   ├── DAU/MAU/retention
│   ├── Top drama ditonton
│   ├── Revenue iklan harian
│   └── Koin diberikan vs dicairkan
├── ⚙️ Pengaturan
│   ├── Remote Config (branding, popup, maintenance — sudah ada)
│   ├── App Version Control (sudah ada)
│   ├── Adsterra Config (Zone ID, dll)
│   └── VIP/Membership Tier (nanti)
└── 🔔 Push Notification (Fase 2 FCM — nanti)
```

### Database Schema (PostgreSQL Lokal)
```sql
-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  display_name VARCHAR(100),
  password_hash VARCHAR(255),
  provider VARCHAR(20) DEFAULT 'email',
  coin_balance INTEGER DEFAULT 0,
  is_vip BOOLEAN DEFAULT FALSE,
  is_banned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);

-- Coin Transactions
CREATE TABLE coin_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  type VARCHAR(30) NOT NULL, -- 'ad_reward', 'mission', 'daily_login', 'withdrawal', 'admin_adjust'
  amount INTEGER NOT NULL, -- positif = masuk, negatif = keluar
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Withdrawal Requests
CREATE TABLE withdrawals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  amount_coins INTEGER NOT NULL,
  amount_rupiah DECIMAL(12,2) NOT NULL,
  method VARCHAR(30), -- 'dana', 'gopay', 'ovo', 'bank_transfer'
  account_info TEXT,
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'paid'
  admin_note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

-- Daily Missions
CREATE TABLE missions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(200) NOT NULL,
  description TEXT,
  type VARCHAR(30) NOT NULL, -- 'watch_drama', 'watch_episodes', 'daily_login', 'share', 'invite'
  target INTEGER DEFAULT 1, -- berapa kali harus dilakukan
  reward_coins INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  reset_period VARCHAR(10) DEFAULT 'daily', -- 'daily', 'weekly', 'once'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Mission Progress
CREATE TABLE user_missions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  mission_id UUID REFERENCES missions(id),
  progress INTEGER DEFAULT 0,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  reset_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(200) NOT NULL,
  message TEXT,
  image_url TEXT,
  action VARCHAR(200), -- 'page:home', 'page:search', external URL
  published_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ad Config
CREATE TABLE ad_config (
  id SERIAL PRIMARY KEY,
  network VARCHAR(30) DEFAULT 'adsterra',
  zone_id VARCHAR(100),
  placement VARCHAR(30), -- 'pre_episode', 'post_episode', 'reward_button'
  coins_per_view INTEGER DEFAULT 1,
  cooldown_seconds INTEGER DEFAULT 30,
  max_daily_views INTEGER DEFAULT 50,
  is_active BOOLEAN DEFAULT TRUE
);

-- Featured/Banner Content
CREATE TABLE featured_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type VARCHAR(20) NOT NULL, -- 'featured_drama', 'banner'
  drama_id VARCHAR(100),
  image_url TEXT,
  action VARCHAR(200),
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Prioritas Eksekusi
1. **Setup PostgreSQL** — buat database, user, dan schema.
2. **Redesign MasterPanel** — sidebar profesional, layout responsif, halaman skeleton.
3. **Notifikasi** — CRUD + endpoint (fitur pertama yang aktif penuh).
4. **Content Management** — featured drama, banner.
5. **User Management** — register/login real backend, saldo koin.
6. **Rewarded Ads** — Adsterra integration config.
7. **Tugas Harian** — CRUD misi.
8. **Withdrawal** — request + approval.
9. **Analytics Dashboard** — visualisasi data.

### Aturan
- Panel admin harus profesional: sidebar, dark mode, responsif.
- Setiap halaman baru harus berfungsi independen — jika satu fitur belum siap, fitur lain tetap jalan.
- Database migration harus incremental (bisa tambah tabel tanpa rusak yang sudah ada).
- API endpoint harus dilindungi auth session (admin only) kecuali yang ditandai public.
- APK fitur ekonomi koin TIDAK boleh dikerjakan sebelum backend dan panel siap.
