// lib/providers/users_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class UsersProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final AuthService _authService = AuthService();

  List<UserModel> nearbyUsers = [];
  // Interest links between nearby users (for the 3D constellation), as sent by
  // GET /nearby: {source, target, matchPercent, exact}.
  List<Map<String, dynamic>> peerLinks = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchNearbyUsers(double lat, double lng) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final token = await _authService.getToken();
    final response = await _api.get(
      '/users/nearby?latitude=$lat&longitude=$lng&maxDistance=5000',
      token: token,
    );

    isLoading = false;

    if (response['success'] == true && response['users'] != null) {
      nearbyUsers = (response['users'] as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
      peerLinks = (response['peerLinks'] as List? ?? [])
          .map((link) => Map<String, dynamic>.from(link as Map))
          .toList();
    } else {
      errorMessage = response['message'] ?? 'Failed to fetch nearby users';
      nearbyUsers = [];
      peerLinks = [];
    }

    notifyListeners();
  }

  Future<bool> pushLocation(double lat, double lng) async {
    final token = await _authService.getToken();
    final response = await _api.put(
      '/users/location',
      {'latitude': lat, 'longitude': lng},
      token: token,
    );

    return response['success'] == true;
  }

  Future<bool> sendConnection(String receiverId) async {
    final token = await _authService.getToken();
    final response = await _api.post(
      '/users/connect',
      {'receiverId': receiverId},
      token: token,
    );

    return response['success'] == true;
  }

  Future<bool> updateInterests(List<String> interests, {String? preference}) async {
    final token = await _authService.getToken();
    final response = await _api.put(
      '/users/profile',
      {'interests': interests, if (preference != null) 'preference': preference},
      token: token,
    );

    return response['success'] == true;
  }

  Future<bool> updateProfile({
    required String name,
    required String bio,
    required List<String> interests,
    String? preference,
  }) async {
    final token = await _authService.getToken();
    final response = await _api.put(
      '/users/profile',
      {
        'name': name,
        'bio': bio,
        'interests': interests,
        if (preference != null) 'preference': preference,
      },
      token: token,
    );

    return response['success'] == true;
  }
}
