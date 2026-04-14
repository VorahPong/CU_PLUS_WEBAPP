import 'package:cu_plus_webapp/core/network/api_client.dart';

class SettingsApi {
  SettingsApi(this._client);

  final ApiClient _client;

  /// GET /me
  Future<Map<String, dynamic>> getProfile() async {
    final res = await _client.getJson('/me') as Map<String, dynamic>;
    return (res['user'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// PATCH /me
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? name,
  }) async {
    final body = <String, dynamic>{};

    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (name != null) body['name'] = name;

    final res = await _client.patchJson('/me', body) as Map<String, dynamic>;

    return (res['user'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// POST /me/profile-image
  Future<Map<String, dynamic>> uploadProfileImage({
    required String dataUrl,
  }) async {
    final res =
        await _client.postJson('/me/profile-image', {'dataUrl': dataUrl})
            as Map<String, dynamic>;

    return (res['user'] as Map?)?.cast<String, dynamic>() ?? {};
  }
}
