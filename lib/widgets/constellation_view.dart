// lib/widgets/constellation_view.dart
// 3D "living constellation" of nearby users. The scene itself is a web page
// (backend/public/constellation/index.html, three.js + 3d-force-graph) shown in
// a WebView on Android/iOS and an iframe on Flutter web; this widget feeds it
// data and relays node taps back.
export 'constellation_common.dart';
export 'constellation_view_native.dart'
    if (dart.library.js_interop) 'constellation_view_web.dart';
