// lib/models/pitch_model.dart
class PitchModel {
  final String id;
  final String fromUser;
  final String toUser;
  final String text;
  final String status;

  PitchModel({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.text,
    required this.status,
  });

  factory PitchModel.fromJson(Map<String, dynamic> json) {
    final rawFromUser = json['fromUser'];
    final fromUserId = rawFromUser is Map
        ? (rawFromUser['_id']?.toString() ?? '')
        : (rawFromUser?.toString() ?? '');

    return PitchModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      fromUser: fromUserId,
      toUser: json['toUser']?.toString() ?? '',
      text: json['text'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}
