import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isDenied && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text('Notification permission is required to receive updates.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // Placeholder notifications
  final List<Map<String, String>> notifications = [
    {
      'text': 'Missed Goal: You walked 5200 steps on 22/5. Keep pushing!',
      'time': '2 hours',
      'highlight': 'true',
    },
    {
      'text': 'New Activity Update! View your latest progress suggestions.',
      'time': '4 hours',
      'highlight': 'true',
    },
    {
      'text': 'Your weekly summary is ready. Check your progress now.',
      'time': '20/4',
      'highlight': 'false',
    },
    {
      'text': 'It\'s almost 8 pm. A short evening walk could help you reach your goal.',
      'time': '19/4',
      'highlight': 'false',
    },
    {
      'text': 'Your profile has been updated successfully',
      'time': '18/4',
      'highlight': 'false',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.subheading),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Mark all as read', style: AppTextStyles.body.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final n = notifications[i];
          final highlight = n['highlight'] == 'true';
          return Container(
            decoration: BoxDecoration(
              color: highlight ? AppColors.secondary : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(n['text']!, style: AppTextStyles.body)),
                const SizedBox(width: 8),
                Text(n['time']!, style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
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
} 