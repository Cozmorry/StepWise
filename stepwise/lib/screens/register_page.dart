import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;
      final confirmPassword = confirmPasswordController.text;

      if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        setState(() {
          _error = 'All fields are required.';
          _loading = false;
        });
        return;
      }

      if (password != confirmPassword) {
        setState(() {
          _error = 'Passwords do not match.';
          _loading = false;
        });
        return;
      }

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/profile-onboarding');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showAdditionalInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final TextEditingController ageController = TextEditingController();
        final TextEditingController heightController = TextEditingController();
        final TextEditingController weightController = TextEditingController();
        final TextEditingController goalController = TextEditingController();
        String? selectedGender;
        final List<String> genders = ['Male', 'Female', 'Other'];
        return AlertDialog(
          title: const Text('Tell us more about you'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  items: genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => selectedGender = val,
                  decoration: const InputDecoration(labelText: 'Gender'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(labelText: 'Height (cm)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: goalController,
                  decoration: const InputDecoration(labelText: 'Goal steps per day'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.getPrimary(brightness).withOpacity(0.08), AppColors.getSecondary(brightness).withOpacity(0.12)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.directions_walk, size: 56, color: AppColors.getPrimary(brightness)),
                  const SizedBox(height: 16),
                  Text('STEPWISE', style: AppTextStyles.heading(brightness).copyWith(fontSize: 32, letterSpacing: 2)),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Email', style: AppTextStyles.body(brightness)),
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    brightness: brightness,
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Password', style: AppTextStyles.body(brightness)),
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: passwordController,
                    obscureText: true,
                    brightness: brightness,
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Confirm Password', style: AppTextStyles.body(brightness)),
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    brightness: brightness,
                  ),
                  const SizedBox(height: 32),
                  if (_error != null) ...[
                    Center(
                      child: Text(
                        _error!,
                        style: AppTextStyles.body(brightness).copyWith(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimary(brightness),
                          foregroundColor: AppColors.buttonText,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        onPressed: _register,
                        child: Text('REGISTER', style: AppTextStyles.button(brightness).copyWith(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppColors.getBorder(brightness)),
                          ),
                        ),
                        icon: Image.asset(
                          'assets/google_logo.png',
                          height: 24,
                        ),
                        label: Text('Sign up with Google',
                            style: AppTextStyles.button(brightness).copyWith(
                              color: Colors.black87,
                              fontSize: 16,
                            )),
                        onPressed: _signUpWithGoogle,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: AppTextStyles.body(brightness)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text('Login', style: AppTextStyles.link(brightness)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required Brightness brightness,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: brightness == Brightness.light ? Colors.white : AppColors.getSecondary(brightness),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.getBorder(brightness)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.getBorder(brightness)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.getPrimary(brightness), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      style: AppTextStyles.body(brightness).copyWith(color: AppColors.getText(brightness)),
    );
  }

  Future<void> _signUpWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() { _loading = false; });
        return; // User cancelled
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        // Always go to onboarding after Google sign-up
        Navigator.pushReplacementNamed(context, '/profile-onboarding');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to sign up with Google. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }
} 