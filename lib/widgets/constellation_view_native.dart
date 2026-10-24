// lib/widgets/constellation_view_native.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'constellation_common.dart';

class ConstellationView extends StatefulWidget {
  final Map<String, dynamic> payload;
  final ConstellationController controller;
  final ValueChanged<String> onNodeTap;
  final ValueChanged<String> onError;

  const ConstellationView({
    super.key,
    required this.payload,
    required this.controller,
    required this.onNodeTap,
    required this.onError,
  });

  @override
  State<ConstellationView> createState() => _ConstellationViewState();
}

class _ConstellationViewState extends State<ConstellationView> {
  WebViewController? _web;
  bool _ready = false;
  String? _lastSent;

  static bool get _supported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_recenter);

    if (!_supported) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onError('The 3D view needs Android or iOS'),
      );
      return;
    }

    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0D0D0D))
      // A non-browser user agent, so a free ngrok tunnel serves the page instead
      // of its "You are about to visit..." interstitial.
      ..setUserAgent('CirclApp/1.0')
      ..addJavaScriptChannel('CirclBridge', onMessageReceived: (m) => _handleMessage(m.message))
      ..setNavigationDelegate(NavigationDelegate(
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? true) {
            widget.onError('Could not load the 3D view (${error.description})');
          }
        },
      ))
      ..loadRequest(Uri.parse(constellationUrl));
  }

  @override
  void didUpdateWidget(covariant ConstellationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_recenter);
      widget.controller.addListener(_recenter);
    }
    _pushData();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_recenter);
    super.dispose();
  }

  void _handleMessage(String raw) {
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (msg['type']) {
      case 'ready':
        _ready = true;
        _pushData();
      case 'tap':
        widget.onNodeTap('${msg['id']}');
      case 'error':
        widget.onError('${msg['message']}');
    }
  }

  // Only re-send when the data actually changed — the home screen rebuilds on
  // every location tick, and each update rebuilds the scene's node objects.
  void _pushData() {
    if (!_ready || _web == null) return;
    final json = jsonEncode(widget.payload);
    if (json == _lastSent) return;
    _lastSent = json;
    _web!.runJavaScript('window.circl && window.circl.update($json);');
  }

  void _recenter() {
    if (_ready) _web?.runJavaScript('window.circl && window.circl.recenter();');
  }

  @override
  Widget build(BuildContext context) {
    if (_web == null) return const ColoredBox(color: Color(0xFF0D0D0D));
    return WebViewWidget(
      controller: _web!,
      // Let the scene own every gesture (orbit, pinch-zoom, tap) instead of
      // losing vertical drags to the surrounding Scaffold.
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }
}
