import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens go in platform Keychain/Keystore — NOT Hive, NOT SharedPreferences.
/// Hive is for cacheable app data (lists, profiles); secrets stay isolated here.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'wq_access_token';
  static const _refreshTokenKey = 'wq_refresh_token';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
      ]);
    } catch (e) {
      print('⚠️ SecureStorage save failed: $e');
    }
  }

  Future<String?> get accessToken async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      print('⚠️ SecureStorage read accessToken failed: $e');
      return null;
    }
  }

  Future<String?> get refreshToken async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      print('⚠️ SecureStorage read refreshToken failed: $e');
      return null;
    }
  }

  Future<void> updateAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
    } catch (e) {
      print('⚠️ SecureStorage update failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
      ]);
    } catch (e) {
      print('⚠️ SecureStorage clear failed: $e');
    }
  }

  Future<bool> get hasSession async => (await accessToken) != null;

  // Generic key-value helpers (used by the one-time Terms gate, and any
  // future small flags). Kept separate from token methods on purpose.
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      print('⚠️ SecureStorage write failed: $e');
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      print('⚠️ SecureStorage read failed: $e');
      return null;
    }
  }
}
