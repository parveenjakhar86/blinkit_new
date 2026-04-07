import 'package:flutter/foundation.dart';

// API configuration for local network or hosted backend.
class ApiConfig {
  // Override at build time for a different backend:
  // flutter run --dart-define=API_BASE_URL=https://your-domain.com/api
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.25:5007
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://blinkit-new.onrender.com/api',
  );

  // Override only the LAN host when your computer IP changes:
  // flutter run --dart-define=API_HOST=192.168.1.25:5007
  static const String _configuredHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '192.168.1.8:5007',
  );

  // Enable this when running on the Android emulator:
  // flutter run --dart-define=USE_ANDROID_EMULATOR_HOST=true
  static const bool _useAndroidEmulatorHost = bool.fromEnvironment(
    'USE_ANDROID_EMULATOR_HOST',
    defaultValue: false,
  );

  static String get _fallbackBaseUrl => 'http://$_configuredHost/api';

  static String get _androidEmulatorBaseUrl => 'http://10.0.2.2:5007/api';

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final withoutTrailingSlash = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;

    if (withoutTrailingSlash.endsWith('/api')) {
      return withoutTrailingSlash;
    }

    return '$withoutTrailingSlash/api';
  }

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _normalizeBaseUrl(_configuredBaseUrl);
    }

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        _useAndroidEmulatorHost) {
      return _androidEmulatorBaseUrl;
    }

    return _fallbackBaseUrl;
  }

  static Uri get baseUri => Uri.parse(baseUrl);

  static bool get isHostedBackend => baseUri.scheme == 'https';

  static String get serviceUrl {
    final pathSegments = List<String>.from(baseUri.pathSegments);
    if (pathSegments.isNotEmpty && pathSegments.last == 'api') {
      pathSegments.removeLast();
    }

    return baseUri.replace(pathSegments: pathSegments).toString();
  }

  static String get login => '$baseUrl/customer/login';
  static String get products => '$baseUrl/products';
  static String get placeOrder => '$baseUrl/orders/place';
  static String get health => '$serviceUrl/health';
}
