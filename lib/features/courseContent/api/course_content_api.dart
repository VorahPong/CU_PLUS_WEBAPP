import 'package:cu_plus_webapp/core/network/api_client.dart';

class CourseContentApi {
  CourseContentApi(this._client);

  final ApiClient _client;

  Future<List<dynamic>> getCourseContentTree() async {
    final res = await _client.getJson('/course-content/tree');
    return (res['folders'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> createRootFolder({
    required String title,
    int sortOrder = 0,
  }) async {
    final res = await _client.postJson('/course-content/admin/folders', {
      'title': title,
      'sortOrder': sortOrder,
    });

    return Map<String, dynamic>.from(res['folder']);
  }

  Future<Map<String, dynamic>> createSubfolder({
    required String parentFolderId,
    required String title,
    int sortOrder = 0,
  }) async {
    final res = await _client.postJson(
      '/course-content/admin/folders/$parentFolderId/subfolders',
      {
        'title': title,
        'sortOrder': sortOrder,
      },
    );

    return Map<String, dynamic>.from(res['folder']);
  }

  Future<Map<String, dynamic>> updateFolder({
    required String folderId,
    String? title,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{};

    if (title != null) body['title'] = title;
    if (sortOrder != null) body['sortOrder'] = sortOrder;

    final res = await _client.patchJson(
      '/course-content/admin/folders/$folderId',
      body,
    );

    return Map<String, dynamic>.from(res['folder']);
  }

  Future<Map<String, dynamic>> moveFolder({
    required String folderId,
    String? parentId,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{
      'parentId': parentId,
    };

    if (sortOrder != null) body['sortOrder'] = sortOrder;

    final res = await _client.patchJson(
      '/course-content/admin/folders/$folderId/move',
      body,
    );

    return Map<String, dynamic>.from(res['folder']);
  }

  Future<void> deleteFolder(String folderId) async {
    await _client.deleteJson('/course-content/admin/folders/$folderId');
  }

  Future<Map<String, dynamic>> attachFormToFolder({
    required String folderId,
    required String formId,
    int sortOrder = 0,
  }) async {
    final res = await _client.postJson(
      '/course-content/admin/folders/$folderId/forms',
      {
        'formId': formId,
        'sortOrder': sortOrder,
      },
    );

    return Map<String, dynamic>.from(res['link']);
  }

  Future<void> detachFormFromFolder({
    required String folderId,
    required String formId,
  }) async {
    await _client.deleteJson('/course-content/admin/folders/$folderId/forms/$formId');
  }

  Future<Map<String, dynamic>> updateAttachedFormOrder({
    required String folderId,
    required String formId,
    required int sortOrder,
  }) async {
    final res = await _client.patchJson(
      '/course-content/admin/folders/$folderId/forms/$formId',
      {
        'sortOrder': sortOrder,
      },
    );

    return Map<String, dynamic>.from(res['link']);
  }
}