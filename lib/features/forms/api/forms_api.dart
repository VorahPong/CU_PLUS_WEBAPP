import 'package:cu_plus_webapp/core/network/api_client.dart';

class FormsApi {
  final ApiClient _client;

  FormsApi(this._client);

  Future<Map<String, dynamic>> createForm({
    required String title,
    String? description,
    String? year,
    String? dueDate,
    String? instructions,
    required List<Map<String, dynamic>> fields,
  }) async {
    return await _client.postJson('/admin/forms', {
      'title': title,
      'description': description,
      'year': year,
      'dueDate': dueDate,
      'instructions': instructions,
      'fields': fields,
    });
  }

  Future<List<dynamic>> getAdminForms() async {
    final res = await _client.getJson('/admin/forms');
    return res['forms'] ?? [];
  }

  Future<Map<String, dynamic>> getAdminFormById(String id) async {
    final res = await _client.getJson('/admin/forms/$id');
    return res['form'];
  }

  Future<Map<String, dynamic>> updateForm({
    required String id,
    required String title,
    String? description,
    String? year,
    String? dueDate,
    String? instructions,
    bool? isActive,
    required List<Map<String, dynamic>> fields,
  }) async {
    return await _client.putJson('/admin/forms/$id', {
      'title': title,
      'description': description,
      'year': year,
      'dueDate': dueDate,
      'instructions': instructions,
      'isActive': isActive,
      'fields': fields,
    });
  }
}