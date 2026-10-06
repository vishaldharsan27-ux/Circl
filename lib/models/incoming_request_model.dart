// lib/models/incoming_request_model.dart
class IncomingRequestModel {
  final String connectionId;
  final String senderId;
  final String senderName;
  final String avatarColor;
  final int age;
  final List<String> interests;
  final String bio;

  IncomingRequestModel({
    required this.connectionId,
    required this.senderId,
    required this.senderName,
    this.avatarColor = '#00E676',
    this.age = 0,
    this.interests = const [],
    this.bio = '',
  });

  factory IncomingRequestModel.fromJson(Map<String, dynamic> json) {
    return IncomingRequestModel(
      connectionId: json['connectionId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName'] ?? '',
      avatarColor: json['avatarColor'] ?? '#00E676',
      age: json['age'] is int ? json['age'] : int.tryParse('${json['age']}') ?? 0,
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : <String>[],
      bio: json['bio'] ?? '',
    );
  }
}
