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

  Future<Map<String, dynamic>> me() {
    return _client.getJson('/auth/me');
  }

  Future<Map<String, dynamic>> logout() {
    return _client.postJson('/auth/logout', {});
  }
}