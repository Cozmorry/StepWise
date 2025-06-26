import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  String? _profileImagePath;
  String? _errorMessage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1000, maxHeight: 1000, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    print('Starting profile save');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _loading = false; _errorMessage = 'User not logged in.'; });
      print('User not logged in');
      return;
    }
    try {
      print('Saving profile to Hive and Firestore');
      final profile = UserProfile(
        userId: user.uid,
        name: nameController.text,
        age: int.tryParse(ageController.text) ?? 0,
        gender: _selectedGender ?? 'Other',
        height: double.tryParse(heightController.text) ?? 0,
        weight: double.tryParse(weightController.text) ?? 0,
        dailyStepGoal: int.tryParse(goalController.text) ?? 10000,
        profilePhotoUrl: _profileImagePath,
      );
      final box = await Hive.openBox<UserProfile>('user_profiles');
      await box.put(user.uid, profile);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'userId': profile.userId,
        'name': profile.name,
        'age': profile.age,
        'gender': profile.gender,
        'weight': profile.weight,
        'height': profile.height,
        'dailyStepGoal': profile.dailyStepGoal,
        'profilePhotoUrl': null,
        'createdAt': profile.createdAt,
        'updatedAt': profile.updatedAt,
      });
      print('Profile saved successfully');
      setState(() { _loading = false; });
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      print('Profile save error: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to save profile. Please try again.';
      });
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
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.getSecondary(brightness),
                      backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                      child: _profileImagePath == null ? Icon(Icons.person, size: 50, color: AppColors.getPrimary(brightness)) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.camera_alt, size: 20, color: AppColors.getPrimary(brightness)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.body(brightness).copyWith(color: Colors.red),
                ),
              ),
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