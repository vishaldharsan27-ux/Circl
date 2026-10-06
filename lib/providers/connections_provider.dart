// lib/providers/connections_provider.dart
import 'package:flutter/foundation.dart';
import '../models/incoming_request_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ConnectionsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final AuthService _authService = AuthService();

  List<IncomingRequestModel> incomingRequests = [];
  List<UserModel> acceptedConnections = [];
  bool isLoading = false;
  bool isLoadingConnections = false;
  String? errorMessage;

  int get pendingCount => incomingRequests.length;

  Future<void> fetchAcceptedConnections() async {
    isLoadingConnections = true;
    notifyListeners();

    final token = await _authService.getToken();
    final response = await _api.get('/users/connections/accepted', token: token);

    isLoadingConnections = false;

    if (response['success'] == true && response['connections'] != null) {
      acceptedConnections = (response['connections'] as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } else {
      errorMessage = response['message'] ?? 'Failed to fetch connections';
    }

    notifyListeners();
  }

  Future<void> fetchIncomingRequests() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final token = await _authService.getToken();
    final response = await _api.get('/users/requests/incoming', token: token);

    isLoading = false;

    if (response['success'] == true && response['requests'] != null) {
      incomingRequests = (response['requests'] as List)
          .map((json) => IncomingRequestModel.fromJson(json))
          .toList();
    } else {
      errorMessage = response['message'] ?? 'Failed to fetch requests';
    }

    notifyListeners();
  }

  Future<bool> respond(String connectionId, String status) async {
    final token = await _authService.getToken();
    final response = await _api.put(
      '/users/connect/$connectionId/respond',
      {'status': status},
      token: token,
    );

    if (response['success'] == true) {
      incomingRequests.removeWhere((r) => r.connectionId == connectionId);
      notifyListeners();
      return true;
    }

    return false;
  }

  void addIncomingRequestFromSocket(dynamic data) {
    if (data is! Map) return;

    final placeholder = IncomingRequestModel(
      connectionId: data['connectionId']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName'] ?? 'Someone',
      avatarColor: data['avatarColor'] ?? '#00E676',
    );

    incomingRequests = [placeholder, ...incomingRequests];
    notifyListeners();
  }
}
