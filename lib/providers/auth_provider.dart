// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  UserModel? currentUser;
  bool isLoggedIn = false;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required int age,
    required List<String> interests,
    required double lat,
    required double lng,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      age: age,
      interests: interests,
      lat: lat,
      lng: lng,
    );

    isLoading = false;

    if (result['success'] == true) {
      currentUser = result['user'];
      isLoggedIn = true;
      notifyListeners();
      return true;
    }

    errorMessage = result['message'];
    notifyListeners();
    return false;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email: email, password: password);

    isLoading = false;

    if (result['success'] == true) {
      currentUser = result['user'];
      isLoggedIn = true;
      notifyListeners();
      return true;
    }

    errorMessage = result['message'];
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    isLoggedIn = false;
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      isLoggedIn = false;
      notifyListeners();
      return false;
    }

    final response = await _apiService.get('/users/profile', token: token);

    if (response['success'] == true && response['user'] != null) {
      currentUser = UserModel.fromJson(response['user']);
      isLoggedIn = true;
      notifyListeners();
      return true;
    }

    isLoggedIn = false;
    notifyListeners();
    return false;
  }

  void updateCurrentUser(UserModel user) {
    currentUser = user;
    notifyListeners();
  }
}
