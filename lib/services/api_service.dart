// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'network_config.dart';

class ApiService {
  static String get baseUrl => '$backendOrigin/api';

  Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint, {String? token}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Map<String, String> _buildHeaders(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> decoded = {};
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      decoded = {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      decoded['success'] = true;
      return decoded;
    } else {
      decoded['success'] = false;
      decoded['message'] = decoded['message'] ?? 'Something went wrong';
      return decoded;
    }
  }
}
