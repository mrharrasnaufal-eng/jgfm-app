class AppRemoteConfig {
  static const String defaultMaintenanceMessage =
      'Aplikasi sedang dalam pemeliharaan. Silakan coba lagi nanti.';

  final String logoUrl;
  final String splashImageUrl;
  final bool popupEnabled;
  final String popupImageUrl;
  final String popupTitle;
  final String popupMessage;
  final String popupAction;
  final String popupExternalUrl;
  final int popupDurationSeconds;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String announcement;
  final bool forceUpdate;
  final String minimumVersion;
  final String homeProvider;

  /// Provider yang dipilih admin untuk feed "Untuk Anda". Kosong = semua provider.
  final List<String> forYouProviders;

  const AppRemoteConfig({
    required this.logoUrl,
    required this.splashImageUrl,
    required this.popupEnabled,
    required this.popupImageUrl,
    required this.popupTitle,
    required this.popupMessage,
    required this.popupAction,
    required this.popupExternalUrl,
    required this.popupDurationSeconds,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.announcement,
    required this.forceUpdate,
    required this.minimumVersion,
    required this.homeProvider,
    this.forYouProviders = const [],
  });

  const AppRemoteConfig.defaults()
      : logoUrl = '',
        splashImageUrl = '',
        popupEnabled = false,
        popupImageUrl = '',
        popupTitle = '',
        popupMessage = '',
        popupAction = '',
        popupExternalUrl = '',
        popupDurationSeconds = 5,
        maintenanceMode = false,
        maintenanceMessage = defaultMaintenanceMessage,
        announcement = '',
        forceUpdate = false,
        minimumVersion = '1.0.0',
        homeProvider = 'shortmax',
        forYouProviders = const [];

  factory AppRemoteConfig.fromJson(Map<String, dynamic> json) {
    final popupAction = _popupAction(json['popup_action_url']);

    return AppRemoteConfig(
      logoUrl: _safeHttpUrl(json['logo_url']),
      splashImageUrl: _safeHttpUrl(json['splash_image_url']),
      popupEnabled: _boolValue(json['popup_enabled']),
      popupImageUrl: _safeHttpUrl(json['popup_image_url']),
      popupTitle: _text(json['popup_title'], maxLength: 120),
      popupMessage: _text(json['popup_message'], maxLength: 1000),
      popupAction: popupAction,
      popupExternalUrl: popupAction == 'external'
          ? _safeHttpUrl(json['popup_external_url'])
          : '',
      popupDurationSeconds: _durationSeconds(json['popup_duration']),
      maintenanceMode: _boolValue(json['maintenance_mode']),
      maintenanceMessage: _text(
        json['maintenance_message'],
        fallback: defaultMaintenanceMessage,
        maxLength: 1000,
      ),
      announcement: _text(json['announcement'], maxLength: 500),
      forceUpdate: _boolValue(json['force_update']),
      minimumVersion: _version(json['min_version']),
      homeProvider: _provider(json['home_provider']),
      forYouProviders: _providersList(json['for_you_providers']),
    );
  }

  bool get hasPopupContent =>
      popupTitle.isNotEmpty ||
      popupMessage.isNotEmpty ||
      popupImageUrl.isNotEmpty;

  bool get hasPopupAction =>
      popupAction.startsWith('page:') ||
      (popupAction == 'external' && popupExternalUrl.isNotEmpty);

  static String _text(
    dynamic value, {
    String fallback = '',
    required int maxLength,
  }) {
    if (value is! String) return fallback;
    final normalized = value.trim();
    if (normalized.isEmpty) return fallback;
    if (normalized.length <= maxLength) return normalized;
    return normalized.substring(0, maxLength);
  }

  static bool _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static int _intValue(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static int _durationSeconds(dynamic value) {
    final parsed = _intValue(value, fallback: 5);
    if (parsed < 2) return 2;
    if (parsed > 30) return 30;
    return parsed;
  }

  static String _safeHttpUrl(dynamic value) {
    if (value is! String) return '';
    final normalized = value.trim();
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) return '';
    if (uri.scheme != 'https' && uri.scheme != 'http') return '';
    return normalized;
  }

  static String _popupAction(dynamic value) {
    if (value is! String) return '';
    final normalized = value.trim().toLowerCase();
    const allowed = {
      'page:home',
      'page:search',
      'page:profile',
      'page:update',
      'page:login',
      'external',
    };
    return allowed.contains(normalized) ? normalized : '';
  }

  static String _version(dynamic value) {
    if (value is! String) return '1.0.0';
    final normalized = value.trim();
    if (!RegExp(r'^\d+(\.\d+){0,3}$').hasMatch(normalized)) {
      return '1.0.0';
    }
    return normalized;
  }

  static String _provider(dynamic value) {
    if (value is! String) return 'shortmax';
    final normalized = value.trim().toLowerCase();
    const allowed = {
      'shortmax', 'cashdrama', 'netshort', 'rapidtv', 'bilitv',
      'flickreels', 'melolo', 'wetv', 'dramabite', 'reelshort',
      'microdrama', 'dotdrama', 'dramabox', 'starshort',
    };
    return allowed.contains(normalized) ? normalized : 'shortmax';
  }

  static List<String> _providersList(dynamic value) {
    if (value is! List) return const [];
    const allowed = {
      'shortmax', 'cashdrama', 'netshort', 'rapidtv', 'bilitv',
      'flickreels', 'melolo', 'wetv', 'dramabite', 'reelshort',
      'microdrama', 'dotdrama', 'dramabox', 'starshort',
    };
    final out = <String>[];
    for (final e in value) {
      if (e is String) {
        final s = e.trim().toLowerCase();
        if (allowed.contains(s) && !out.contains(s)) out.add(s);
      }
    }
    return out;
  }
}
