// lib/providers/projects_provider.dart
import 'package:flutter/foundation.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ProjectsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final AuthService _authService = AuthService();

  List<ProjectModel> projects = [];
  List<ProjectMemberModel> acceptedConnections = [];
  bool isLoading = false;
  String? errorMessage;

  List<CommitModel> commits = [];
  bool isLoadingCommits = false;
  String? commitsError;
  String? commitsForProjectId;

  Future<void> fetchProjects() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final token = await _authService.getToken();
    final response = await _api.get('/projects', token: token);

    isLoading = false;

    if (response['success'] == true && response['projects'] != null) {
      projects = (response['projects'] as List)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } else {
      errorMessage = response['message'] ?? 'Failed to fetch projects';
    }

    notifyListeners();
  }

  Future<void> fetchAcceptedConnections() async {
    final token = await _authService.getToken();
    final response = await _api.get('/users/connections/accepted', token: token);

    if (response['success'] == true && response['connections'] != null) {
      acceptedConnections = (response['connections'] as List)
          .map((json) => ProjectMemberModel.fromJson(json))
          .toList();
      notifyListeners();
    }
  }

  Future<bool> createProject(String name, List<String> memberIds, {String? repoUrl}) async {
    final token = await _authService.getToken();
    final response = await _api.post(
      '/projects',
      {
        'name': name,
        'memberIds': memberIds,
        if (repoUrl != null && repoUrl.isNotEmpty) 'repoUrl': repoUrl,
      },
      token: token,
    );

    if (response['success'] == true && response['project'] != null) {
      projects = [ProjectModel.fromJson(response['project']), ...projects];
      notifyListeners();
      return true;
    }

    errorMessage = response['message'] ?? 'Failed to create project';
    notifyListeners();
    return false;
  }

  Future<bool> updateProject(
    String projectId, {
    String? name,
    List<String>? memberIds,
    String? repoUrl,
  }) async {
    final token = await _authService.getToken();
    final response = await _api.put(
      '/projects/$projectId',
      {
        if (name != null) 'name': name,
        if (memberIds != null) 'memberIds': memberIds,
        if (repoUrl != null) 'repoUrl': repoUrl,
      },
      token: token,
    );

    if (response['success'] == true && response['project'] != null) {
      final updated = ProjectModel.fromJson(response['project']);
      projects = projects.map((p) => p.id == projectId ? updated : p).toList();
      notifyListeners();
      return true;
    }

    errorMessage = response['message'] ?? 'Failed to update project';
    notifyListeners();
    return false;
  }

  Future<void> fetchCommits(String projectId) async {
    isLoadingCommits = true;
    commitsError = null;
    commitsForProjectId = projectId;
    notifyListeners();

    final token = await _authService.getToken();
    final response = await _api.get('/projects/$projectId/commits', token: token);

    isLoadingCommits = false;

    if (response['success'] == true && response['commits'] != null) {
      commits = (response['commits'] as List)
          .map((json) => CommitModel.fromJson(json))
          .toList();
    } else {
      commits = [];
      commitsError = response['message'] ?? 'Failed to fetch commits';
    }

    notifyListeners();
  }

  Future<bool> deleteProject(String projectId) async {
    final token = await _authService.getToken();
    final response = await _api.delete('/projects/$projectId', token: token);

    if (response['success'] == true) {
      projects = projects.where((p) => p.id != projectId).toList();
      notifyListeners();
      return true;
    }

    return false;
  }
}
