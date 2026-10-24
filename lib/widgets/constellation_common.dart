// lib/widgets/constellation_common.dart
// Shared by the native (WebView) and web (iframe) ConstellationView variants.
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/network_config.dart';

/// Served by backend/server.js from backend/public/constellation/.
String get constellationUrl => '$backendOrigin/constellation/index.html';

/// Lets the home screen ask the 3D view to fly the camera back to the
/// starting position (e.g. after the profile sheet for a tapped node closes).
class ConstellationController extends ChangeNotifier {
  void recenter() => notifyListeners();
}

/// The data the constellation page draws — see the comment at the top of
/// backend/public/constellation/index.html for the shape it expects.
Map<String, dynamic> buildConstellationPayload({
  required UserModel? me,
  required List<UserModel> users,
  required List<Map<String, dynamic>> peerLinks,
}) {
  return {
    'me': {
      'name': me?.name ?? 'You',
      'interests': me?.interests ?? const <String>[],
      'preference': me?.preference,
      'avatarColor': me?.avatarColor ?? '#00E676',
    },
    'users': users
        .map((u) => {
              'id': u.id,
              'name': u.name,
              'interests': u.interests,
              'matchPercent': u.matchPercent,
              'distanceKm': u.distanceKm,
              'preference': u.preference,
              'preferenceMatch': u.preferenceMatch,
              'avatarColor': u.avatarColor,
              'connectionStatus': u.connectionStatus,
            })
        .toList(),
    'peerLinks': peerLinks,
  };
}
