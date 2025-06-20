import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _passwordError = '';
  String _confirmPasswordError = '';

  void _validatePassword(String value) {
    String error = '';
    if (value.length < 8) error = 'Min 8 characters. ';
    if (!RegExp(r'[A-Z]').hasMatch(value)) error += 'Uppercase required. ';
    if (!RegExp(r'[0-9]').hasMatch(value)) error += 'Number required. ';
    setState(() { _passwordError = error.trim(); });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      _confirmPasswordError = value != passwordController.text ? 'Passwords do not match.' : '';
    });
  }

  Future<void> _registerWithEmail() async {
    setState(() { _loading = true; _error = null; });
    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final confirmPassword = confirmPasswordController.text.trim();
      if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        setState(() { _error = 'All fields are required.'; _loading = false; });
        return;
      }
      if (_passwordError.isNotEmpty || _confirmPasswordError.isNotEmpty) {
        setState(() { _error = 'Please fix password errors.'; _loading = false; });
        return;
      }
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        _showAdditionalInfoDialog();
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.directions_walk, size: 32, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('STEPWISE', style: AppTextStyles.heading),
                ],
              ),
              const SizedBox(height: 32),
              _label('Full Name'),
              _textField(nameController),
              const SizedBox(height: 14),
              _label('Email'),
              _textField(emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _label('Password'),
              _passwordField(passwordController, _showPassword, (v) => setState(() => _showPassword = v), _validatePassword),
              if (_passwordError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 2),
                  child: Text(_passwordError, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              const SizedBox(height: 14),
              _label('Confirm Password'),
              _passwordField(confirmPasswordController, _showConfirmPassword, (v) => setState(() => _showConfirmPassword = v), _validateConfirmPassword),
              if (_confirmPasswordError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 2),
                  child: Text(_confirmPasswordError, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              const SizedBox(height: 28),
              if (_error != null) ...[
                Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 12),
              ],
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Center(
                  child: SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.buttonText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _registerWithEmail,
                      child: Text('REGISTER', style: AppTextStyles.button),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: SizedBox(
                          width: 220,
                          child: _customGoogleButton(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: AppTextStyles.body),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Text('Login', style: AppTextStyles.link),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 4),
        child: Text(text, style: AppTextStyles.body),
      );

  Widget _textField(TextEditingController controller,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    bool show,
    ValueChanged<bool> onShowChanged,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      controller: controller,
      obscureText: !show,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility : Icons.visibility_off),
          onPressed: () => onShowChanged(!show),
        ),
      ),
    );
  }

  Widget _customGoogleButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Color(0xFFDD4B39)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Image.asset('assets/google_logo.png', height: 22),
      label: const Text('Sign up with Google', style: TextStyle(fontWeight: FontWeight.w600)),
      onPressed: _signInWithGoogle,
    );
  }

  Future<void> _signInWithGoogle() async {
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
        _showAdditionalInfoDialog();
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }
} 