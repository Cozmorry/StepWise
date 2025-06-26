import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfilePage({super.key, required this.userProfile});

  @override
  EditProfilePageState createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  late TextEditingController goalController;
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  bool _loading = false;
  String? _profileImagePath;
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  double? _currentBmi;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userProfile.name);
    ageController = TextEditingController(text: widget.userProfile.age.toString());
    heightController = TextEditingController(text: widget.userProfile.height.toString());
    weightController = TextEditingController(text: widget.userProfile.weight.toString());
    goalController = TextEditingController(text: widget.userProfile.dailyStepGoal.toString());
    _selectedGender = widget.userProfile.gender;
    _profileImagePath = widget.userProfile.profilePhotoUrl;
    _updateBmi();
  }

  void _updateBmi() {
    final weight = double.tryParse(weightController.text);
    final height = double.tryParse(heightController.text);
    if (weight != null && height != null && height > 0) {
      setState(() {
        _currentBmi = weight / ((height / 100) * (height / 100));
      });
    } else {
      setState(() {
        _currentBmi = null;
      });
    }
  }

  String? _validateNumber(String? value, String fieldName, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    if (max != null && number > max) {
      return '$fieldName cannot exceed $max';
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
        final savedImage = await File(pickedFile.path).copy('${directory.path}/$fileName');
        setState(() {
          _profileImagePath = savedImage.path;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    print('Starting profile save');
    try {
      print('Saving profile to Hive and Firestore');
      widget.userProfile.update(
        name: nameController.text,
        age: int.parse(ageController.text),
        gender: _selectedGender,
        height: double.parse(heightController.text),
        weight: double.parse(weightController.text),
        dailyStepGoal: int.parse(goalController.text),
        profilePhotoUrl: _profileImagePath,
      );
      await widget.userProfile.save();
      await FirebaseFirestore.instance.collection('users').doc(widget.userProfile.userId).set({
        'userId': widget.userProfile.userId,
        'name': widget.userProfile.name,
        'age': widget.userProfile.age,
        'gender': widget.userProfile.gender,
        'weight': widget.userProfile.weight,
        'height': widget.userProfile.height,
        'dailyStepGoal': widget.userProfile.dailyStepGoal,
        'profilePhotoUrl': null,
        'createdAt': widget.userProfile.createdAt,
        'updatedAt': widget.userProfile.updatedAt,
        'achievements': widget.userProfile.achievements.map((k, v) => MapEntry(k, v.toIso8601String())),
        'notificationsOn': widget.userProfile.notificationsOn,
      });
      print('Profile saved successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Profile save error: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to save profile. Please try again.';
      });
    } finally {
      if (mounted && _loading) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        title: Text('Edit Profile', style: AppTextStyles.title(brightness).copyWith(color: Colors.white)),
        backgroundColor: AppColors.getPrimary(brightness),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.body(brightness).copyWith(color: Colors.red),
                  ),
                ),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.getSecondary(brightness),
                        backgroundImage: _profileImagePath != null
                            ? FileImage(File(_profileImagePath!))
                            : null,
                        child: _profileImagePath == null
                            ? Icon(Icons.person, size: 50, color: AppColors.getPrimary(brightness))
                            : null,
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
              const SizedBox(height: 24),
              _buildTextField(
                controller: nameController,
                label: 'Full Name',
                brightness: brightness,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _buildTextField(
                controller: ageController,
                label: 'Age',
                keyboardType: TextInputType.number,
                brightness: brightness,
                validator: (value) => _validateNumber(value, 'Age', min: 1, max: 120),
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
                validator: (value) => _validateNumber(value, 'Height', min: 50, max: 300),
                onChanged: (value) => _updateBmi(),
              ),
              const SizedBox(height: 18),
              _buildTextField(
                controller: weightController,
                label: 'Weight (kg)',
                keyboardType: TextInputType.number,
                brightness: brightness,
                validator: (value) => _validateNumber(value, 'Weight', min: 20, max: 500),
                onChanged: (value) => _updateBmi(),
              ),
              if (_currentBmi != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Current BMI: ${_currentBmi!.toStringAsFixed(1)} (${_getBmiCategory(_currentBmi!)})',
                    style: AppTextStyles.body(brightness).copyWith(
                      color: _getBmiColor(_currentBmi!, brightness),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              _buildTextField(
                controller: goalController,
                label: 'Daily Step Goal',
                keyboardType: TextInputType.number,
                brightness: brightness,
                validator: (value) => _validateNumber(value, 'Daily step goal', min: 1000, max: 100000),
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
                        child: Text('SAVE CHANGES', style: AppTextStyles.button(brightness)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBmiColor(double bmi, Brightness brightness) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Brightness brightness,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body(brightness)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a gender';
            }
            return null;
          },
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    goalController.dispose();
    super.dispose();
  }
} 