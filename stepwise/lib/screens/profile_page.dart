import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool notificationsOn = true;
  late Box<UserProfile> _profileBox;

  @override
  void initState() {
    super.initState();
    _profileBox = Hive.box<UserProfile>('user_profiles');
    _loadUserProfileIfNeeded();
  }

  Future<void> _loadUserProfileIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userProfile = _profileBox.get(user.uid);
      if (userProfile == null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          userProfile = UserProfile.fromMap(doc.data()!);
          await _profileBox.put(user.uid, userProfile);
          if (mounted) setState(() {});
        }
      }
    }
  }

  void _showThemeDialog() {
    final themeNotifier = Provider.of<ThemeModeNotifier>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choose Theme', style: AppTextStyles.subheading(Theme.of(context).brightness)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('System', style: AppTextStyles.body(Theme.of(context).brightness)),
                onTap: () {
                  themeNotifier.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Light', style: AppTextStyles.body(Theme.of(context).brightness)),
                onTap: () {
                  themeNotifier.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Dark', style: AppTextStyles.body(Theme.of(context).brightness)),
                onTap: () {
                  themeNotifier.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile', style: AppTextStyles.subheading(brightness)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_4, color: AppColors.getText(brightness)),
            onPressed: _showThemeDialog,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: AppColors.getText(brightness)),
            onPressed: () async {
              // Clear persisted user ID before signing out
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('persisted_user_id');
              print('Cleared persisted user ID on logout');
              
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _profileBox.listenable(),
        builder: (context, Box<UserProfile> box, _) {
          final userProfile = box.get(user?.uid);

          if (userProfile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
            child: ListView(
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.getSecondary(brightness),
                        backgroundImage: userProfile.profilePhotoUrl != null
                            ? FileImage(File(userProfile.profilePhotoUrl!))
                            : null,
                        child: userProfile.profilePhotoUrl == null
                            ? Icon(Icons.person, size: 44, color: AppColors.getPrimary(brightness))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/edit-profile', arguments: userProfile);
                                                    },
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.edit, size: 18, color: AppColors.getPrimary(brightness)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(userProfile.name, style: AppTextStyles.subheading(brightness).copyWith(fontSize: 22)),
                ),
                const SizedBox(height: 24),
                _profileField('Gender', userProfile.gender, brightness),
                _profileField('Age', '${userProfile.age}', brightness),
                _profileField('Weight', '${userProfile.weight} kg', brightness),
                _profileField('Height', '${userProfile.height} cm', brightness),
                _profileField('Goal', '${userProfile.dailyStepGoal} steps/day', brightness),
                const SizedBox(height: 24),
                ListTile(
                  title: Text('Account Settings', style: AppTextStyles.body(brightness)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18, color: AppColors.getPrimary(brightness)),
                  onTap: () {
                    Navigator.pushNamed(context, '/edit-profile', arguments: userProfile);
                  },
                ),
                ListTile(
                  title: Text('Badges & Achievements', style: AppTextStyles.body(brightness)),
                  trailing: Icon(Icons.emoji_events, size: 20, color: AppColors.getPrimary(brightness)),
                  onTap: () {
                    Navigator.pushNamed(context, '/badges');
                  },
                ),
                ListTile(
                  title: Text('Personalized Insights', style: AppTextStyles.body(brightness)),
                  subtitle: Text('Get personalized health messages based on your profile', 
                    style: AppTextStyles.body(brightness).copyWith(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Icon(Icons.psychology, size: 20, color: AppColors.getPrimary(brightness)),
                  onTap: () {
                    Navigator.pushNamed(context, '/personalized-messages');
                  },
                ),
                Divider(color: AppColors.getBorder(brightness)),
                ListTile(
                  title: Text('Notifications', style: AppTextStyles.body(brightness)),
                  trailing: Switch(
                    value: userProfile.notificationsOn,
                    activeColor: AppColors.getPrimary(brightness),
                    onChanged: (val) async {
                      setState(() {
                        userProfile.notificationsOn = val;
                      });
                      await userProfile.save();
                      await FirebaseFirestore.instance.collection('users').doc(userProfile.userId).set({
                        'notificationsOn': val,
                      }, SetOptions(merge: true));
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileField(String label, String value, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body(brightness)),
          Text(value, style: AppTextStyles.subtitle(brightness).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
} 