import '../../../core/network/api_client.dart';

class AnnouncementApi {
  final ApiClient _client;

  AnnouncementApi(this._client);

  Future<void> createAnnouncement({
    required String message,
    required bool everyone,
    required bool firstYear,
    required bool secondYear,
    required bool thirdYear,
    required bool fourthYear,
  }) async {
    final response = await _client.postJson('/admin/announcements', {
      "message": message,
      "everyone": everyone,
      "firstYear": firstYear,
      "secondYear": secondYear,
      "thirdYear": thirdYear,
      "fourthYear": fourthYear,
    });

    if (response.isEmpty) {
      throw Exception("Failed to create announcement");
    }
  }

  Future<List<dynamic>> getAnnouncements() async {
    final response = await _client.getJson('/admin/announcements');

    if (response['announcements'] == null) {
      throw Exception("Failed to fetch announcements");
    }

    return response['announcements'] as List<dynamic>;
  }

  Future<void> deleteAnnouncement(String id) async {
    final response = await _client.deleteJson('/admin/announcements/$id');

    if (response.isEmpty) {
      throw Exception("Failed to delete announcement");
    }
  }

  Future<List<dynamic>> getStudentAnnouncements() async {
    final response = await _client.getJson('/student/announcements/my-feed');
    return response['announcements'] as List<dynamic>? ?? [];
  }

  Future<void> updateAnnouncement({
    required String id,
    required String message,
    required bool everyone,
    required bool firstYear,
    required bool secondYear,
    required bool thirdYear,
    required bool fourthYear,
  }) async {
    final response = await _client.putJson('/admin/announcements/$id', {
      "message": message,
      "everyone": everyone,
      "firstYear": firstYear,
      "secondYear": secondYear,
      "thirdYear": thirdYear,
      "fourthYear": fourthYear,
    });

    if (response.isEmpty) {
      throw Exception("Failed to update announcement");
    }
  }
}
