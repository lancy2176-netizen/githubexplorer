import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  String? _token;
  DateTime? _expires;
  Timer? _expiryTimer;
  bool get isAuthenticated =>
      _token != null && _expires != null && DateTime.now().isBefore(_expires!);
  String? get token => isAuthenticated ? _token : null;

  Future<void> restore() async {
    _token = await _storage.read(key: 'mock_jwt');
    final expiry = await _storage.read(key: 'mock_jwt_expiry');
    _expires = expiry == null ? null : DateTime.tryParse(expiry);
    if (!isAuthenticated) {
      await logout();
    } else {
      _scheduleExpiry();
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      throw const FormatException('Enter a username and password.');
    }
    final exp = DateTime.now().add(const Duration(hours: 8));
    // This assignment uses a mock identity provider. The opaque JWT-shaped token is not GitHub OAuth.
    final payload = base64Url.encode(
      utf8.encode(
        jsonEncode({
          'sub': username.trim(),
          'exp': exp.millisecondsSinceEpoch ~/ 1000,
        }),
      ),
    );
    _token = 'mock.$payload.signature';
    _expires = exp;
    await _storage.write(key: 'mock_jwt', value: _token);
    await _storage.write(key: 'mock_jwt_expiry', value: exp.toIso8601String());
    _scheduleExpiry();
    notifyListeners();
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final remaining = _expires?.difference(DateTime.now());
    if (remaining != null && !remaining.isNegative) {
      _expiryTimer = Timer(remaining, () {
        _token = null;
        _expires = null;
        _storage.delete(key: 'mock_jwt');
        _storage.delete(key: 'mock_jwt_expiry');
        notifyListeners();
      });
    }
  }

  Future<void> logout() async {
    _expiryTimer?.cancel();
    _token = null;
    _expires = null;
    await _storage.delete(key: 'mock_jwt');
    await _storage.delete(key: 'mock_jwt_expiry');
    notifyListeners();
  }
}
