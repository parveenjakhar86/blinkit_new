import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenPrefKey = 'customerToken';
  static const _profilePrefKey = 'customerProfile';
  static const _savedAddressesPrefKey = 'savedAddresses';
  static const _selectedAddressIdPrefKey = 'selectedAddressId';

  String? _token;
  Map<String, dynamic>? _customer;
  List<Map<String, dynamic>> _savedAddresses = [];
  String? _selectedAddressId;
  bool _loading = false;
  String? _error;

  String? get token => _token;
  Map<String, dynamic>? get customer => _customer;
  List<Map<String, dynamic>> get savedAddresses => List.unmodifiable(
    _savedAddresses,
  );
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _token != null;

  Map<String, dynamic>? get selectedAddress {
    for (final address in _savedAddresses) {
      if (address['id'] == _selectedAddressId) {
        return address;
      }
    }
    return null;
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenPrefKey);
    final customerJson = prefs.getString(_profilePrefKey);
    if (customerJson != null) {
      _customer = jsonDecode(customerJson);
    }
    final savedAddressesJson = prefs.getString(_savedAddressesPrefKey);
    if (savedAddressesJson != null) {
      final decoded = jsonDecode(savedAddressesJson);
      if (decoded is List) {
        _savedAddresses = decoded
            .whereType<Map>()
            .map(
              (entry) => _normalizeAddress(
                entry.map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              ),
            )
            .where((entry) => entry['address'].toString().trim().isNotEmpty)
            .toList();
      }
    }
    _selectedAddressId = prefs.getString(_selectedAddressIdPrefKey);
    _ensureAddressBookSeeded();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final loginUri = await ApiService.resolveUri('customer/login');
      final resp = await http.post(
        loginUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200) {
        _token = data['token'];
        _customer = data['customer'];
        _ensureAddressBookSeeded();
        final prefs = await SharedPreferences.getInstance();
        await _persistToPrefs(prefs);
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
    _savedAddresses = [];
    _selectedAddressId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefKey);
    await prefs.remove(_profilePrefKey);
    await prefs.remove(_savedAddressesPrefKey);
    await prefs.remove(_selectedAddressIdPrefKey);
    notifyListeners();
  }

  Future<void> updateCustomerProfile(Map<String, dynamic> updates) async {
    final merged = <String, dynamic>{...?_customer, ...updates};
    _customer = merged;
    _syncSelectedAddressWithProfile(merged);
    final prefs = await SharedPreferences.getInstance();
    await _persistToPrefs(prefs);
    notifyListeners();
  }

  Future<void> upsertSavedAddress(
    Map<String, dynamic> address, {
    bool select = true,
  }) async {
    final normalized = _normalizeAddress(address);
    final index = _savedAddresses.indexWhere(
      (entry) => entry['id'] == normalized['id'],
    );

    if (index >= 0) {
      _savedAddresses[index] = normalized;
    } else {
      _savedAddresses = [normalized, ..._savedAddresses];
    }

    if (select || _selectedAddressId == normalized['id']) {
      _selectedAddressId = normalized['id'] as String;
    }

    _syncCustomerFromSelectedAddress();
    final prefs = await SharedPreferences.getInstance();
    await _persistToPrefs(prefs);
    notifyListeners();
  }

  Future<void> selectSavedAddress(String addressId) async {
    final exists = _savedAddresses.any((entry) => entry['id'] == addressId);
    if (!exists) return;

    _selectedAddressId = addressId;
    _syncCustomerFromSelectedAddress();
    final prefs = await SharedPreferences.getInstance();
    await _persistToPrefs(prefs);
    notifyListeners();
  }

  Future<void> deleteSavedAddress(String addressId) async {
    _savedAddresses = _savedAddresses
        .where((entry) => entry['id'] != addressId)
        .toList();

    if (_selectedAddressId == addressId) {
      _selectedAddressId = _savedAddresses.isEmpty
          ? null
          : _savedAddresses.first['id'] as String?;
    }

    _syncCustomerFromSelectedAddress();
    final prefs = await SharedPreferences.getInstance();
    await _persistToPrefs(prefs);
    notifyListeners();
  }

  void _ensureAddressBookSeeded() {
    if (_savedAddresses.isNotEmpty) {
      if (_selectedAddressId == null || selectedAddress == null) {
        _selectedAddressId = _savedAddresses.first['id'] as String?;
      }
      _syncCustomerFromSelectedAddress();
      return;
    }

    final seeded = _addressFromCustomer(_customer);
    if (seeded != null) {
      _savedAddresses = [seeded];
      _selectedAddressId = seeded['id'] as String;
      _syncCustomerFromSelectedAddress();
    }
  }

  Map<String, dynamic>? _addressFromCustomer(Map<String, dynamic>? customer) {
    if (customer == null) return null;

    final address = (customer['address'] ?? '').toString().trim();
    final state = (customer['state'] ?? '').toString().trim();
    final pinCode = (customer['pinCode'] ?? '').toString().trim();

    if (address.isEmpty && state.isEmpty && pinCode.isEmpty) {
      return null;
    }

    return _normalizeAddress({
      'id': 'seeded-home-address',
      'label': 'Home',
      'name': (customer['name'] ?? '').toString().trim(),
      'phone': (customer['phone'] ?? '').toString().trim(),
      'address': address,
      'state': state,
      'pinCode': pinCode,
    });
  }

  void _syncSelectedAddressWithProfile(Map<String, dynamic> profile) {
    final selected = selectedAddress;
    if (selected == null) return;

    final updated = _normalizeAddress({
      ...selected,
      'name': (profile['name'] ?? '').toString().trim(),
      'phone': (profile['phone'] ?? '').toString().trim(),
      'address': (profile['address'] ?? '').toString().trim(),
      'state': (profile['state'] ?? '').toString().trim(),
      'pinCode': (profile['pinCode'] ?? '').toString().trim(),
    });

    _savedAddresses = _savedAddresses.map((entry) {
      return entry['id'] == updated['id'] ? updated : entry;
    }).toList();
    _selectedAddressId = updated['id'] as String;
  }

  void _syncCustomerFromSelectedAddress() {
    final selected = selectedAddress;
    final current = <String, dynamic>{...?_customer};

    if (selected == null) {
      current['address'] = '';
      current['state'] = '';
      current['pinCode'] = '';
      _customer = current.isEmpty ? null : current;
      return;
    }

    current['name'] = (selected['name'] ?? current['name'] ?? '').toString();
    current['phone'] =
        (selected['phone'] ?? current['phone'] ?? '').toString();
    current['address'] = (selected['address'] ?? '').toString();
    current['state'] = (selected['state'] ?? '').toString();
    current['pinCode'] = (selected['pinCode'] ?? '').toString();
    _customer = current;
  }

  Map<String, dynamic> _normalizeAddress(Map<String, dynamic> input) {
    final id = (input['id'] ?? '').toString().trim();
    final label = (input['label'] ?? 'Home').toString().trim();
    final name = (input['name'] ?? '').toString().trim();
    final phone = (input['phone'] ?? '').toString().trim();
    final address = (input['address'] ?? '').toString().trim();
    final state = (input['state'] ?? '').toString().trim();
    final pinCode = (input['pinCode'] ?? '').toString().trim();

    return {
      'id': id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id,
      'label': label.isEmpty ? 'Home' : label,
      'name': name,
      'phone': phone,
      'address': address,
      'state': state,
      'pinCode': pinCode,
    };
  }

  Future<void> _persistToPrefs(SharedPreferences prefs) async {
    if (_token == null) {
      await prefs.remove(_tokenPrefKey);
    } else {
      await prefs.setString(_tokenPrefKey, _token!);
    }

    if (_customer == null) {
      await prefs.remove(_profilePrefKey);
    } else {
      await prefs.setString(_profilePrefKey, jsonEncode(_customer));
    }

    await prefs.setString(_savedAddressesPrefKey, jsonEncode(_savedAddresses));

    if (_selectedAddressId == null) {
      await prefs.remove(_selectedAddressIdPrefKey);
    } else {
      await prefs.setString(_selectedAddressIdPrefKey, _selectedAddressId!);
    }
  }
}
