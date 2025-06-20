import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 3;
  bool notificationsOn = true;

  // Placeholder user data
  final String userName = 'Ivy Waringa';
  final String gender = 'Female';
  final String age = '23';
  final String weight = '65 kg';
  final String height = "5'3\"";
  final String goal = '2000 steps/day';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile', style: AppTextStyles.subheading),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: AppColors.primary),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.secondary,
                    backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/44.jpg'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 18, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(userName, style: AppTextStyles.subheading.copyWith(fontSize: 22)),
            ),
            const SizedBox(height: 24),
            _profileField('Gender', gender),
            _profileField('Age', age),
            _profileField('Weight', weight),
            _profileField('Height', height),
            _profileField('Goal', goal),
            const SizedBox(height: 24),
            ListTile(
              title: Text('Account Settings', style: AppTextStyles.body),
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: AppColors.primary),
              onTap: () {},
            ),
            Divider(color: AppColors.border),
            ListTile(
              title: Text('Turn off Notifications', style: AppTextStyles.body),
              trailing: Switch(
                value: notificationsOn,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => notificationsOn = val);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/activity-log');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/health-tips');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
} 