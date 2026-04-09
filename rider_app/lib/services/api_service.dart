import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiService {
  static String? _activeBaseUrl;

  static List<String> get _baseCandidates => ApiConfig.candidateBaseUrls;

  static Duration _requestTimeoutFor(String baseUrl) {
    return baseUrl.contains('onrender.com')
        ? const Duration(seconds: 20)
        : const Duration(seconds: 8);
  }

  static bool _shouldTryNextBase(int statusCode) {
    return statusCode == 404 || statusCode >= 500;
  }

  static bool _shouldFallbackToAnotherBase(Object error) {
    return error is SocketException || error is TimeoutException || error is http.ClientException;
  }

  static ApiException _mapRequestError(
    Object error, {
    required String fallbackMessage,
  }) {
    if (error is ApiException) return error;
    return ApiException(fallbackMessage);
  }

  static String? _extractMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return null;
  }

  static Future<http.Response> _postWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
  }) {
    return http.post(uri, headers: headers, body: body).timeout(timeout);
  }

  static Future<http.Response> postJsonWithFallback(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    String? fallbackMessage,
  }) async {
    ApiException? lastApiError;

    for (final baseUrl in _baseCandidates) {
      final uri = Uri.parse(ApiConfig.endpointFor(baseUrl, path));

      try {
        final response = await _postWithRetry(
          uri,
          headers: {
            'Content-Type': 'application/json',
            ...?headers,
          },
          body: jsonEncode(body),
          timeout: _requestTimeoutFor(baseUrl),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _activeBaseUrl = baseUrl;
          return response;
        }

        lastApiError = ApiException(
          _extractMessage(response) ?? fallbackMessage ?? 'Unable to complete the request.',
        );

        if (!_shouldTryNextBase(response.statusCode)) {
          throw lastApiError;
        }
      } catch (error) {
        if (error is ApiException) {
          rethrow;
        }

        if (!_shouldFallbackToAnotherBase(error)) {
          throw _mapRequestError(
            error,
            fallbackMessage: fallbackMessage ?? 'Unable to complete the request.',
          );
        }
      }
    }

    throw lastApiError ?? ApiException(fallbackMessage ?? 'Unable to complete the request.');
  }

  static String? get activeBaseUrl => _activeBaseUrl;
}