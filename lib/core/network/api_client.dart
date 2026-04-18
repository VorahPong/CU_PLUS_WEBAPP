import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';

import 'download_file_stub.dart'
    if (dart.library.html) 'download_file_web.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? _buildClient();

  final http.Client _client;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  static http.Client _buildClient() {
    if (kIsWeb) {
      final client = BrowserClient()..withCredentials = true;
      return client;
    }
    return http.Client();
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );

    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
    );

    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );

    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final res = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
    );

    return _handleResponse(res);
  }

  Future<void> downloadFile(String path) async {
    final request = http.Request(
      'GET',
      Uri.parse('${ApiConfig.baseUrl}$path'),
    )..headers.addAll(_headers);

    final streamed = await _client.send(request);
    final bytes = await streamed.stream.toBytes();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final body = bytes.isNotEmpty ? utf8.decode(bytes) : '';
      dynamic decoded;

      try {
        decoded = body.isNotEmpty ? jsonDecode(body) : {};
      } catch (_) {
        decoded = null;
      }

      final msg = (decoded is Map && decoded['message'] != null)
          ? decoded['message'].toString()
          : 'Request failed (${streamed.statusCode})';

      throw Exception(msg);
    }

    final contentDisposition =
        streamed.headers['content-disposition'] ??
        streamed.headers['Content-Disposition'];
    final filename = _extractFilename(contentDisposition) ?? 'download.pdf';

    final contentTypeHeader =
        streamed.headers['content-type'] ??
        streamed.headers['Content-Type'] ??
        'application/octet-stream';
    final mediaType = MediaType.parse(contentTypeHeader);

    await saveDownloadedFile(
      bytes,
      filename: filename,
      contentType: mediaType.toString(),
    );
  }

  String? _extractFilename(String? contentDisposition) {
    if (contentDisposition == null || contentDisposition.trim().isEmpty) {
      return null;
    }

    final utf8Match = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    if (utf8Match != null) {
      return Uri.decodeComponent(utf8Match.group(1)!);
    }

    final quotedMatch = RegExp(
      r'filename="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    if (quotedMatch != null) {
      return quotedMatch.group(1);
    }

    final plainMatch = RegExp(
      r'filename=([^;]+)',
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    if (plainMatch != null) {
      return plainMatch.group(1)?.trim();
    }

    return null;
  }

  Map<String, dynamic> _handleResponse(http.Response res) {
    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {};
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Request failed (${res.statusCode})';

    throw Exception(msg);
  }
}
