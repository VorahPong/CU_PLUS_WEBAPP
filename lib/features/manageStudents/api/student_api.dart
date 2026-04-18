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
    final response = await _client.postJson('/admin/students', {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "password": password,
      "schoolId": schoolId,
      "year": year,
    });

    if (response.isEmpty) {
      throw Exception("Failed to create student");
    }
  }

  Future<List<StudentRow>> getStudents({
    String? search,
    String? year,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (year != null && year.trim().isNotEmpty) {
      queryParams['year'] = year.trim();
    }

    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final uri = Uri(path: '/admin/students', queryParameters: queryParams);

    final response = await _client.getJson(uri.toString());
    final students = response['students'] as List<dynamic>? ?? [];

    return students
        .map((item) => StudentRow.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deactivateStudent(String id) async {
    final response = await _client.deleteJson('/admin/students/$id');

    if (response.isEmpty) {
      throw Exception("Failed to deactivate student");
    }
  }

  Future<StudentRow> getStudentById(String id) async {
    final response = await _client.getJson('/admin/students/$id');
    return StudentRow.fromJson(response['student'] as Map<String, dynamic>);
  }

  Future<StudentRow> updateStudent({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String schoolId,
    String? nickname,
  }) async {
    final response = await _client.patchJson('/admin/students/$id', {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'schoolId': schoolId,
      'name': nickname,
    });

    return StudentRow.fromJson(response['student'] as Map<String, dynamic>);
  }

  Future<void> reactivateStudent(String id) async {
    final response = await _client.patchJson(
      '/admin/students/$id/reactivate',
      {},
    );

    if (response.isEmpty) {
      throw Exception("Failed to reactivate student");
    }
  }
}

class StudentRow {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String schoolId;
  final String year;
  final bool isActive;
  final String? nickname;

  StudentRow({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.schoolId,
    required this.year,
    required this.isActive,
    this.nickname,
  });

  String get name => '$firstName $lastName'.trim();

  factory StudentRow.fromJson(Map<String, dynamic> json) {
    return StudentRow(
      id: json['id'].toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      schoolId: (json['schoolId'] ?? '').toString(),
      year: (json['year'] ?? '').toString(),
      isActive: json['isActive'] == true,
      nickname: json['name']?.toString(),
    );
  }
}
