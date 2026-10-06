// lib/services/network_config.dart
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Resolves the full origin (scheme://host[:port]) used to reach the backend.
/// - A `BACKEND_ORIGIN` value passed via `--dart-define` always wins — used
///   for native builds (Android/iOS) where the backend isn't reachable at a
///   host derivable from the app's own location, e.g.:
///   `flutter build apk --dart-define=BACKEND_ORIGIN=https://xxxx.ngrok-free.dev`
/// - Web: the backend serves the compiled web app as static files alongside
///   its API (see backend/server.js), so app and API always share an origin.
///   This mirrors the page's own URL — works unchanged whether that's
///   localhost, a LAN IP, or a public tunnel (e.g. ngrok) URL over HTTPS.
/// - Android emulator: localhost on the host machine is aliased to 10.0.2.2.
/// - Physical Android device / desktop: falls back to localhost.
String get backendOrigin {
  const override = String.fromEnvironment('BACKEND_ORIGIN');
  if (override.isNotEmpty) return override;

  if (kIsWeb) {
    final base = Uri.base;
    final port = base.hasPort ? ':${base.port}' : '';
    return '${base.scheme}://${base.host}$port';
  }
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5000';
  return 'http://localhost:5000';
}
