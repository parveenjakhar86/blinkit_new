class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _configuredHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '192.168.68.137:5007',
  );

  static const bool _useAndroidEmulatorHost = bool.fromEnvironment(
    'USE_ANDROID_EMULATOR_HOST',
    defaultValue: false,
  );

  static const String _hostedBaseUrl = 'https://blinkit-new.onrender.com/api';
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:5007/api';

  static String normalizeBaseUrl(String baseUrl) {
    var normalized = baseUrl.trim();
    if (normalized.isEmpty) return normalized;
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    if (!normalized.endsWith('/api')) {
      normalized = normalized.replaceAll(RegExp(r'/+$'), '');
      normalized = '$normalized/api';
    }
    return normalized;
  }

  static String endpointFor(String baseUrl, String path) {
    final cleanedPath = path.startsWith('/') ? path.substring(1) : path;
    return '${normalizeBaseUrl(baseUrl)}/$cleanedPath';
  }

  static String get _fallbackBaseUrl => normalizeBaseUrl(_configuredHost);

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return normalizeBaseUrl(_configuredBaseUrl);
    }
    return _hostedBaseUrl;
  }

  static List<String> get candidateBaseUrls {
    final candidates = <String>[];

    void addCandidate(String value) {
      final normalized = normalizeBaseUrl(value);
      if (normalized.isNotEmpty && !candidates.contains(normalized)) {
        candidates.add(normalized);
      }
    }

    if (_configuredBaseUrl.isNotEmpty) {
      addCandidate(_configuredBaseUrl);
      return candidates;
    }

    addCandidate(_hostedBaseUrl);
    if (_useAndroidEmulatorHost) {
      addCandidate(_androidEmulatorBaseUrl);
    } else if (_configuredHost.isNotEmpty) {
      addCandidate(_fallbackBaseUrl);
    }
    return candidates;
  }
}