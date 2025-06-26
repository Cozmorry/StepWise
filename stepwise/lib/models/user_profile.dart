import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  late String userId;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late int age;

  @HiveField(3)
  late String gender;

  @HiveField(4)
  late double weight; // in kg

  @HiveField(5)
  late double height; // in cm

  @HiveField(6)
  late int dailyStepGoal;

  @HiveField(7)
  late String? profilePhotoUrl;

  @HiveField(8)
  late DateTime createdAt;

  @HiveField(9)
  late DateTime updatedAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    this.dailyStepGoal = 10000,
    this.profilePhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  // Helper methods
  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  void update({
    String? name,
    int? age,
    String? gender,
    double? weight,
    double? height,
    int? dailyStepGoal,
    String? profilePhotoUrl,
  }) {
    if (name != null) this.name = name;
    if (age != null) this.age = age;
    if (gender != null) this.gender = gender;
    if (weight != null) this.weight = weight;
    if (height != null) this.height = height;
    if (dailyStepGoal != null) this.dailyStepGoal = dailyStepGoal;
    if (profilePhotoUrl != null) this.profilePhotoUrl = profilePhotoUrl;
    updatedAt = DateTime.now();
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return UserProfile(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'Other',
      weight: (map['weight'] ?? 0).toDouble(),
      height: (map['height'] ?? 0).toDouble(),
      dailyStepGoal: map['dailyStepGoal'] ?? 10000,
      profilePhotoUrl: map['profilePhotoUrl'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
} 