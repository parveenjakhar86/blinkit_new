import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _customer;
  bool _loading = false;
  String? _error;

  String? get token => _token;
  Map<String, dynamic>? get customer => _customer;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _token != null;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('customerToken');
    final customerJson = prefs.getString('customerProfile');
    if (customerJson != null) {
      _customer = jsonDecode(customerJson);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200) {
        _token = data['token'];
        _customer = data['customer'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customerToken', _token!);
        await prefs.setString('customerProfile', jsonEncode(_customer));
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Login failed';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error. Is the server running?';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _customer = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('customerToken');
    await prefs.remove('customerProfile');
    notifyListeners();
  }
}
