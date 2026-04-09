import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class RiderAuthProvider extends ChangeNotifier {
  static const _tokenPrefKey = 'riderToken';
  static const _profilePrefKey = 'riderProfile';

  String? _token;
  Map<String, dynamic>? _rider;
  bool _loading = false;
  bool _isReady = false;
  String? _error;

  String? get token => _token;
  Map<String, dynamic>? get rider => _rider;
  bool get loading => _loading;
  bool get isReady => _isReady;
  String? get error => _error;
  bool get isLoggedIn => _token != null;

  Map<String, dynamic>? _decodeMapOrNull(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return null;
  }

  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenPrefKey);
      final riderJson = prefs.getString(_profilePrefKey);
      if (riderJson != null) {
        _rider = jsonDecode(riderJson);
      }
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<void> _persistToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token == null) {
      await prefs.remove(_tokenPrefKey);
    } else {
      await prefs.setString(_tokenPrefKey, _token!);
    }

    if (_rider == null) {
      await prefs.remove(_profilePrefKey);
    } else {
      await prefs.setString(_profilePrefKey, jsonEncode(_rider));
    }
  }

  Future<String?> requestOtp(String phone, {String name = ''}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await ApiService.postJsonWithFallback(
        'rider/send-otp',
        body: {'phone': phone, 'name': name},
        fallbackMessage:
            'Send OTP failed. Render is unavailable and the local Wi-Fi backend could not be reached.',
      );
      final data = _decodeMapOrNull(resp.body);

      if (resp.statusCode == 200) {
        _loading = false;
        notifyListeners();
        return data?['otp']?.toString();
      }

      _error = data?['message']?.toString() ?? 'Send OTP failed.';
      _loading = false;
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      _error = error.message;
      _loading = false;
      notifyListeners();
      return null;
    } catch (_) {
      _error = 'Cannot reach OTP service.';
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyOtp({
    required String phone,
    required String otp,
    String name = '',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await ApiService.postJsonWithFallback(
        'rider/verify-otp',
        body: {'phone': phone, 'otp': otp, 'name': name},
        fallbackMessage:
            'OTP verification failed. Render is unavailable and the local Wi-Fi backend could not be reached.',
      );
      final data = _decodeMapOrNull(resp.body);

      if (resp.statusCode == 200) {
        _token = data?['token']?.toString();
        _rider = (data?['rider'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        await _persistToPrefs();
        _loading = false;
        notifyListeners();
        return true;
      }

      _error = data?['message']?.toString() ?? 'OTP verification failed.';
      _loading = false;
      notifyListeners();
      return false;
    } on ApiException catch (error) {
      _error = error.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Cannot reach OTP verification service.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _rider = null;
    await _persistToPrefs();
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}