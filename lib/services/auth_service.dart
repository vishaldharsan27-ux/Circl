// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int age,
    required List<String> interests,
    required double lat,
    required double lng,
  }) async {
    final response = await _api.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'age': age,
      'interests': interests,
      'latitude': lat,
      'longitude': lng,
    });

    if (response['success'] == true && response['token'] != null) {
      final user = UserModel.fromJson(response['user']);
      await _saveSession(response['token'], user.id);
      return {'success': true, 'user': user, 'token': response['token']};
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Registration failed',
    };
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response['success'] == true && response['token'] != null) {
      final user = UserModel.fromJson(response['user']);
      await _saveSession(response['token'], user.id);
      return {'success': true, 'user': user, 'token': response['token']};
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Login failed',
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<void> _saveSession(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userId', userId);
  }
}
