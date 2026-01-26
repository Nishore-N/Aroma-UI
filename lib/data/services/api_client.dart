// lib/data/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants/api_endpoints.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiEndpoints.baseUrl;

  Uri _buildUri(String path) {
    // Allow passing a full URL directly.
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }

    final trimmedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final trimmedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$trimmedBase/$trimmedPath');
  }

  Future<dynamic> get(String path) async {
    final url = _buildUri(path);
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    return _handleResponse(response);
  }

  Future<dynamic> getList(String path) async {
    return await get(path);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final url = _buildUri(path);
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
}