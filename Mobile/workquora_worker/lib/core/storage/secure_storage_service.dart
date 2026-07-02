import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens go in platform Keychain/Keystore — NOT Hive, NOT SharedPreferences.
/// Hive is for cacheable app data (lists, profiles); secrets stay isolated here.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'wq_access_token';
  static const _refreshTokenKey = 'wq_refresh_token';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);

  Future<void> updateAccessToken(String token) => _storage.write(key: _accessTokenKey, value: token);

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  Future<bool> get hasSession async => (await accessToken) != null;

  // Generic key-value helpers (used by the one-time Terms gate, and any
  // future small flags). Kept separate from token methods on purpose.
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<String?> read(String key) => _storage.read(key: key);
}
