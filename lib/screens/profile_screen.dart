// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import 'register_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> _allInterests = [
    'Gen AI',
    'LLM',
    'SLM',
    'Agentic AI',
    'RAG',
    'LangChain',
    'Machine Learning',
    'Deep Learning',
    'Computer Vision',
    'MLOps',
    'Data Engineering',
    'Cloud/DevOps',
  ];

  static const List<String> _preferences = ['Build', 'Learn', 'Mentor', 'Hire'];

  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  Set<String> _editedInterests = {};
  String? _editedPreference;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _editedInterests = Set.from(user?.interests ?? []);
    _editedPreference = user?.preference;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_editedInterests.contains(interest)) {
        _editedInterests.remove(interest);
      } else {
        _editedInterests.add(interest);
      }
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final usersProvider = Provider.of<UsersProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await usersProvider.updateProfile(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      interests: _editedInterests.toList(),
      preference: _editedPreference,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success && authProvider.currentUser != null) {
      authProvider.updateCurrentUser(
        authProvider.currentUser!.copyWith(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          interests: _editedInterests.toList(),
          preference: _editedPreference,
        ),
      );
      setState(() => _isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
      (route) => false,
    );
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: user == null
          ? Center(
              child: Text('No profile data', style: TextStyle(color: AppColors.textMuted(context))),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: _parseColor(user.avatarColor),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isEditing) ...[
                    _buildField(_nameController, 'Name'),
                    const SizedBox(height: 12),
                    _buildField(_bioController, 'Bio', maxLines: 3),
                    const SizedBox(height: 16),
                    Text('Interests', style: GoogleFonts.poppins(color: AppColors.textSecondary(context))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allInterests.map((interest) {
                        final isSelected = _editedInterests.contains(interest);
                        return ChoiceChip(
                          label: Text(interest),
                          selected: isSelected,
                          onSelected: (_) => _toggleInterest(interest),
                          selectedColor: const Color(0xFF00E676),
                          backgroundColor: AppColors.card(context),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : AppColors.textPrimary(context),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Looking for', style: GoogleFonts.poppins(color: AppColors.textSecondary(context))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _preferences.map((preference) {
                        final isSelected = _editedPreference == preference;
                        return ChoiceChip(
                          label: Text(preference),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _editedPreference = preference),
                          selectedColor: const Color(0xFF00E676),
                          backgroundColor: AppColors.card(context),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : AppColors.textPrimary(context),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Text(
                        '${user.name}, ${user.age}',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        user.bio.isNotEmpty ? user.bio : 'No bio yet',
                        style: GoogleFonts.poppins(color: AppColors.textMuted(context)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Interests', style: GoogleFonts.poppins(color: AppColors.textSecondary(context))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.interests.map((interest) {
                        return Chip(
                          label: Text(interest),
                          backgroundColor: AppColors.card(context),
                          labelStyle: const TextStyle(color: Color(0xFF00E676)),
                          side: const BorderSide(color: Color(0xFF00E676)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text('Looking for', style: GoogleFonts.poppins(color: AppColors.textSecondary(context))),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(user.preference ?? 'Not set'),
                      backgroundColor: AppColors.card(context),
                      labelStyle: const TextStyle(color: Color(0xFF00E676)),
                      side: const BorderSide(color: Color(0xFF00E676)),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _isEditing = true),
                        child: const Text('Edit Profile'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Divider(color: AppColors.divider(context)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Dark Mode',
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      themeProvider.isDark ? 'On' : 'Off',
                      style: GoogleFonts.poppins(color: AppColors.textMuted(context), fontSize: 12),
                    ),
                    value: themeProvider.isDark,
                    activeThumbColor: const Color(0xFF00E676),
                    onChanged: (_) => themeProvider.toggle(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.card(context),
                        foregroundColor: Colors.redAccent,
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.textPrimary(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted(context)),
      ),
    );
  }
}
