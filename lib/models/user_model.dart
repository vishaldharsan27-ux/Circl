// lib/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final int age;
  final List<String> interests;
  final int matchPercent;
  final String avatarColor;
  final double distanceKm;
  final String bio;
  final List<String> relatedInterests;
  final String connectionStatus;
  final String? preference;
  final bool preferenceMatch;

  UserModel({
    required this.id,
    required this.name,
    this.email = '',
    required this.age,
    required this.interests,
    this.matchPercent = 0,
    required this.avatarColor,
    this.distanceKm = 0.0,
    this.bio = '',
    this.relatedInterests = const [],
    this.connectionStatus = 'none',
    this.preference,
    this.preferenceMatch = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] is int
          ? json['age']
          : int.tryParse('${json['age']}') ?? 0,
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : <String>[],
      matchPercent: json['matchPercent'] is int
          ? json['matchPercent']
          : int.tryParse('${json['matchPercent'] ?? 0}') ?? 0,
      avatarColor: json['avatarColor'] ?? '#00E676',
      distanceKm: json['distanceKm'] != null
          ? (json['distanceKm'] as num).toDouble()
          : 0.0,
      bio: json['bio'] ?? '',
      relatedInterests: json['relatedInterests'] != null
          ? List<String>.from(json['relatedInterests'])
          : <String>[],
      connectionStatus: json['connectionStatus'] ?? 'none',
      preference: json['preference'],
      preferenceMatch: json['preferenceMatch'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'interests': interests,
      'matchPercent': matchPercent,
      'avatarColor': avatarColor,
      'distanceKm': distanceKm,
      'bio': bio,
      'preference': preference,
    };
  }

  UserModel copyWith({
    String? name,
    String? bio,
    List<String>? interests,
    String? preference,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      age: age,
      interests: interests ?? this.interests,
      matchPercent: matchPercent,
      avatarColor: avatarColor,
      distanceKm: distanceKm,
      bio: bio ?? this.bio,
      preference: preference ?? this.preference,
    );
  }
}
