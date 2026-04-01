import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import '../config/api_config.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? _buildClient();

  final http.Client _client;

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
      headers: {
        'Content-Type': 'application/json',
      },
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
      headers: {
        'Content-Type': 'application/json',
      },
    );

    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final res = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    return _handleResponse(res);
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