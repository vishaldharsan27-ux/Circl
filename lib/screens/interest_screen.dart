// lib/screens/interest_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

class InterestScreen extends StatefulWidget {
  const InterestScreen({super.key});

  @override
  State<InterestScreen> createState() => _InterestScreenState();
}

class _InterestScreenState extends State<InterestScreen> {
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

  final Set<String> _selectedInterests = {};
  String? _selectedPreference;
  bool _isSubmitting = false;
  String? _errorText;

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  Future<void> _handleFindPeople() async {
    if (_selectedInterests.length < 3) {
      setState(() => _errorText = 'Select at least 3 interests');
      return;
    }

    if (_selectedPreference == null) {
      setState(() => _errorText = 'Select what you\'re looking for');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final usersProvider = Provider.of<UsersProvider>(context, listen: false);
    final updated = await usersProvider.updateInterests(
      _selectedInterests.toList(),
      preference: _selectedPreference,
    );

    if (!updated) {
      setState(() {
        _isSubmitting = false;
        _errorText = 'Could not save interests, please try again';
      });
      return;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        }
      }
    } catch (_) {
      // Non-blocking: HomeScreen will attempt to acquire location again.
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'What are you into?',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select at least 3 interests',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textMuted(context),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: _allInterests.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.6,
                  ),
                  itemBuilder: (context, index) {
                    final interest = _allInterests[index];
                    final isSelected = _selectedInterests.contains(interest);
                    return GestureDetector(
                      onTap: () => _toggleInterest(interest),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00E676)
                              : AppColors.card(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00E676)
                                : AppColors.divider(context),
                          ),
                        ),
                        child: Text(
                          interest,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.black : AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "What are you looking for?",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _preferences.map((preference) {
                  final isSelected = _selectedPreference == preference;
                  return ChoiceChip(
                    label: Text(preference),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedPreference = preference),
                    selectedColor: const Color(0xFF00E676),
                    backgroundColor: AppColors.card(context),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AppColors.textPrimary(context),
                    ),
                  );
                }).toList(),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleFindPeople,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Find People Nearby →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
