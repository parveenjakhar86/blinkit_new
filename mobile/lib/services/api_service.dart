import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/product.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  static const String _productCacheKey = 'cachedProducts';
  static String? _activeBaseUrl;
  static Duration _requestTimeoutFor(String baseUrl) =>
      ApiConfig.isHostedBaseUrl(baseUrl)
    ? const Duration(seconds: 20)
    : const Duration(seconds: 5);
  static Duration _catalogRequestTimeoutFor(String baseUrl) =>
      ApiConfig.isHostedBaseUrl(baseUrl)
    ? const Duration(seconds: 20)
    : const Duration(seconds: 4);
  static Duration _healthTimeoutFor(String baseUrl) =>
      ApiConfig.isHostedBaseUrl(baseUrl)
    ? const Duration(seconds: 6)
    : const Duration(seconds: 2);
  static const Duration _retryDelay = Duration(seconds: 2);

  static List<String> get _baseCandidates {
    final candidates = <String>[];
    if (_activeBaseUrl != null) {
      candidates.add(_activeBaseUrl!);
    }

    for (final baseUrl in ApiConfig.candidateBaseUrls) {
      if (!candidates.contains(baseUrl)) {
        candidates.add(baseUrl);
      }
    }

    return candidates;
  }

  static Future<Uri> resolveUri(String path) async {
    final baseUrl = await _resolveBaseUrl();
    return Uri.parse(ApiConfig.endpointFor(baseUrl, path));
  }

  static Future<List<Product>> fetchProducts() async {
    ApiException? lastApiError;
    final cachedProducts = await _readCachedProducts();

    try {
      for (final baseUrl in _baseCandidates) {
        try {
          final resp = await _getWithRetry(
            Uri.parse(ApiConfig.endpointFor(baseUrl, 'products')),
            timeout: _catalogRequestTimeoutFor(baseUrl),
          );

          if (resp.statusCode == 200) {
            _activeBaseUrl = baseUrl;
            final List data = jsonDecode(resp.body) as List;
            final products = data
                .map((e) => Product.fromJson(e as Map<String, dynamic>))
                .toList();
            await _cacheProducts(resp.body);
            return products;
          }

          lastApiError = ApiException(
            _extractMessage(resp) ?? 'Unable to load products right now.',
          );

          if (!_shouldTryNextBase(resp.statusCode)) {
            throw lastApiError;
          }
        } catch (error) {
          if (!_shouldFallbackToAnotherBase(error)) {
            rethrow;
          }
        }
      }

      if (cachedProducts.isNotEmpty) {
        return cachedProducts;
      }

      throw lastApiError ?? const ApiException('Unable to load products right now.');
    } on ApiException {
      if (cachedProducts.isNotEmpty) {
        return cachedProducts;
      }
      rethrow;
    } catch (error) {
      if (cachedProducts.isNotEmpty) {
        return cachedProducts;
      }
      throw _mapRequestError(
        error,
        fallbackMessage: 'Unable to load products right now.',
      );
    }
  }

  static Future<http.Response> _getWithRetry(
    Uri uri, {
    required Duration timeout,
  }) async {
    final maxAttempts = uri.scheme == 'https' ? 2 : 1;
    Object? lastError;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await http.get(uri).timeout(timeout);
      } catch (error) {
        lastError = error;
        if (!_shouldRetry(error) || attempt == maxAttempts - 1) {
          rethrow;
        }

        await Future<void>.delayed(_retryDelay);
      }
    }

    throw lastError ?? ApiException('Unable to complete the request.');
  }

  static Future<Map<String, dynamic>> placeOrder({
    required Map<String, dynamic> customerDetails,
    required List<Map<String, dynamic>> products,
    required String paymentMethod,
    required double totalAmount,
  }) async {
    try {
      final uri = await resolveUri('orders/place');
      final resp = await _postWithRetry(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerDetails': customerDetails,
          'products': products,
          'paymentMethod': paymentMethod,
          'totalAmount': totalAmount,
        }),
        timeout: _requestTimeoutFor(uri.replace(path: '').toString()),
      );

      final data = _decodeJsonMap(resp);
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return data;
      }

      throw ApiException(
        data['message']?.toString() ?? 'Failed to place order.',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw _mapRequestError(
        error,
        fallbackMessage: 'Failed to place order. Please try again.',
      );
    }
  }

  static Future<http.Response> _postWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
  }) async {
    final maxAttempts = uri.scheme == 'https' ? 2 : 1;
    Object? lastError;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await http
            .post(uri, headers: headers, body: body)
            .timeout(timeout);
      } catch (error) {
        lastError = error;
        if (!_shouldRetry(error) || attempt == maxAttempts - 1) {
          rethrow;
        }

        await Future<void>.delayed(_retryDelay);
      }
    }

    throw lastError ?? ApiException('Unable to complete the request.');
  }

  static Future<String> _resolveBaseUrl() async {
    if (_activeBaseUrl != null) {
      return _activeBaseUrl!;
    }

    for (final baseUrl in _baseCandidates) {
      try {
        final response = await http
            .get(Uri.parse('${ApiConfig.serviceUrlFor(baseUrl)}/health'))
            .timeout(_healthTimeoutFor(baseUrl));

        if (response.statusCode == 200) {
          _activeBaseUrl = baseUrl;
          return baseUrl;
        }
      } catch (_) {
        continue;
      }
    }

    _activeBaseUrl = ApiConfig.candidateBaseUrls.last;
    return _activeBaseUrl!;
  }

  static Future<void> _cacheProducts(String rawJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_productCacheKey, rawJson);
    } catch (_) {
      // Ignore cache write failures.
    }
  }

  static Future<List<Product>> _readCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_productCacheKey);
      if (rawJson == null || rawJson.trim().isEmpty) {
        return const <Product>[];
      }

      final decoded = jsonDecode(rawJson);
      if (decoded is! List) {
        return const <Product>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => Product.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    } catch (_) {
      return const <Product>[];
    }
  }

  static Map<String, dynamic> _decodeJsonMap(http.Response resp) {
    if (resp.body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{};
  }

  static String? _extractMessage(http.Response resp) {
    try {
      return _decodeJsonMap(resp)['message']?.toString();
    } catch (_) {
      return null;
    }
  }

  static ApiException _mapRequestError(
    Object error, {
    required String fallbackMessage,
  }) {
    if (error is TimeoutException) {
      return const ApiException(
        'The server took too long to respond. If the hosted server was sleeping, wait a few seconds and try again.',
      );
    }

    if (error is SocketException) {
      return const ApiException(
        'Unable to connect to the server. Check that the backend is running and both devices are on the same network.',
      );
    }

    final message = error.toString().toLowerCase();
    if (message.contains('socketexception') ||
        message.contains('connection abort') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused')) {
      return const ApiException(
        'Unable to connect to the server. Check that the backend is running and both devices are on the same network.',
      );
    }

    if (error is http.ClientException || message.contains('clientexception')) {
      return const ApiException(
        'Network connection was interrupted. Please try again.',
      );
    }

    return ApiException(fallbackMessage);
  }

  static bool _shouldTryNextBase(int statusCode) {
    return statusCode >= 500 || statusCode == 404 || statusCode == 502;
  }

  static bool _shouldFallbackToAnotherBase(Object error) {
    return error is TimeoutException ||
        error is SocketException ||
        error is http.ClientException ||
        error.toString().toLowerCase().contains('connection refused') ||
        error.toString().toLowerCase().contains('failed host lookup');
  }

  static bool _shouldRetry(Object error) {
    if (error is TimeoutException ||
        error is SocketException ||
        error is http.ClientException) {
      return true;
    }

    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('connection abort') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('clientexception');
  }
}
