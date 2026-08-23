# BLUEPRINT UI/UX — JagatFilm APK Redesign v2.0

> Referensi: DramaBox (11 screenshot) | Target: Level produksi setara DramaBox
> Tanggal: 2026-08-23 | Status: BLUEPRINT FINAL

---

## 1. Ringkasan Redesign

### Apa yang berubah:

| Aspek | Sebelum | Sesudah |
|-------|---------|---------|
| Bottom Navigation | Tidak ada (hanya drawer/push) | 5 tab: Beranda, Untuk Anda, Koin, Daftarku, Profil |
| Tab Kategori | Tidak ada | 4 tab atas: Untukmu, Terbaru, Peringkat, Kategori |
| Layout Grid | Grid sederhana 2 kolom | Multi-layout: 3-col grid, list vertikal, ranking, masonry |
| Card Design | Basic card (cover + title) | Rich card: badge, views, genre pill, ranking tag |
| Halaman Koin | Tidak ada | Full reward center (ads + misi) |
| Daftarku | Tidak ada | Watchlist + Riwayat Tontonan |
| Search | Basic text field | Full search + trending + suggestions |
| Profil | Minimal login/logout | Full profile: avatar, stats, menu, settings |
| Theme | Dark basic | Dark premium (#0D0D0D base) |

### Prinsip Desain:
- **Dark-first**: Background #0D0D0D, surface #1A1A1A, card #242424
- **Aksen Pink**: #FF2D55 untuk CTA, badge aktif, highlight
- **Sekunder Ungu**: #6C63FF untuk badge provider, secondary actions
- **Content-first**: Poster drama adalah hero, UI minimal chrome
- **Fault-tolerant**: Semua fetch wrapped try-catch, graceful fallback

---

## 2. Struktur Navigasi Baru

### 2.1 Bottom Navigation Bar

```
┌─────────────────────────────────────────────────┐
│  🏠 Beranda  │  ✨ Untuk Anda  │  🪙 Koin  │  📋 Daftarku  │  👤 Profil  │
└─────────────────────────────────────────────────┘
```

| Index | Label | Icon | Screen |
|-------|-------|------|--------|
| 0 | Beranda | `Icons.home_rounded` | `HomeScreen` |
| 1 | Untuk Anda | `Icons.auto_awesome` | `ForYouScreen` |
| 2 | Koin | `Icons.monetization_on_rounded` | `CoinScreen` |
| 3 | Daftarku | `Icons.bookmark_rounded` | `WatchlistScreen` |
| 4 | Profil | `Icons.person_rounded` | `ProfileScreen` |

**Spesifikasi Bottom Nav:**
- Height: 64dp (termasuk safe area)
- Background: #1A1A1A dengan border-top 0.5px #333333
- Icon size: 24dp, label font: 10sp
- Active: icon + label #FF2D55, Inactive: #888888
- Animasi: scale 1.0 → 1.1 pada active icon (150ms ease)
- Badge dot merah pada Koin jika ada reward unclaimed

### 2.2 Tab Kategori Atas (Beranda only)

```
┌──────────────────────────────────────────────┐
│  Untukmu  │  Terbaru  │  Peringkat  │  Kategori  │
└──────────────────────────────────────────────┘
```

- Widget: `TabBar` + `TabBarView` dengan `PageView`
- Tab style: Scrollable, font 14sp medium
- Active: #FFFFFF + underline 3px #FF2D55
- Inactive: #888888
- Swipeable antar tab

### 2.3 Routing Map

```
/                       → MainShell (bottom nav wrapper)
/home                   → Beranda (tab 0)
/home/untukmu           → Tab Untukmu
/home/terbaru           → Tab Terbaru
/home/peringkat         → Tab Peringkat
/home/kategori          → Tab Kategori
/foryou                 → Untuk Anda (tab 1)
/coin                   → Koin Center (tab 2)
/watchlist              → Daftarku (tab 3)
/profile                → Profil (tab 4)
/drama/:id              → Detail Drama (push)
/player/:id/:episode    → Player (push, fullscreen)
/search                 → Search (push)
/login                  → Login (push)
/settings               → Settings (push)
```

---

## 3. Desain Per Halaman

### 3.1 BERANDA — Tab 'Untukmu'

**Header Area (fixed, tidak scroll):**
```
┌─────────────────────────────────────────────┐
│ [Logo 28px]   [🔍 Search]   [🪙+60 badge]  │
└─────────────────────────────────────────────┘
│  Untukmu  │  Terbaru  │  Peringkat  │  Kategori │
```

- Logo: dari remote config `logoUrl`, fallback text "JagatFilm"
- Search icon: tap → push `/search`
- Koin icon: lingkaran emas 🪙 + badge merah "+60" jika ada reward, tap → `/coin`
- Announcement banner (jika ada dari remote config): strip kuning/pink, 1 baris, dismissible

**Body (ScrollView):**

**Section A — Grid Drama Populer (3 kolom)**
```
┌────────┐ ┌────────┐ ┌────────┐
│ POSTER │ │ POSTER │ │ POSTER │
│ badge  │ │ badge  │ │ badge  │
│ views  │ │ views  │ │ views  │
├────────┤ ├────────┤ ├────────┤
│ Title  │ │ Title  │ │ Title  │
│ Genre  │ │ Genre  │ │ Genre  │
└────────┘ └────────┘ └────────┘
```

- Grid: `SliverGrid` crossAxisCount=3, spacing 10dp, childAspectRatio 0.52
- Card spec:
  - Poster: rounded 10dp, aspect ratio 3:4
  - Badge kiri-atas: "Terpopuler" (#FF2D55), "Terbaru" (#4CAF50), atau provider name (#6C63FF)
  - Views kanan-bawah overlay: icon eye + "5.8M" (format compact)
  - Title: 12sp medium, max 2 lines, #FFFFFF
  - Genre: 10sp, #888888, max 1 line
- Data: pertama 9 item dari API response
- Shimmer loading: 9 placeholder cards

**Section B — Rekomendasi Populer (2 kolom masonry)**

Header: "Rekomendasi Populer" 16sp bold + "Lihat Semua >" link

```
┌───────────────┐ ┌───────────────┐
│               │ │   POSTER      │
│  BIG POSTER   │ │   views       │
│  views        │ │   title       │
│  title        │ │   genre       │
│  genre pill   │ ├───────────────┤
├───────────────┤ │ GENRE BLOCK   │
│   POSTER      │ │ ┌──┐┌──┐     │
│   views       │ │ │  ││  │     │
│   title       │ │ └──┘└──┘     │
│   genre       │ │ ┌──┐┌──┐     │
└───────────────┘ │ │  ││  │     │
                  │ └──┘└──┘     │
                  └───────────────┘
```

- Layout: `flutter_staggered_grid_view` — StaggeredGrid.count crossAxisCount=2
- Card heights bervariasi: 220dp, 280dp, 180dp (staggered)
- Ranking tag: "TOP 1" strip merah diagonal di corner
- Genre Block (setiap 6 cards, ganti 1 slot):
  - Background: gradient warna genre (marun #8B0000 → transparent)
  - Heading: nama genre 14sp bold + chevron right
  - 4 mini thumbnails: 2×2 grid, 48×64dp, rounded 6dp
  - Tap → filter kategori genre tersebut

**Section C — Provider Spotlight (horizontal scroll)**

Header: "Jelajahi Provider" 16sp bold

- Horizontal ListView: card 140×200dp
- Setiap card: provider logo/icon + nama + jumlah drama
- Tap → filter kategori provider tersebut

**Behavior:**
- Pull-to-refresh: `RefreshIndicator`
- Infinite scroll: load page 2, 3... saat mendekati bottom
- Error state: ilustrasi + "Gagal memuat" + tombol "Coba Lagi"
- Empty state: ilustrasi + "Belum ada drama"

---

### 3.2 BERANDA — Tab 'Terbaru'

**Sub-tab:**
```
┌──────────────────────────────────┐
│ [● Sudah Tayang]  [Akan Tayang]  │
└──────────────────────────────────┘
```
- Pill toggle: aktif = filled #FF2D55, inactive = outline #444444
- Height: 32dp, rounded 16dp, font 12sp

**Layout: List Vertikal**
```
┌──────────────────────────────────────────────┐
│ ┌────────┐  23/08                            │
│ │ POSTER │  Judul Drama Yang Panjang         │
│ │ 3:4    │  Sinopsis dua baris maksimum...   │
│ │        │  [Terbaru TOP 3]  64 Ep  ▶ 2.1M  │
│ └────────┘                                   │
├──────────────────────────────────────────────┤
```

- Item height: ~120dp
- Poster: 80×107dp (3:4), rounded 8dp, kiri
- Tanggal rilis: 12sp #FF2D55, kanan atas
- Judul: 14sp bold white, max 1 line
- Sinopsis: 12sp #AAAAAA, max 2 lines
- Badge "Terbaru TOP N": pill merah kecil
- Episode count: 11sp #888888
- Views: icon eye + angka, 11sp #888888
- Sort: terbaru dulu (dari API sort=latest)
- Pagination: infinite scroll

---

### 3.3 BERANDA — Tab 'Peringkat'

**Filter Pills (horizontal scroll):**
```
[● Terpopuler]  [Paling Dicari]  [Terbaru]
```
- Pill style: aktif = #FF2D55 filled, inactive = #333333 filled, text white

**Header gradient:** Top 80dp gradient dari #2D1B00 → transparent (warm amber tone)

**Ranking List:**
```
┌──────────────────────────────────────────────┐
│ 1  ┌────┐  Judul Drama                      │
│    │    │  Romansa · CEO                     │
│    └────┘  🔥 321K                           │
├──────────────────────────────────────────────┤
│ 2  ┌────┐  Judul Drama Lain                 │
│    │    │  Aksi · Balas Dendam               │
│    └────┘  🔥 298K                           │
└──────────────────────────────────────────────┘
```

- Ranking number: 24sp bold, #1 = #FFD700 (gold), #2 = #C0C0C0 (silver), #3 = #CD7F32 (bronze), rest = #666666
- Thumbnail: 56×75dp (3:4), rounded 8dp
- Title: 14sp bold white
- Genre: 12sp #AAAAAA
- Popularitas: icon api + angka, 12sp #FF6B35
- Item #1: background highlight #1F1A10 (subtle gold glow)
- Divider: 0.5px #333333
- Data: API sort by popularity/views

---

### 3.4 BERANDA — Tab 'Kategori'

**Multi-level Filter Area (sticky, scrollable vertically jika banyak):**
```
Provider:  [Semua] [ShortMax] [DramaBox] [ReelShort] [+22 lagi]
Genre:     [Semua] [Romansa] [Aksi] [Komedi] [Thriller] [Horror]
Tema:      [Semua] [Balas Dendam] [CEO] [Keluarga] [Fantasi]
Sort:      [Terpopuler] [Terbaru] [Episode Terbanyak]
```

- Setiap baris: label 12sp #888888 di kiri, lalu horizontal scroll pills
- Pill aktif: #FF2D55 filled, text white
- Pill inactive: #2A2A2A filled, text #CCCCCC
- Pill size: height 28dp, rounded 14dp, padding h:12dp
- Jumlah pill per baris: scrollable, show 4-5 visible
- Provider list: dari API response `providers` map (25 provider)
- Genre list: hardcoded dari data yang umum: Romansa, Aksi, Komedi, Thriller, Horror, Fantasi, Drama, Misteri
- Tema list: Balas Dendam, CEO, Keluarga, Sekolah, Supernatural, Historis

**Hasil Grid:** Sama seperti grid 3 kolom di Untukmu
- Infinite scroll
- Show count: "320 drama ditemukan" di atas grid, 12sp #666666
- Loading: shimmer grid

---

### 3.5 UNTUK ANDA (Bottom Nav Tab 1)

**Konsep:** Feed personal TikTok-style cards — drama yang belum ditonton, berdasarkan riwayat genre/provider preference.

**Layout: Full-width vertical feed**
```
┌─────────────────────────────────────┐
│ ┌─────────────────────────────────┐ │
│ │                                 │ │
│ │      POSTER BESAR (16:9)       │ │
│ │                                 │ │
│ │  [▶ Tonton]                     │ │
│ └─────────────────────────────────┘ │
│ Judul Drama Yang Menarik            │
│ Romansa · CEO · 64 Episode          │
│ Sinopsis singkat drama ini...       │
│ [♥ Simpan]  [↗ Share]              │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │      POSTER BESAR (16:9)       │ │
│ ...                                 │
└─────────────────────────────────────┘
```

- Card: full-width, margin 12dp horizontal, 8dp vertical
- Poster: 16:9 `coverHorizontal` (fallback to `cover` cropped), rounded 12dp
- Overlay gradient bawah: untuk readability title
- Tombol "▶ Tonton": pill pink #FF2D55, 12sp bold, posisi kanan-bawah poster
- Title: 16sp bold white
- Meta: 12sp #AAAAAA
- Sinopsis: 13sp #CCCCCC, max 2 lines
- Actions row: Simpan (heart outline), Share (native share)
- Pull-to-refresh: shuffle rekomendasi baru
- Jika belum login: tampilkan rekomendasi random, setelah login prioritaskan genre yang sering ditonton

**Header:**
```
┌─────────────────────────────────────┐
│ Untuk Anda               [⚙ Filter] │
└─────────────────────────────────────┘
```
- Filter: bottom sheet pilih genre preference

---

### 3.6 HALAMAN KOIN / REWARD CENTER (Bottom Nav Tab 2)

> CATATAN: Backend koin BELUM ada. UI dibuat lengkap, fungsi tombol show "Coming Soon" snackbar atau disabled state. Siap diaktifkan saat backend ready.

**Header Area:**
```
┌─────────────────────────────────────────┐
│          🪙 Koin Saya                   │
│            0 Koin                        │
│    [💰 Isi Ulang]  [📜 Riwayat]         │
└─────────────────────────────────────────┘
```
- Background: gradient #1A1A2E → #0D0D0D
- Koin angka: 32sp bold #FFD700 (gold)
- Tombol Isi Ulang: outline gold, Riwayat: outline white

**Section: Dapatkan Koin Gratis**
```
┌─────────────────────────────────────────┐
│ 🎬 Tonton Iklan          +10 🪙  [▶]   │
├─────────────────────────────────────────┤
│ 📅 Login Harian          +5 🪙   [✓]   │
├─────────────────────────────────────────┤
│ 🎯 Tonton 3 Episode      +15 🪙  [2/3] │
├─────────────────────────────────────────┤
│ ⭐ Review di Play Store   +50 🪙  [→]   │
├─────────────────────────────────────────┤
│ 🔗 Undang Teman          +100 🪙 [→]   │
└─────────────────────────────────────────┘
```

- List tiles: icon kiri, judul, reward kanan gold, action button
- Completed: checkmark hijau, disabled
- In-progress: progress text "2/3"
- Action button: pill outline, tap → execute action atau show coming soon
- "Tonton Iklan" → Adsterra rewarded ad (jika SDK ready)

**Section: Cara Pakai Koin**
```
┌─────────────────────────────────────────┐
│ 🔓 Buka Episode Terkunci   5 🪙/ep     │
│ 📥 Download Episode        10 🪙/ep    │
│ 🚫 Hilangkan Iklan 1 Jam   20 🪙       │
└─────────────────────────────────────────┘
```

- Info cards: background #242424, rounded 12dp
- Semua fungsi: "Segera Hadir" badge

**CTA Banner:**
```
┌─────────────────────────────────────────┐
│ 🎬 Tonton Iklan Sekarang — Dapat 10 🪙  │
│        [Tonton Iklan - Gratis]          │
└─────────────────────────────────────────┘
```
- Banner: gradient pink→ungu, text white, rounded 16dp
- CTA button: white filled, text pink

---

### 3.7 DAFTARKU (Bottom Nav Tab 3)

**Tab Bar:**
```
┌──────────────────────────────────────┐
│  [Sedang Ditonton]  [Riwayat]        │
└──────────────────────────────────────┘
```
- Style: underline tab, aktif white + underline #FF2D55

**Tab: Sedang Ditonton (Watchlist)**

Jika login & ada data:
```
┌──────────────────────────────────────────────┐
│ ┌────────┐  Judul Drama                     │
│ │ POSTER │  Episode 12/64                    │
│ │ 3:4    │  ████████░░░░ 18%                │
│ │        │  [▶ Lanjut]  [✕ Hapus]            │
│ └────────┘                                   │
├──────────────────────────────────────────────┤
```

- Item: poster kiri 72×96dp, info kanan
- Progress bar: linear, hijau #4CAF50
- "Lanjut": pill pink, tap → player episode terakhir +1
- "Hapus": icon button grey
- Data: `SharedPreferences` local (key: watchlist_$dramaId)

Jika kosong:
```
┌──────────────────────────────────────────────┐
│         📋                                    │
│   Belum ada drama di daftar                  │
│   Mulai tonton untuk menambahkan             │
│                                              │
│   ── Sedang Tren ──                          │
│   [grid 3 kolom rekomendasi]                 │
└──────────────────────────────────────────────┘
```

Jika belum login:
- Show login CTA bottom sheet (lihat section Login)

**Tab: Riwayat Tontonan**
- List sama seperti Sedang Ditonton tapi tanpa progress bar
- Tambahan: timestamp "Ditonton 2 jam lalu"
- Data: local SharedPreferences (last 50 entries)
- Tombol "Hapus Semua Riwayat" di bottom

---

### 3.8 PROFIL (Bottom Nav Tab 4)

**Header (jika login):**
```
┌─────────────────────────────────────────┐
│                          [🔔] [⚙]       │
│   ┌─────┐                              │
│   │ AVA │  Nama User                    │
│   └─────┘  ID: usr_xxxxx               │
│            Mengikuti: 0                  │
└─────────────────────────────────────────┘
```
- Avatar: 64dp circle, dari Google profile pic (fallback: initial letter)
- Nama: 18sp bold white
- ID: 12sp #888888
- Background: subtle gradient atau poster blur (dari last watched drama)

**Header (jika belum login):**
```
┌─────────────────────────────────────────┐
│                          [🔔] [⚙]       │
│   ┌─────┐                              │
│   │ 👤  │  Login >                      │
│   └─────┘  Masuk untuk sinkronisasi     │
└─────────────────────────────────────────┘
```
- Tap → push LoginScreen

**Koin Banner:**
```
┌─────────────────────────────────────────┐
│ 🪙 Koin Saya: 0        [Dapatkan Koin] │
└─────────────────────────────────────────┘
```
- Background: gradient #2D1B3D (dark purple)
- "Dapatkan Koin": pill pink CTA

**Benefit Grid (2×2):**
```
┌──────────┐ ┌──────────┐
│ 🎬 25    │ │ 🪙 Koin  │
│ Provider │ │ Gratis   │
├──────────┤ ├──────────┤
│ 📥 Unduh │ │ 📺 HD    │
│ Episode  │ │ 1080p    │
└──────────┘ └──────────┘
```
- Card: #242424, rounded 12dp, 80dp tall
- Icon: 24dp, tint #FF2D55
- Text: 11sp white

**Menu List:**
```
┌─────────────────────────────────────────┐
│ 🪙 Dompet Saya          0 Koin    >    │
├─────────────────────────────────────────┤
│ 🎁 Dapatkan Hadiah      +10       >    │
├─────────────────────────────────────────┤
│ 📜 Riwayat Tontonan               >    │
├─────────────────────────────────────────┤
│ 📥 Unduhan                         >    │
├─────────────────────────────────────────┤
│ 🌐 Bahasa               Indonesia >    │
├─────────────────────────────────────────┤
│ ℹ️ Tentang Aplikasi     v1.0.9    >    │
├─────────────────────────────────────────┤
│ 🔄 Cek Pembaruan                   >    │
└─────────────────────────────────────────┘
```
- ListTile: icon kiri 20dp, title 14sp, trailing text 12sp grey + chevron
- Divider: 0.5px #2A2A2A
- "Dompet Saya" → `/coin`
- "Riwayat Tontonan" → `/watchlist` tab riwayat
- "Unduhan" → Coming Soon
- "Bahasa" → bottom sheet pilih bahasa (Indonesia only untuk sekarang)
- "Tentang" → dialog version info
- "Cek Pembaruan" → UpdateScreen yang sudah ada

**Logout Button (jika login):**
- Tombol merah outline, bottom of list
- Konfirmasi dialog sebelum logout

---

### 3.9 PLAYER SCREEN (Existing — Pertahankan + Enhance)

> Player sudah gesture-based. Pertahankan fungsionalitas, tambah beberapa UI element.

**Tambahan UI:**
- Episode counter overlay: "Ep 12/64" top-left, 12sp, semi-transparent bg
- Judul drama overlay: top-center, 14sp bold, fade out setelah 3 detik
- Next episode auto-play: countdown 5 detik di akhir episode
- Koin gate (future): sebelum play episode terkunci, show modal "Gunakan 5 koin" atau "Tonton Iklan"
- Ad insertion point: setiap 3 episode, show Adsterra interstitial (jika SDK ready)
- Swipe up/down: next/prev episode (sudah ada, pertahankan)
- Double tap kiri/kanan: rewind/forward 10s

**Koin Gate Modal (disabled untuk sekarang):**
```
┌─────────────────────────────────────────┐
│       🔒 Episode Terkunci               │
│                                          │
│   Gunakan 5 🪙 untuk membuka            │
│   atau                                   │
│   [🎬 Tonton Iklan - Gratis]            │
│                                          │
│   [Buka dengan Koin]                     │
│   Saldo: 0 🪙                           │
└─────────────────────────────────────────┘
```

---

### 3.10 DETAIL DRAMA

**Layout:**
```
┌─────────────────────────────────────────┐
│ [← Back]              [♥] [↗ Share]     │
│                                          │
│ ┌─────────────────────────────────────┐ │
│ │      COVER HORIZONTAL (16:9)       │ │
│ │         ▶ Tonton                    │ │
│ └─────────────────────────────────────┘ │
│                                          │
│ Judul Drama Lengkap                      │
│ ⭐ Provider · 64 Episode · Romansa       │
│                                          │
│ [Romansa] [CEO] [Balas Dendam]  (pills)  │
│                                          │
│ Sinopsis lengkap drama ini yang bisa...  │
│ [Selengkapnya]                           │
│                                          │
│ ── Episode ──                            │
│ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐         │
│ │ 1 │ │ 2 │ │ 3 │ │ 4 │ │ 5 │ ...     │
│ └───┘ └───┘ └───┘ └───┘ └───┘         │
│                                          │
│ ── Drama Serupa ──                       │
│ [grid 3 kolom]                           │
└─────────────────────────────────────────┘
```

- Cover: full-width 16:9, dari `coverHorizontal` (fallback `cover`)
- Play button: centered overlay, circle 56dp #FF2D55, icon play white
- Title: 20sp bold white
- Meta: 13sp #AAAAAA
- Genre pills: horizontal scroll, #333333 background, text 11sp #FFFFFF
- Sinopsis: 13sp #CCCCCC, max 3 lines collapsed, expandable
- Episode grid: wrap, 5 kolom, setiap cell 48×48dp rounded 8dp
  - Watched: #4CAF50 border
  - Current: filled #FF2D55
  - Locked (future): #333333 + 🔒 icon
  - Normal: #242424
- "Drama Serupa": 3 kolom grid, max 6 items, dari genre yang sama
- Tombol ♥ Simpan: toggle ke watchlist
- Tombol Share: native share link

---

### 3.11 SEARCH SCREEN

**Layout:**
```
┌─────────────────────────────────────────┐
│ [←] [🔍 Cari drama, genre, provider... ] │
├─────────────────────────────────────────┤
│ Pencarian Populer                        │
│ [Romansa] [CEO] [Korea] [China] [Aksi]  │
│                                          │
│ Riwayat Pencarian            [Hapus]     │
│ drama korea terbaru                      │
│ balas dendam ceo                         │
├─────────────────────────────────────────┤
│ (Setelah ketik)                          │
│ Hasil untuk "ceo"                        │
│ [Grid 3 kolom / List hasil]             │
└─────────────────────────────────────────┘
```

- TextField: autofocus, background #242424, rounded 24dp, hint grey
- Debounce: 500ms sebelum fetch
- Trending tags: wrap pills, background #333333
- Results: grid 3 kolom (sama seperti Untukmu)
- Empty result: ilustrasi + "Tidak ditemukan"
- Min 2 karakter untuk search

---

## 4. Komponen Reusable

### 4.1 `DramaCardGrid` (3-column card)
```dart
// Props: Drama drama, VoidCallback onTap
// Variants: showBadge, showViews, showProvider
// Size: flexible height (aspect 0.52 ratio)
```
- Poster 3:4 dengan rounded 10dp
- Badge overlay (configurable position & text)
- Views overlay bottom-right
- Title + genre below

### 4.2 `DramaCardList` (horizontal list item)
```dart
// Props: Drama drama, VoidCallback onTap
// Extra: releaseDate, sinopsis, ranking
// Size: 120dp height
```
- Poster kiri 80×107dp
- Info stack kanan
- Optional: ranking badge, date, progress

### 4.3 `DramaCardLarge` (masonry / for-you card)
```dart
// Props: Drama drama, VoidCallback onTap, double height
// Size: variable height (staggered)
```
- Poster full-card background
- Gradient overlay bottom
- Views + title overlay

### 4.4 `BadgePill`
```dart
// Props: String text, Color color, IconData? icon
// Variants: filled, outline
```
- Height: 20dp, rounded 10dp, padding h:8dp
- Font: 10sp bold
- Preset colors: popular=#FF2D55, new=#4CAF50, provider=#6C63FF, trending=#FF6B35

### 4.5 `GenrePill`
```dart
// Props: String genre, bool isSelected, VoidCallback onTap
```
- Height: 28dp, rounded 14dp
- Selected: #FF2D55 filled
- Unselected: #333333 filled

### 4.6 `GenreBlock` (replaces card slot in masonry)
```dart
// Props: String genre, Color bgColor, List<Drama> items (4 max)
```
- Background: gradient from bgColor
- Header: genre name + chevron
- 2×2 mini thumbnail grid

### 4.7 `ProviderChip`
```dart
// Props: String name, int count, bool isSelected
```
- Scrollable horizontal
- Show provider name + drama count

### 4.8 `RankingTile`
```dart
// Props: int rank, Drama drama, int popularity
```
- Number styling berdasarkan rank (gold/silver/bronze)
- Fire icon + popularity count

### 4.9 `CoinBadge`
```dart
// Props: int amount, bool showPlus
```
- Circle gold icon + amount
- Optional "+" prefix (reward indicator)

### 4.10 `EmptyState`
```dart
// Props: IconData icon, String title, String subtitle, Widget? action
```
- Centered layout, 64dp icon, texts, optional CTA button

### 4.11 `SectionHeader`
```dart
// Props: String title, VoidCallback? onSeeAll
```
- 16sp bold white + "Lihat Semua >" link

### 4.12 `ShimmerGrid`
```dart
// Props: int columns, int rows
```
- Placeholder loading skeleton matching card layout

---

## 5. Adaptasi untuk JagatFilm (vs DramaBox)

| Aspek | DramaBox | JagatFilm | Implementasi |
|-------|----------|-----------|--------------|
| Model Bisnis | Subscription ($5.99/minggu) | GRATIS + Rewarded Ads | Tab "Koin" bukan "Anggota" |
| Monetisasi | Paywall episode | Adsterra ads + koin (future) | Interstitial setiap 3 ep, rewarded untuk bonus |
| Provider | Single (DramaBox own content) | Multi (25 provider) | Filter "Provider" bukan "Negara" di Kategori |
| Views/Popularity | Data internal DramaBox | **Analytics sendiri** (PostgreSQL) | Endpoint `/api/analytics/view` + tabel `drama_views` |
| Trending/Ranking | Data internal | **Views 7 hari terakhir** | Endpoint `/api/dramas/trending` |
| Terbaru | Data rilis internal | **`first_seen_at`** saat cron menemukan drama baru | Endpoint `/api/dramas/newest` |
| Login | Facebook + Google | Google OAuth only | Hapus FB, satu tombol Google |
| Anime | Ada tab khusus | Tidak ada konten anime | Skip tab Anime, 4 tab saja |
| Koin | Beli dengan uang | Gratis dari iklan + misi | CoinScreen fokus earn, bukan purchase |
| Download | Fitur member | Coming Soon (perlu backend) | UI ada, fungsi disabled |
| Bahasa Filter | Sulih Suara/Subtitle | Tidak relevan (semua subtitle) | Skip filter bahasa |
| VIP Tab | Grid khusus member | Tidak ada VIP | Skip, semua konten gratis |
| Share | Internal gifting | Native share link | share_plus package |
| Notifikasi | Push notification | Belum ada | Icon ada, fungsi coming soon |

### Perbedaan Filter Kategori:

DramaBox: Negara → Bahasa → Akses → Genre → Tema → Sort
JagatFilm: **Provider → Genre → Tema → Sort** (3 level saja, lebih simpel)

### Perbedaan Koin:

DramaBox: Beli koin → buka episode
JagatFilm: Tonton iklan / selesaikan misi → dapat koin → (future) buka episode premium

### Prioritas Konten:

- Home default sort: popularity (views tinggi dulu)
- Provider default: `homeProvider` dari remote config (saat ini "shortmax")
- Tampilkan provider badge di setiap card (competitive advantage: multi-source)

---

## 6. Prioritas Implementasi

### Fase 0: Backend Analytics (Pre-requisite, ~2-3 jam)
0. ✅ Buat tabel PostgreSQL: `drama_views`, `drama_views_daily`, `drama_first_seen`
1. ✅ Buat endpoint `POST /api/analytics/view`
2. ✅ Buat endpoint `GET /api/dramas/popular`, `/trending`, `/newest`, `/stats`
3. ✅ Modifikasi cron refresh → auto-populate `drama_first_seen` saat drama baru ditemukan
4. ✅ Seed views awal (random) agar app tidak kosong
5. ✅ Rebuild & restart jagatfilm

### Fase 1: Foundation (Week 1-2)
1. ✅ Buat `MainShell` dengan bottom navigation 5 tab
2. ✅ Refactor `HomeScreen` → nested TabBar (Untukmu, Terbaru, Peringkat, Kategori)
3. ✅ Buat komponen reusable: `DramaCardGrid`, `BadgePill`, `SectionHeader`, `ShimmerGrid`
4. ✅ Implementasi tab Untukmu (grid 3 kolom + infinite scroll)
5. ✅ Implementasi tab Kategori (filter provider + genre + sort)

### Fase 2: Content Pages (Week 2-3)
6. Implementasi tab Terbaru (list layout + sub-tab)
7. Implementasi tab Peringkat (ranking list)
8. Buat `ForYouScreen` (feed vertikal card besar)
9. Upgrade `DetailScreen` (layout baru + episode grid + drama serupa)
10. Upgrade `SearchScreen` (trending + riwayat + debounce)

### Fase 3: User Features (Week 3-4)
11. Buat `WatchlistScreen` (Sedang Ditonton + Riwayat — local storage)
12. Upgrade `ProfileScreen` (layout baru + menu lengkap)
13. Buat `CoinScreen` (full UI, fungsi disabled/coming soon)
14. Implementasi local watchlist dengan SharedPreferences
15. Implementasi watch history tracking

### Fase 4: Polish & Monetization (Week 4-5)
16. Masonry layout di Untukmu (Section Rekomendasi Populer)
17. Genre Block widget
18. Provider Spotlight section
19. Adsterra interstitial integration (setiap 3 episode)
20. Rewarded ad button di CoinScreen
21. Animasi dan transisi (hero animation poster, page transitions)

### Fase 5: Future (Backend Required)
22. Koin backend integration (earn + spend)
23. Cloud watchlist sync
24. Push notifications
25. Download feature
26. Episode locking/unlocking system

---

## 7. File/Screen yang Perlu Dibuat atau Diubah

### File BARU yang perlu dibuat:

```
lib/
├── main.dart                          ← UBAH (tambah MainShell routing)
├── screens/
│   ├── main_shell.dart                ← BARU (bottom nav wrapper)
│   ├── home_screen.dart               ← UBAH BESAR (refactor + tabs)
│   ├── home_tabs/
│   │   ├── untukmu_tab.dart           ← BARU
│   │   ├── terbaru_tab.dart           ← BARU
│   │   ├── peringkat_tab.dart         ← BARU
│   │   └── kategori_tab.dart          ← BARU
│   ├── for_you_screen.dart            ← BARU
│   ├── coin_screen.dart               ← BARU
│   ├── watchlist_screen.dart          ← BARU
│   ├── profile_screen.dart            ← UBAH BESAR (redesign)
│   ├── detail_screen.dart             ← UBAH (layout upgrade)
│   ├── player_screen.dart             ← UBAH KECIL (tambah overlay)
│   ├── search_screen.dart             ← UBAH (trending + history)
│   ├── settings_screen.dart           ← BARU
│   ├── login_screen.dart              ← UBAH KECIL
│   └── maintenance_screen.dart        ← TETAP
├── widgets/
│   ├── drama_card.dart                ← UBAH → rename drama_card_grid.dart
│   ├── drama_card_grid.dart           ← BARU (enhanced version)
│   ├── drama_card_list.dart           ← BARU
│   ├── drama_card_large.dart          ← BARU
│   ├── badge_pill.dart                ← BARU
│   ├── genre_pill.dart                ← BARU
│   ├── genre_block.dart               ← BARU
│   ├── provider_chip.dart             ← BARU
│   ├── ranking_tile.dart              ← BARU
│   ├── coin_badge.dart                ← BARU
│   ├── empty_state.dart               ← BARU
│   ├── section_header.dart            ← BARU
│   ├── shimmer_grid.dart              ← BARU
│   ├── bottom_nav_bar.dart            ← BARU
│   ├── filter_pills.dart              ← BARU
│   └── remote_config_popup.dart       ← TETAP
├── services/
│   ├── api_service.dart               ← UBAH (tambah endpoint sort/filter)
│   ├── auth_service.dart              ← TETAP
│   ├── update_service.dart            ← TETAP
│   ├── remote_config_service.dart     ← TETAP
│   ├── preload_service.dart           ← TETAP
│   ├── watchlist_service.dart         ← BARU (local SharedPreferences)
│   ├── history_service.dart           ← BARU (watch history tracking)
│   ├── coin_service.dart              ← BARU (placeholder/mock)
│   └── ad_service.dart                ← BARU (Adsterra wrapper)
├── models/
│   ├── drama.dart                     ← TETAP
│   ├── user.dart                      ← TETAP
│   ├── app_remote_config.dart         ← TETAP
│   ├── watchlist_item.dart            ← BARU
│   ├── watch_history.dart             ← BARU
│   └── coin_transaction.dart          ← BARU (model placeholder)
├── theme/
│   └── app_theme.dart                 ← BARU (centralized theme)
└── utils/
    ├── format_utils.dart              ← BARU (view count formatter etc)
    └── constants.dart                 ← BARU (colors, spacing, strings)
```

### Summary Perubahan:
- **File baru**: ~28 file
- **File diubah**: ~7 file
- **File tetap**: ~7 file
- **File dihapus**: 0

---

## 8. Catatan Teknis Flutter

### 8.1 Dependencies (tambahan di pubspec.yaml)

```yaml
dependencies:
  # Existing - TETAP
  flutter:
    sdk: flutter
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

  # BARU - Tambahkan
  go_router: 14.2.0              # Declarative routing
  share_plus: 9.0.0              # Native share
  webview_flutter: 4.8.0         # Adsterra ad rendering
  connectivity_plus: 6.0.3       # Network state checking
  intl: 0.19.0                   # Number/date formatting
```

### 8.2 State Management

**Gunakan `Provider` (sudah ada) dengan pattern:**

```dart
// Global providers di main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService()),
    ChangeNotifierProvider(create: (_) => WatchlistService()),
    ChangeNotifierProvider(create: (_) => HistoryService()),
    ChangeNotifierProvider(create: (_) => CoinService()),
    Provider(create: (_) => ApiService()),
  ],
  child: MaterialApp.router(...),
)
```

- `AuthService`: existing, login state
- `WatchlistService`: ChangeNotifier, wraps SharedPreferences
- `HistoryService`: ChangeNotifier, watch history
- `CoinService`: ChangeNotifier, coin balance (mock for now)
- `ApiService`: singleton, stateless

### 8.3 Theme Configuration

```dart
// lib/theme/app_theme.dart
class AppTheme {
  // Colors
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color card = Color(0xFF242424);
  static const Color divider = Color(0xFF333333);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textTertiary = Color(0xFF888888);
  static const Color accent = Color(0xFFFF2D55);       // Pink/Magenta
  static const Color secondary = Color(0xFF6C63FF);    // Purple
  static const Color gold = Color(0xFFFFD700);         // Coin
  static const Color success = Color(0xFF4CAF50);      // Green
  static const Color trending = Color(0xFFFF6B35);     // Orange

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: secondary,
      surface: surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: accent,
      unselectedItemColor: textTertiary,
    ),
    cardTheme: CardTheme(
      color: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
```

### 8.4 Routing dengan GoRouter

```dart
final router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/foryou', builder: (_, __) => const ForYouScreen()),
        GoRoute(path: '/coin', builder: (_, __) => const CoinScreen()),
        GoRoute(path: '/watchlist', builder: (_, __) => const WatchlistScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
    GoRoute(path: '/drama/:id', builder: (_, state) => DetailScreen(id: state.pathParameters['id']!)),
    GoRoute(path: '/player/:id/:ep', builder: (_, state) => PlayerScreen(...)),
    GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);
```

### 8.5 API Service Extensions

```dart
// Tambahan method di ApiService:

/// Get dramas sorted by views (for ranking)
Future<DramaListResponse> getDramasByPopularity({int page = 1, int limit = 50});

/// Get dramas sorted by latest (for terbaru tab)  
Future<DramaListResponse> getLatestDramas({int page = 1, int limit = 30});

/// Get dramas filtered by genre
Future<DramaListResponse> getDramasByGenre(String genre, {int page = 1});

/// Get similar dramas (by genre match)
Future<List<Drama>> getSimilarDramas(Drama drama, {int limit = 6});
```

Catatan: Jika API belum support sort/filter server-side, lakukan client-side filtering dari full list. Wrap semua call dalam try-catch.

### 8.6 Error Handling Pattern

```dart
// SEMUA data fetch WAJIB wrapped:
Future<void> _loadData() async {
  try {
    setState(() => _isLoading = true);
    final result = await _api.getDramas(page: _page);
    setState(() {
      _dramas = result.dramas;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _error = 'Gagal memuat data';
      _isLoading = false;
    });
    // JANGAN throw — show error state di UI
  }
}
```

### 8.7 Performance Considerations

- **Image caching**: `CachedNetworkImage` sudah dipakai, pertahankan
- **Lazy loading**: Gunakan `SliverList` / `SliverGrid` untuk semua list panjang
- **Pagination**: Default 30 items per page, load more saat scroll 80%
- **Debounce search**: 500ms delay sebelum API call
- **Preload**: Pertahankan `PreloadService` untuk first-load data
- **Memory**: Dispose controllers di `dispose()`, cancel subscriptions
- **Image proxy**: Semua image via `jagatfilm.com/api/img?url=` (sudah ada)

### 8.8 Adsterra Integration Notes

```dart
// lib/services/ad_service.dart
// Adsterra tidak punya Flutter SDK resmi
// Implementasi via WebView untuk render ad tags

class AdService {
  static const String interstitialTag = '<!-- Adsterra tag here -->';
  
  /// Show interstitial ad (setiap 3 episode)
  Future<bool> showInterstitial(BuildContext context) async {
    // WebView overlay fullscreen dengan ad tag
    // Auto-close setelah 5 detik atau user close
    // Return true jika ditampilkan sukses
  }
  
  /// Show rewarded ad (untuk earn koin)
  Future<bool> showRewarded(BuildContext context) async {
    // WebView overlay, user harus tonton sampai selesai
    // Return true jika completed (reward koin)
  }
}
```

### 8.9 Local Storage Schema

```dart
// SharedPreferences keys:

// Watchlist
'watchlist_items'       → JSON string List<WatchlistItem>
'watchlist_$dramaId'    → JSON string {episode, progress, timestamp}

// History  
'watch_history'         → JSON string List<WatchHistory> (max 50)

// Preferences
'preferred_genres'      → List<String>
'preferred_providers'   → List<String>
'search_history'        → List<String> (max 20)

// Coin (mock/local until backend)
'coin_balance'          → int
'daily_login_date'      → String (ISO date)
'missions_completed'    → JSON string Map<String, bool>
```

---

## 9. Design Tokens Quick Reference

```
SPACING:
  xs: 4dp
  sm: 8dp
  md: 12dp
  lg: 16dp
  xl: 24dp
  xxl: 32dp

BORDER RADIUS:
  card: 10-12dp
  pill: 14-16dp (half height)
  avatar: 50% (circular)
  button: 8dp (rect) atau 24dp (pill)
  
FONT SIZES:
  h1: 24sp bold (page titles)
  h2: 20sp bold (drama title detail)
  h3: 16sp bold (section headers)
  body: 14sp regular
  caption: 12sp regular
  micro: 10sp medium (badges, meta)

ELEVATION:
  bottomNav: 8dp shadow
  card: 0dp (flat dark mode)
  modal: 16dp shadow
  
ANIMATION:
  fast: 150ms
  normal: 300ms
  slow: 500ms
  curve: Curves.easeOutCubic (default)
```

---

## 10. Checklist Implementasi Developer

Sebelum merge setiap fase, pastikan:

- [ ] Dark mode konsisten (tidak ada warna putih/light yang bocor)
- [ ] Semua `CachedNetworkImage` punya placeholder + errorWidget
- [ ] Semua API call wrapped try-catch, error state ditampilkan
- [ ] Infinite scroll tidak double-fetch (debounce/flag `_isLoadingMore`)
- [ ] Bottom nav mempertahankan state saat switch tab (gunakan `IndexedStack` atau `AutomaticKeepAliveClientMixin`)
- [ ] Shimmer loading di semua screen yang fetch data
- [ ] Tidak ada hardcoded string (gunakan constants)
- [ ] Responsive: test di 360dp width (small) dan 412dp width (normal)
- [ ] Memory: dispose semua controllers
- [ ] Koin features show "Segera Hadir" snackbar, tidak crash

---

## 11. Analytics Backend — Views, Trending, Terbaru

### Mengapa Dibutuhkan
API captain.sapimu.au tidak menyediakan data views, popularitas, atau tanggal rilis.
Kita bangun **analytics sendiri** menggunakan PostgreSQL yang sudah tersedia di VPS (port 5432, db `masterpanel_db`).

Data ini akan mengisi:
- **Tab "Untukmu"** → rekomendasi berdasarkan views tertinggi + random
- **Tab "Daftar Peringkat"** → ranking berdasarkan views real dari user kita
- **Tab "Terbaru"** → drama yang baru ditemukan/ditambah oleh cron refresh
- **Badge views** (5.8M, 321K dll) → diganti real view count dari user kita

### 11.1 Database Schema (tambahan di PostgreSQL)

```sql
-- Track jumlah views per drama (lifetime)
CREATE TABLE IF NOT EXISTS drama_views (
  drama_id VARCHAR(100) PRIMARY KEY,
  title VARCHAR(500),
  source VARCHAR(50),
  genre VARCHAR(100),
  view_count INTEGER DEFAULT 0,
  unique_viewers INTEGER DEFAULT 0,
  last_viewed_at TIMESTAMPTZ DEFAULT NOW(),
  first_viewed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Track views harian (untuk trending/7 hari)
CREATE TABLE IF NOT EXISTS drama_views_daily (
  id SERIAL PRIMARY KEY,
  drama_id VARCHAR(100) NOT NULL,
  view_date DATE NOT NULL DEFAULT CURRENT_DATE,
  view_count INTEGER DEFAULT 0,
  UNIQUE(drama_id, view_date)
);
CREATE INDEX idx_views_daily_date ON drama_views_daily(view_date);
CREATE INDEX idx_views_daily_drama ON drama_views_daily(drama_id);

-- Track kapan drama pertama kali muncul di sistem (untuk tab Terbaru)
CREATE TABLE IF NOT EXISTS drama_first_seen (
  drama_id VARCHAR(100) PRIMARY KEY,
  title VARCHAR(500),
  source VARCHAR(50),
  genre VARCHAR(100),
  cover TEXT,
  first_seen_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_first_seen_date ON drama_first_seen(first_seen_at DESC);
```

### 11.2 Endpoint Baru (Next.js API routes)

Lokasi: `/www/wwwroot/jagatfilm.com/jagatfilm/src/app/api/`

#### `POST /api/analytics/view`
**Dipanggil oleh APK** saat user buka detail drama atau mulai nonton episode.

```typescript
// Request body:
{
  "drama_id": "shortmax-850772",
  "title": "Rahasia Sang Putri Miliarder",  // optional, untuk cache
  "source": "shortmax",                      // optional
  "genre": "Drama"                           // optional
}

// Response:
{ "success": true, "view_count": 1542 }
```

Logic:
1. `INSERT ... ON CONFLICT (drama_id) DO UPDATE SET view_count = view_count + 1, last_viewed_at = NOW()`
2. `INSERT INTO drama_views_daily ... ON CONFLICT (drama_id, view_date) DO UPDATE SET view_count = view_count + 1`
3. Return current total view_count

Rate limit: 1 view per drama per device per 5 menit (via header/IP, optional).

#### `GET /api/dramas/popular?limit=50&page=1`
Sort by `view_count` DESC. Untuk tab **Untukmu** dan **Daftar Peringkat**.

```typescript
// Response:
{
  "success": true,
  "data": [
    { "drama_id": "shortmax-850772", "view_count": 15420, "rank": 1 },
    { "drama_id": "reelshort-123", "view_count": 12300, "rank": 2 },
    ...
  ]
}
```

APK mencocokkan `drama_id` dengan data drama dari `/api/dramas` untuk mendapat info lengkap (cover, title, dll).

#### `GET /api/dramas/trending?days=7&limit=30`
Sort by total views dalam X hari terakhir. Untuk badge **"Sedang Tren"**.

```typescript
// Response:
{
  "success": true,
  "data": [
    { "drama_id": "shortmax-850772", "trending_views": 5420, "rank": 1 },
    ...
  ]
}
```

SQL: `SELECT drama_id, SUM(view_count) as trending_views FROM drama_views_daily WHERE view_date >= CURRENT_DATE - interval '7 days' GROUP BY drama_id ORDER BY trending_views DESC LIMIT $1`

#### `GET /api/dramas/newest?limit=30&page=1`
Sort by `first_seen_at` DESC. Untuk tab **Terbaru**.

```typescript
// Response:
{
  "success": true,
  "data": [
    { "drama_id": "melolo-123", "first_seen_at": "2026-08-23T15:00:00Z", ... },
    ...
  ]
}
```

#### `GET /api/dramas/stats?ids=shortmax-850772,reelshort-123,...`
Batch get view counts untuk drama yang sudah di-load (untuk badge views di card).

```typescript
// Response:
{
  "success": true,
  "stats": {
    "shortmax-850772": { "view_count": 15420, "trending_rank": 3 },
    "reelshort-123": { "view_count": 12300, "trending_rank": null }
  }
}
```

### 11.3 Auto-Populate "Terbaru" dari Cron Refresh

Modifikasi cron refresh (`/www/wwwroot/jagatfilm.com/jagatfilm/scripts/cron-refresh.sh` atau logic di `dramas/route.ts`):

Saat `mergeDramas()` menemukan drama baru (ID belum ada di cache sebelumnya):
→ INSERT ke `drama_first_seen` dengan `first_seen_at = NOW()`

Ini otomatis — tidak butuh input user. Setiap 30 menit, drama baru dari provider langsung tercatat waktunya.

### 11.4 Integrasi di APK

**Kapan hit `POST /api/analytics/view`:**
1. User masuk `DetailScreen` (buka halaman detail drama)
2. User mulai nonton episode di `PlayerScreen` (first play per sesi)

**Kapan fetch view stats:**
1. `HomeScreen` load → fetch `/api/dramas/popular` (untuk tab Untukmu ranking)
2. Tab Peringkat → fetch `/api/dramas/popular` + `/api/dramas/trending`
3. Tab Terbaru → fetch `/api/dramas/newest`
4. Card drama tampil → badge views dari stats (batch fetch atau embedded)

**Kode di APK (tambahan di ApiService):**

```dart
/// Record a view (fire-and-forget, jangan block UI)
Future<void> recordView(String dramaId, {String? title, String? source, String? genre}) async {
  try {
    await _client.post(
      Uri.parse('$baseUrl/api/analytics/view'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'drama_id': dramaId,
        if (title != null) 'title': title,
        if (source != null) 'source': source,
        if (genre != null) 'genre': genre,
      }),
    );
  } catch (_) {
    // Silent fail — analytics tidak boleh ganggu UX
  }
}

/// Get popular dramas (for ranking)
Future<List<DramaPopularity>> getPopularDramas({int limit = 50, int page = 1}) async {
  final uri = Uri.parse('$baseUrl/api/dramas/popular').replace(
    queryParameters: {'limit': limit.toString(), 'page': page.toString()},
  );
  final response = await _client.get(uri, headers: _headers);
  // parse...
}

/// Get trending dramas (7 days)
Future<List<DramaTrending>> getTrendingDramas({int days = 7, int limit = 30}) async {
  final uri = Uri.parse('$baseUrl/api/dramas/trending').replace(
    queryParameters: {'days': days.toString(), 'limit': limit.toString()},
  );
  final response = await _client.get(uri, headers: _headers);
  // parse...
}

/// Get newest dramas
Future<List<DramaNewest>> getNewestDramas({int limit = 30, int page = 1}) async {
  final uri = Uri.parse('$baseUrl/api/dramas/newest').replace(
    queryParameters: {'limit': limit.toString(), 'page': page.toString()},
  );
  final response = await _client.get(uri, headers: _headers);
  // parse...
}
```

### 11.5 Format Views di Badge

```dart
String formatViews(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}
// 1542 → "1.5K"
// 15420 → "15.4K"  
// 1542000 → "1.5M"
```

Awalnya view count akan kecil (app baru, user sedikit). Strategi:
- **Seed data**: saat pertama kali setup, bisa inject random views 100-5000 untuk drama populer agar tidak terlihat kosong
- Atau tampilkan badge views hanya jika > 100, hide jika masih sedikit

### 11.6 Dampak ke Tab di Blueprint

| Tab | Sumber Data | Endpoint |
|-----|-------------|----------|
| **Untukmu** | Popular + random mix | `/api/dramas/popular` + `/api/dramas?page=random` |
| **Terbaru** | Newest first_seen | `/api/dramas/newest` |
| **Peringkat** | Views ranking + trending 7d | `/api/dramas/popular` + `/api/dramas/trending` |
| **Kategori** | Genre filter (client-side) | `/api/dramas?provider=X` + filter genres/tags |

### 11.7 Prioritas Implementasi Analytics

Ini harus dikerjakan **SEBELUM** atau **BERSAMAAN dengan** Fase 1 APK, karena tab butuh data ini:

1. **Buat tabel** PostgreSQL (5 menit)
2. **Buat endpoint** `POST /api/analytics/view` (30 menit)
3. **Modifikasi cron/merge** untuk populate `drama_first_seen` (30 menit)
4. **Buat endpoint** `GET /api/dramas/popular`, `/trending`, `/newest` (1 jam)
5. **Seed data** views awal agar tidak kosong (optional)
6. **Rebuild & restart** website Next.js

Total: ~2-3 jam kerja → semua tab punya data real.

---

## 12. Fase 0 (Pre-requisite) — Backend Analytics

**Sebelum mulai Fase 1 APK, kerjakan ini dulu:**

| # | Task | Lokasi | Estimasi |
|---|------|--------|----------|
| 0.1 | Buat tabel `drama_views`, `drama_views_daily`, `drama_first_seen` | PostgreSQL | 5 min |
| 0.2 | Buat `POST /api/analytics/view` | jagatfilm Next.js | 30 min |
| 0.3 | Buat `GET /api/dramas/popular` | jagatfilm Next.js | 20 min |
| 0.4 | Buat `GET /api/dramas/trending` | jagatfilm Next.js | 20 min |
| 0.5 | Buat `GET /api/dramas/newest` | jagatfilm Next.js | 20 min |
| 0.6 | Buat `GET /api/dramas/stats` (batch) | jagatfilm Next.js | 20 min |
| 0.7 | Modifikasi `mergeDramas()` → populate `drama_first_seen` | dramas/route.ts | 30 min |
| 0.8 | Seed views awal (random 100-5000 untuk top 500 drama) | SQL script | 10 min |
| 0.9 | Rebuild & restart jagatfilm, test endpoints | PM2 | 10 min |

**Setelah Fase 0 selesai**, semua endpoint siap dan Fase 1 APK bisa langsung pakai data real.

---

*End of Blueprint — Dokumen ini adalah single source of truth untuk redesign UI/UX APK JagatFilm.*
