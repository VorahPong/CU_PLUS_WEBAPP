import '../../../core/network/api_client.dart';

class AuthApi {
  final ApiClient _api;
  AuthApi(this._api);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _api.postJson(
      "/auth/login",
      {"email": email, "password": password},
    );
  }
}