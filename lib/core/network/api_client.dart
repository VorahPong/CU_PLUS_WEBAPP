import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String? _token;

  void setToken(String? token) {
    _token = token;
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

  Future<Map<String, dynamic>> getJson(String path) async {
    final res = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
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

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null && _token!.isNotEmpty)
        'Authorization': 'Bearer $_token',
    };
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