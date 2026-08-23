# JagatFilm Android Launcher Icon

- Source: logo configured in MasterPanel `logo_url` on 23 August 2026.
- Original: `source/masterpanel-logo.png` (PNG RGBA, 1024x1024).
- Legacy launcher icons: `res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`.
- Adaptive foregrounds: `res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_foreground.png`.
- Adaptive background: `#081633`.
- Play Store artwork: `play-store-icon-512.png`.

The CI workflow copies `branding/launcher_icon/res/` after `flutter create`, because that command regenerates and replaces the Android project. A MasterPanel logo change only affects in-app branding; changing the Android launcher icon still requires regenerating these files and publishing a new APK.
