// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'interest_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();

  bool _isLoginMode = false;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _errorText = 'Please enable location services');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _errorText = 'Location permission is required');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _errorText = 'Location permission permanently denied');
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final position = await _getCurrentPosition();
    if (position == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      age: int.parse(_ageController.text.trim()),
      interests: const [],
      lat: position.latitude,
      lng: position.longitude,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InterestScreen()),
      );
    } else {
      setState(() => _errorText = authProvider.errorMessage ?? 'Registration failed');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _errorText = authProvider.errorMessage ?? 'Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Circl',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00E676),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode ? 'Welcome back' : 'Create your account',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 32),
                if (!_isLoginMode) ...[
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                if (!_isLoginMode) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ageController,
                    label: 'Age',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Age is required';
                      }
                      final age = int.tryParse(value.trim());
                      if (age == null || age < 13 || age > 120) {
                        return 'Enter a valid age';
                      }
                      return null;
                    },
                  ),
                ],
                if (_errorText != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : (_isLoginMode ? _handleLogin : _handleNext),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(_isLoginMode ? 'Login' : 'Next →'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _isLoginMode = !_isLoginMode;
                              _errorText = null;
                            });
                          },
                    child: Text(
                      _isLoginMode
                          ? "Don't have an account? Register"
                          : 'Already have account? Login',
                      style: const TextStyle(color: Color(0xFF00E676)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.textPrimary(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted(context)),
      ),
      validator: validator,
    );
  }
}
