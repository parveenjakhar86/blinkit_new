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
  static const Duration _requestTimeout = Duration(seconds: 12);

  static Future<List<Product>> fetchProducts() async {
    try {
      final resp = await http
          .get(Uri.parse(ApiConfig.products))
          .timeout(_requestTimeout);

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

  static Future<Map<String, dynamic>> placeOrder({
    required Map<String, dynamic> customerDetails,
    required List<Map<String, dynamic>> products,
    required String paymentMethod,
    required double totalAmount,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse(ApiConfig.placeOrder),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'customerDetails': customerDetails,
              'products': products,
              'paymentMethod': paymentMethod,
              'totalAmount': totalAmount,
            }),
          )
          .timeout(_requestTimeout);

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
        'The server took too long to respond. Please try again.',
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
}
