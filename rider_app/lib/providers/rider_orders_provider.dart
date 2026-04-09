import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/rider_earnings_summary.dart';
import '../models/rider_order.dart';
import '../services/api_service.dart';

class RiderOrdersProvider extends ChangeNotifier {
  String? _token;
  bool _loadingOrders = false;
  bool _loadingEarnings = false;
  String? _error;
  List<RiderOrder> _activeOrders = const [];
  List<RiderOrder> _availableOrders = const [];
  RiderEarningsSummary? _earnings;

  List<RiderOrder> get activeOrders => _activeOrders;
  List<RiderOrder> get availableOrders => _availableOrders;
  RiderEarningsSummary? get earnings => _earnings;
  bool get loadingOrders => _loadingOrders;
  bool get loadingEarnings => _loadingEarnings;
  String? get error => _error;

  void updateToken(String? token) {
    final changed = _token != token;
    _token = token;
    if (!changed) return;

    if (_token == null) {
      _activeOrders = const [];
      _availableOrders = const [];
      _earnings = null;
      _error = null;
      notifyListeners();
    }
  }

  Future<http.Response> _authorizedGet(String path) async {
    ApiException? lastApiError;
    for (final baseUrl in ApiConfig.candidateBaseUrls) {
      final uri = Uri.parse(ApiConfig.endpointFor(baseUrl, path));
      try {
        final response = await http.get(
          uri,
          headers: {'Authorization': 'Bearer $_token'},
        ).timeout(
          baseUrl.contains('onrender.com')
              ? const Duration(seconds: 20)
              : const Duration(seconds: 8),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        lastApiError = ApiException(_extractMessage(response) ?? 'Request failed');
        if (response.statusCode != 404 && response.statusCode < 500) {
          throw lastApiError;
        }
      } catch (error) {
        if (error is ApiException) rethrow;
      }
    }
    throw lastApiError ?? ApiException('Unable to fetch rider data.');
  }

  String? _extractMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return null;
  }

  Future<void> fetchOrders() async {
    if (_token == null) return;
    _loadingOrders = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authorizedGet('rider/orders');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final active = decoded['activeOrders'] as List? ?? const [];
      final available = decoded['availableOrders'] as List? ?? const [];
      _activeOrders = active
          .whereType<Map>()
          .map((entry) => RiderOrder.fromJson(entry.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
      _availableOrders = available
          .whereType<Map>()
          .map((entry) => RiderOrder.fromJson(entry.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Unable to fetch rider orders.';
    } finally {
      _loadingOrders = false;
      notifyListeners();
    }
  }

  Future<void> fetchEarnings() async {
    if (_token == null) return;
    _loadingEarnings = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authorizedGet('rider/earnings');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      _earnings = RiderEarningsSummary.fromJson(decoded);
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Unable to fetch rider earnings.';
    } finally {
      _loadingEarnings = false;
      notifyListeners();
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    if (_token == null) return false;

    try {
      final response = await ApiService.postJsonWithFallback(
        'rider/orders/$orderId/accept',
        body: const {},
        headers: {'Authorization': 'Bearer $_token'},
        fallbackMessage: 'Unable to accept order.',
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await fetchOrders();
        await fetchEarnings();
        return true;
      }
    } catch (_) {}

    _error = 'Unable to accept order.';
    notifyListeners();
    return false;
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    if (_token == null) return false;

    try {
      final response = await ApiService.patchJsonWithFallback(
        'rider/orders/$orderId/status',
        body: {'status': status},
        headers: {'Authorization': 'Bearer $_token'},
        fallbackMessage: 'Unable to update order status.',
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await fetchOrders();
        await fetchEarnings();
        return true;
      }
    } catch (_) {}

    _error = 'Unable to update order status.';
    notifyListeners();
    return false;
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchOrders(), fetchEarnings()]);
  }
}