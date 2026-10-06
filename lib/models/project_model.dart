// lib/models/project_model.dart
class ProjectMemberModel {
  final String id;
  final String name;
  final String avatarColor;

  ProjectMemberModel({
    required this.id,
    required this.name,
    required this.avatarColor,
  });

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    return ProjectMemberModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      avatarColor: json['avatarColor'] ?? '#00E676',
    );
  }
}

class ProjectModel {
  final String id;
  final String name;
  final List<ProjectMemberModel> members;
  final String? repoUrl;

  ProjectModel({
    required this.id,
    required this.name,
    required this.members,
    this.repoUrl,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      members: json['members'] != null
          ? (json['members'] as List)
              .map((m) => ProjectMemberModel.fromJson(m))
              .toList()
          : <ProjectMemberModel>[],
      repoUrl: json['repoUrl'],
    );
  }
}

class CommitModel {
  final String sha;
  final String message;
  final String authorName;
  final String? authorLogin;
  final String? authorAvatarUrl;
  final String? date;
  final String url;

  CommitModel({
    required this.sha,
    required this.message,
    required this.authorName,
    this.authorLogin,
    this.authorAvatarUrl,
    this.date,
    required this.url,
  });

  factory CommitModel.fromJson(Map<String, dynamic> json) {
    return CommitModel(
      sha: json['sha'] ?? '',
      message: json['message'] ?? '',
      authorName: json['authorName'] ?? 'Unknown',
      authorLogin: json['authorLogin'],
      authorAvatarUrl: json['authorAvatarUrl'],
      date: json['date'],
      url: json['url'] ?? '',
    );
  }
}
