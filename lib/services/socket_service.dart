// lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'network_config.dart';

class SocketService {
  socket_io.Socket? _socket;

  static String get socketUrl => backendOrigin;

  void connect(String userId) {
    _socket = socket_io.io(
      socketUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('join', userId);
    });
  }

  void listenForConnectionRequests(Function(dynamic data) callback) {
    _socket?.on('connection_request', (data) {
      callback(data);
    });
  }

  void listenForConnectionAccepted(Function(dynamic data) callback) {
    _socket?.on('connection_accepted', (data) {
      callback(data);
    });
  }

  void sendConnectionRequest(String receiverId) {
    _socket?.emit('connect_request', {'receiverId': receiverId});
  }

  void listenForPitchReceived(Function(dynamic data) callback) {
    _socket?.on('pitch_received', (data) => callback(data));
  }

  void listenForPitchResponded(Function(dynamic data) callback) {
    _socket?.on('pitch_responded', (data) => callback(data));
  }

  void listenForPitchMatched(Function(dynamic data) callback) {
    _socket?.on('pitch_matched', (data) => callback(data));
  }

  void listenForMeetLinkShared(Function(dynamic data) callback) {
    _socket?.on('meet_link_shared', (data) => callback(data));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
