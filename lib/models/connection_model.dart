// lib/models/connection_model.dart
class ConnectionModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String status;

  ConnectionModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
  });

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
    };
  }
}
