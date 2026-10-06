// lib/providers/pitch_provider.dart
import 'package:flutter/foundation.dart';
import '../models/pitch_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class PitchProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final AuthService _authService = AuthService();

  String? otherUserId;
  PitchModel? myPitch;
  PitchModel? theirPitch;
  bool bothAccepted = false;
  String? meetLink;
  bool isLoading = false;
  String? errorMessage;

  bool get canMeet => bothAccepted;

  Future<void> fetchPitchWith(String userId) async {
    otherUserId = userId;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final token = await _authService.getToken();
    final response = await _api.get('/pitch/with/$userId', token: token);

    isLoading = false;

    if (response['success'] == true) {
      myPitch = response['mine'] != null ? PitchModel.fromJson(response['mine']) : null;
      theirPitch = response['theirs'] != null ? PitchModel.fromJson(response['theirs']) : null;
      bothAccepted = response['bothAccepted'] == true;
    } else {
      errorMessage = response['message'] ?? 'Failed to fetch pitch';
    }

    notifyListeners();
  }

  Future<bool> sendPitch(String toUserId, String text) async {
    final token = await _authService.getToken();
    final response = await _api.post(
      '/pitch',
      {'toUserId': toUserId, 'text': text},
      token: token,
    );

    if (response['success'] == true && response['pitch'] != null) {
      myPitch = PitchModel.fromJson(response['pitch']);
      notifyListeners();
      return true;
    }

    errorMessage = response['message'] ?? 'Failed to send pitch';
    notifyListeners();
    return false;
  }

  Future<bool> respondToPitch(String pitchId, String status) async {
    final token = await _authService.getToken();
    final response = await _api.put(
      '/pitch/$pitchId/respond',
      {'status': status},
      token: token,
    );

    if (response['success'] == true && response['pitch'] != null) {
      theirPitch = PitchModel.fromJson(response['pitch']);
      bothAccepted = myPitch?.status == 'accepted' && theirPitch?.status == 'accepted';
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<bool> shareMeetLink(String toUserId, String link) async {
    final token = await _authService.getToken();
    final response = await _api.post(
      '/pitch/meet/share',
      {'toUserId': toUserId, 'meetLink': link},
      token: token,
    );

    if (response['success'] == true) {
      meetLink = link;
      notifyListeners();
      return true;
    }

    return false;
  }

  void handlePitchReceived(dynamic data) {
    if (data is! Map || data['fromUserId']?.toString() != otherUserId) return;
    theirPitch = PitchModel(
      id: data['pitchId']?.toString() ?? '',
      fromUser: otherUserId ?? '',
      toUser: '',
      text: data['text'] ?? '',
      status: 'pending',
    );
    notifyListeners();
  }

  void handlePitchResponded(dynamic data) {
    if (data is! Map) return;
    final status = data['status'] ?? 'pending';
    if (myPitch != null && data['pitchId']?.toString() == myPitch!.id) {
      myPitch = PitchModel(
        id: myPitch!.id,
        fromUser: myPitch!.fromUser,
        toUser: myPitch!.toUser,
        text: myPitch!.text,
        status: status,
      );
      bothAccepted = myPitch?.status == 'accepted' && theirPitch?.status == 'accepted';
      notifyListeners();
    }
  }

  void handlePitchMatched(dynamic data) {
    if (data is! Map || otherUserId == null) return;
    final userIds = (data['userIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
    if (userIds.contains(otherUserId)) {
      bothAccepted = true;
      notifyListeners();
    }
  }

  void handleMeetLinkShared(dynamic data) {
    if (data is! Map || data['fromUserId']?.toString() != otherUserId) return;
    meetLink = data['meetLink'];
    notifyListeners();
  }

  void reset() {
    otherUserId = null;
    myPitch = null;
    theirPitch = null;
    bothAccepted = false;
    meetLink = null;
    errorMessage = null;
  }
}
