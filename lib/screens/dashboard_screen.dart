// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/project_model.dart';
import '../providers/projects_provider.dart';
import '../theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProjectsProvider>(context, listen: false);
    provider.fetchProjects();
    provider.fetchAcceptedConnections();
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  Future<void> _showCreateProjectDialog() async {
    final provider = Provider.of<ProjectsProvider>(context, listen: false);
    final nameController = TextEditingController();
    final selected = <String>{};

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card(context),
              title: Text('New Project', style: GoogleFonts.poppins(color: AppColors.textPrimary(context))),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: TextStyle(color: AppColors.textPrimary(context)),
                      decoration: const InputDecoration(hintText: 'Project name'),
                    ),
                    const SizedBox(height: 16),
                    Text('Add people', style: GoogleFonts.poppins(color: AppColors.textSecondary(context))),
                    const SizedBox(height: 8),
                    if (provider.acceptedConnections.isEmpty)
                      Text(
                        'No accepted connections yet',
                        style: GoogleFonts.poppins(color: AppColors.textFaint(context), fontSize: 13),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: ListView(
                          shrinkWrap: true,
                          children: provider.acceptedConnections.map((member) {
                            final isSelected = selected.contains(member.id);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (_) {
                                setDialogState(() {
                                  if (isSelected) {
                                    selected.remove(member.id);
                                  } else {
                                    selected.add(member.id);
                                  }
                                });
                              },
                              activeColor: const Color(0xFF00E676),
                              title: Text(member.name, style: TextStyle(color: AppColors.textPrimary(context))),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final success = await provider.createProject(
                      nameController.text.trim(),
                      selected.toList(),
                    );
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop(success);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true && mounted && provider.projects.isNotEmpty) {
      setState(() => _selectedProjectId = provider.projects.first.id);
    }
  }

  Future<void> _showManageMembersSheet(ProjectModel project) async {
    final provider = Provider.of<ProjectsProvider>(context, listen: false);
    final selected = Set<String>.from(project.members.map((m) => m.id));

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage members',
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (provider.acceptedConnections.isEmpty)
                    Text(
                      'No accepted connections yet',
                      style: GoogleFonts.poppins(color: AppColors.textFaint(context)),
                    )
                  else
                    ...provider.acceptedConnections.map((member) {
                      final isSelected = selected.contains(member.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) {
                          setSheetState(() {
                            if (isSelected) {
                              selected.remove(member.id);
                            } else {
                              selected.add(member.id);
                            }
                          });
                        },
                        activeColor: const Color(0xFF00E676),
                        title: Text(member.name, style: TextStyle(color: AppColors.textPrimary(context))),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await provider.updateProject(project.id, memberIds: selected.toList());
                        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRenameDialog(ProjectModel project) async {
    final provider = Provider.of<ProjectsProvider>(context, listen: false);
    final controller = TextEditingController(text: project.name);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card(dialogContext),
          title: Text('Rename Project', style: GoogleFonts.poppins(color: AppColors.textPrimary(dialogContext))),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimary(dialogContext)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                await provider.updateProject(project.id, name: controller.text.trim());
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDelete(ProjectModel project) async {
    final provider = Provider.of<ProjectsProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card(dialogContext),
        title: Text('Delete "${project.name}"?', style: GoogleFonts.poppins(color: AppColors.textPrimary(dialogContext))),
        content: Text(
          'This only removes the project grouping, not your connections.',
          style: GoogleFonts.poppins(color: AppColors.textMuted(dialogContext)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteProject(project.id);
      if (mounted && _selectedProjectId == project.id) {
        setState(() => _selectedProjectId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<ProjectsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.projects.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            );
          }

          ProjectModel? selectedProject;
          for (final p in provider.projects) {
            if (p.id == _selectedProjectId) selectedProject = p;
          }
          if (selectedProject == null && provider.projects.isNotEmpty && _selectedProjectId == null) {
            selectedProject = provider.projects.first;
          }

          return Row(
            children: [
              _buildSidebar(provider, selectedProject),
              VerticalDivider(width: 1, color: AppColors.divider(context)),
              Expanded(
                child: selectedProject == null
                    ? _buildEmptyState()
                    : _buildProjectDetail(selectedProject),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(ProjectsProvider provider, ProjectModel? selectedProject) {
    return Container(
      width: 130,
      color: AppColors.card(context),
      child: Column(
        children: [
          const SizedBox(height: 12),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF00E676)),
            tooltip: 'New Project',
            onPressed: _showCreateProjectDialog,
          ),
          Divider(color: AppColors.divider(context), height: 1),
          Expanded(
            child: provider.projects.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'No projects yet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: AppColors.textFaint(context), fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.projects.length,
                    itemBuilder: (context, index) {
                      final project = provider.projects[index];
                      final isSelected = selectedProject?.id == project.id;
                      return InkWell(
                        onTap: () => setState(() => _selectedProjectId = project.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00E676).withValues(alpha: 0.12)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? const Color(0xFF00E676) : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: isSelected ? const Color(0xFF00E676) : AppColors.textPrimary(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${project.members.length} member${project.members.length == 1 ? '' : 's'}',
                                style: GoogleFonts.poppins(color: AppColors.textFaint(context), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No project selected',
              style: GoogleFonts.poppins(color: AppColors.textMuted(context), fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a project and pick which of your connections are working on it with you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.textFaint(context), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showCreateProjectDialog,
              child: const Text('New Project'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLinkRepoDialog(ProjectModel project) async {
    final provider = Provider.of<ProjectsProvider>(context, listen: false);
    final controller = TextEditingController(text: project.repoUrl ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card(dialogContext),
          title: Text('Link GitHub Repo', style: GoogleFonts.poppins(color: AppColors.textPrimary(dialogContext))),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimary(dialogContext)),
            decoration: const InputDecoration(hintText: 'https://github.com/owner/repo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await provider.updateProject(
                  project.id,
                  repoUrl: controller.text.trim(),
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.errorMessage ?? 'Could not link repo')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _relativeTime(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final diff = DateTime.now().toUtc().difference(date.toUtc());
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Widget _buildProjectDetail(ProjectModel project) {
    return Consumer<ProjectsProvider>(
      builder: (context, provider, _) {
        final showingCommitsForThis = provider.commitsForProjectId == project.id;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: AppColors.textMuted(context), size: 20),
                    onPressed: () => _showRenameDialog(project),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => _handleDelete(project),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Members', style: GoogleFonts.poppins(color: AppColors.textSecondary(context), fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              project.members.isEmpty
                  ? Text('No one added yet', style: GoogleFonts.poppins(color: AppColors.textFaint(context)))
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: project.members.map((member) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: _parseColor(member.avatarColor),
                                child: Text(
                                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                member.name,
                                style: GoogleFonts.poppins(color: AppColors.textPrimary(context), fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showManageMembersSheet(project),
                  child: const Text('Manage Members'),
                ),
              ),
              const SizedBox(height: 28),
              Divider(color: AppColors.divider(context)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Repository',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary(context), fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showLinkRepoDialog(project),
                    child: Text(project.repoUrl == null ? 'Link Repo' : 'Change'),
                  ),
                ],
              ),
              if (project.repoUrl == null)
                Text(
                  'No repo linked yet',
                  style: GoogleFonts.poppins(color: AppColors.textFaint(context), fontSize: 13),
                )
              else ...[
                Text(
                  project.repoUrl!,
                  style: GoogleFonts.poppins(color: const Color(0xFF00E676), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  "Shows pushes only — git has no way to report pulls",
                  style: GoogleFonts.poppins(color: AppColors.textFaint(context), fontSize: 11),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: provider.isLoadingCommits
                        ? null
                        : () => provider.fetchCommits(project.id),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(provider.isLoadingCommits ? 'Refreshing...' : 'Refresh Commits'),
                  ),
                ),
                const SizedBox(height: 16),
                if (showingCommitsForThis) ...[
                  if (provider.commitsError != null)
                    Text(provider.commitsError!, style: const TextStyle(color: Colors.redAccent))
                  else if (provider.commits.isEmpty && !provider.isLoadingCommits)
                    Text('No commits found', style: GoogleFonts.poppins(color: AppColors.textFaint(context)))
                  else
                    ...provider.commits.map((commit) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF00E676),
                              backgroundImage: commit.authorAvatarUrl != null
                                  ? NetworkImage(commit.authorAvatarUrl!)
                                  : null,
                              child: commit.authorAvatarUrl == null
                                  ? const Icon(Icons.person, size: 16, color: Colors.black)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    commit.message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(color: AppColors.textPrimary(context), fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${commit.authorName} · ${commit.sha} · ${_relativeTime(commit.date)}',
                                    style: GoogleFonts.poppins(color: AppColors.textFaint(context), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
