import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyAccess = 'jwt_access_token';
  static const _keyRefresh = 'jwt_refresh_token';
  static const _keyRole = 'user_role';
  static const _keyUserId = 'user_id';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String role,
    required int userId,
  }) async {
    await _storage.write(key: _keyAccess, value: accessToken);
    await _storage.write(key: _keyRefresh, value: refreshToken);
    await _storage.write(key: _keyRole, value: role);
    await _storage.write(key: _keyUserId, value: userId.toString());
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccess);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefresh);
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: _keyRole);
  }

  static Future<int?> getUserId() async {
    final str = await _storage.read(key: _keyUserId);
    return str != null ? int.tryParse(str) : null;
  }

  static Future<void> updateAccessToken(String token) async {
    await _storage.write(key: _keyAccess, value: token);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
