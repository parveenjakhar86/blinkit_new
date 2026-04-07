import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/product.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  static Duration get _requestTimeout => ApiConfig.isHostedBackend
      ? const Duration(seconds: 45)
      : const Duration(seconds: 12);
  static Duration get _catalogRequestTimeout => ApiConfig.isHostedBackend
      ? const Duration(seconds: 75)
      : const Duration(seconds: 30);
  static const Duration _retryDelay = Duration(seconds: 2);
  static bool _backendWarmedUp = false;

  static Future<List<Product>> fetchProducts() async {
    try {
      await _warmUpBackend();
      final resp = await _getWithRetry(
        Uri.parse(ApiConfig.products),
        timeout: _catalogRequestTimeout,
      );

      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body) as List;
        return data
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw ApiException(
        _extractMessage(resp) ?? 'Unable to load products right now.',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
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
    final maxAttempts = ApiConfig.isHostedBackend ? 3 : 2;
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
      await _warmUpBackend();
      final resp = await _postWithRetry(
        Uri.parse(ApiConfig.placeOrder),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerDetails': customerDetails,
          'products': products,
          'paymentMethod': paymentMethod,
          'totalAmount': totalAmount,
        }),
        timeout: _requestTimeout,
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
    final maxAttempts = ApiConfig.isHostedBackend ? 3 : 2;
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

  static Future<void> _warmUpBackend() async {
    if (!ApiConfig.isHostedBackend || _backendWarmedUp) {
      return;
    }

    try {
      await http
          .get(Uri.parse(ApiConfig.health))
          .timeout(const Duration(seconds: 20));
      _backendWarmedUp = true;
    } catch (_) {
      // Ignore warm-up failures and let the main request handle retries.
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
