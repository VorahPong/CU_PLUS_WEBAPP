import '../../../core/network/api_client.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _client.postJson('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> verifyTwoFactor({
    required String email,
    required String code,
  }) {
    return _client.postJson('/auth/verify-2fa', {
      'email': email,
      'code': code,
    });
  }

  Future<Map<String, dynamic>> resendTwoFactor({
    required String email,
  }) {
    return _client.postJson('/auth/resend-2fa', {
      'email': email,
    });
  }

  Future<Map<String, dynamic>> me() {
    return _client.getJson('/auth/me');
  }

  Future<Map<String, dynamic>> logout() {
    return _client.postJson('/auth/logout', {});
  }
}