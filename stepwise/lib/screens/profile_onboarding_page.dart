import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ProfileOnboardingPage extends StatefulWidget {
  const ProfileOnboardingPage({super.key});

  @override
  ProfileOnboardingPageState createState() => ProfileOnboardingPageState();
}

class ProfileOnboardingPageState extends State<ProfileOnboardingPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController goalController = TextEditingController();
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  bool _loading = false;

  Future<void> _saveProfile() async {
    setState(() {
      _loading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle user not logged in
      setState(() {
        _loading = false;
      });
      return;
    }

    final profile = UserProfile(
      userId: user.uid,
      name: nameController.text,
      age: int.tryParse(ageController.text) ?? 0,
      gender: _selectedGender ?? 'Other',
      height: double.tryParse(heightController.text) ?? 0,
      weight: double.tryParse(weightController.text) ?? 0,
      dailyStepGoal: int.tryParse(goalController.text) ?? 10000,
    );

    final box = await Hive.openBox<UserProfile>('user_profiles');
    await box.put(user.uid, profile);

    setState(() {
      _loading = false;
    });

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        title: Text('Complete Your Profile', style: AppTextStyles.title(brightness).copyWith(color: Colors.white)),
        backgroundColor: AppColors.getPrimary(brightness),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: nameController,
              label: 'Full Name',
              brightness: brightness,
            ),
            const SizedBox(height: 18),
            _buildTextField(
              controller: ageController,
              label: 'Age',
              keyboardType: TextInputType.number,
              brightness: brightness,
            ),
            const SizedBox(height: 18),
            _buildDropdown(
              value: _selectedGender,
              items: _genders,
              label: 'Gender',
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
              brightness: brightness,
            ),
            const SizedBox(height: 18),
            _buildTextField(
              controller: heightController,
              label: 'Height (cm)',
              keyboardType: TextInputType.number,
              brightness: brightness,
            ),
            const SizedBox(height: 18),
            _buildTextField(
              controller: weightController,
              label: 'Weight (kg)',
              keyboardType: TextInputType.number,
              brightness: brightness,
            ),
            const SizedBox(height: 18),
            _buildTextField(
              controller: goalController,
              label: 'Daily Step Goal',
              keyboardType: TextInputType.number,
              brightness: brightness,
            ),
            const SizedBox(height: 32),
            Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimary(brightness),
                        foregroundColor: AppColors.buttonText,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('SAVE & CONTINUE', style: AppTextStyles.button(brightness)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Brightness brightness,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body(brightness)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
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
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required ValueChanged<String?> onChanged,
    required Brightness brightness,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body(brightness)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: AppTextStyles.body(brightness)),
            );
          }).toList(),
          onChanged: onChanged,
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
          dropdownColor: brightness == Brightness.light ? Colors.white : AppColors.getSecondary(brightness),
        ),
      ],
    );
  }
} 