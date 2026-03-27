import '../../../core/network/api_client.dart';

class StudentApi {
  final ApiClient _client;

  StudentApi(this._client);

  Future<void> createStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String schoolId,
    required String year,
  }) async {
    final response = await _client.postJson(
      '/admin/students',
      {
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "password": password,
        "schoolId": schoolId,
        "year": year,
      },
    );

    // optional: handle response
    if (response == null) {
      throw Exception("Failed to create student");
    }
  }
}