import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  String? _token;
  DateTime? _expires;
  Timer? _expiryTimer;
  bool get isAuthenticated {
    final token = _token;
    final expiry = _expires;
    if (token == null || expiry == null || !DateTime.now().isBefore(expiry)) {
      return false;
    }
    final segments = token.split('.');
    if (segments.length != 3 ||
        segments[0] != 'mock' ||
        segments[2] != 'signature') {
      return false;
    }
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      ) as Map<String, dynamic>;
      final subject = payload['sub'] as String?;
      final expiration = payload['exp'] as int?;
      return subject != null &&
          subject.trim().isNotEmpty &&
          expiration != null &&
          DateTime.fromMillisecondsSinceEpoch(expiration * 1000)
              .isAtSameMomentAs(
                DateTime.fromMillisecondsSinceEpoch(
                  expiry.millisecondsSinceEpoch ~/ 1000 * 1000,
                ),
              );
    } on Object {
      return false;
    }
  }

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
    try {
      await _storage.write(key: 'mock_jwt', value: _token);
      await _storage.write(
        key: 'mock_jwt_expiry',
        value: exp.toIso8601String(),
      );
    } on Object catch (_) {
      _token = null;
      _expires = null;
      await _storage.delete(key: 'mock_jwt');
      await _storage.delete(key: 'mock_jwt_expiry');
      rethrow;
    }
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
