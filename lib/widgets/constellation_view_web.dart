// lib/widgets/constellation_view_web.dart
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;
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
  static int _nextId = 0;

  final String _viewType = 'circl-constellation-${_nextId++}';
  final String _origin = Uri.parse(constellationUrl).origin;
  web.HTMLIFrameElement? _iframe;
  StreamSubscription<web.MessageEvent>? _messages;
  bool _ready = false;
  String? _lastSent;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_recenter);

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = web.HTMLIFrameElement()
        ..src = constellationUrl
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
      _iframe = iframe;
      return iframe;
    });

    _messages = web.window.onMessage.listen((event) {
      if (event.origin != _origin) return;
      final data = event.data?.dartify();
      if (data is! String) return;
      _handleMessage(data);
    });
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
    _messages?.cancel();
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

  void _post(Map<String, dynamic> message) {
    _iframe?.contentWindow?.postMessage(jsonEncode(message).toJS, _origin.toJS);
  }

  void _pushData() {
    if (!_ready) return;
    final json = jsonEncode(widget.payload);
    if (json == _lastSent) return;
    _lastSent = json;
    _post({'type': 'update', 'payload': widget.payload});
  }

  void _recenter() {
    if (_ready) _post({'type': 'recenter'});
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
