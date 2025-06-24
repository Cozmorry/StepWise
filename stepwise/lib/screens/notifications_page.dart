import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

enum NotificationType { achievement, tip, general }

class NotificationItem {
  final String id;
  final String text;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.text,
    required this.timestamp,
    this.type = NotificationType.general,
    this.isRead = false,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  int _currentIndex = 0;
  final List<NotificationItem> _notifications = [
    NotificationItem(id: '1', text: 'Congratulations! You hit your 10,000-step goal yesterday!', timestamp: DateTime.now().subtract(const Duration(hours: 18)), type: NotificationType.achievement),
    NotificationItem(id: '2', text: 'You have a new health tip: "The Importance of a Cool-Down Routine".', timestamp: DateTime.now().subtract(const Duration(days: 1)), type: NotificationType.tip, isRead: true),
    NotificationItem(id: '3', text: 'Your weekly summary is ready. You walked an average of 8,500 steps last week!', timestamp: DateTime.now().subtract(const Duration(days: 2)), isRead: true),
    NotificationItem(id: '4', text: 'You achieved a 3-day streak! Keep the momentum going.', timestamp: DateTime.now().subtract(const Duration(days: 3)), type: NotificationType.achievement),
    NotificationItem(id: '5', text: 'Remember to sync your activity data before the end of the day.', timestamp: DateTime.now().subtract(const Duration(hours: 2)), isRead: false)
  ];

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

  void _markAsRead(String id) {
    setState(() {
      _notifications.firstWhere((n) => n.id == id).isRead = true;
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 24) {
      return '1d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.tip:
        return Icons.lightbulb_outline;
      case NotificationType.general:
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(brightness),
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.title(brightness)),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Clear All',
                style: AppTextStyles.button(brightness).copyWith(color: AppColors.getPrimary(brightness)),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState(brightness)
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildSlidableNotification(notification, brightness);
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

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.getSecondary(brightness)),
          const SizedBox(height: 20),
          Text(
            'All Caught Up!',
            style: AppTextStyles.heading(brightness),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no new notifications.',
            style: AppTextStyles.subtitle(brightness),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSlidableNotification(NotificationItem notification, Brightness brightness) {
    final primaryColor = AppColors.getPrimary(brightness);
    final backgroundColor = notification.isRead ? AppColors.getBackground(brightness) : AppColors.getSecondary(brightness);

    return Slidable(
      key: Key(notification.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _deleteNotification(notification.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _markAsRead(notification.id),
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: notification.isRead ? AppColors.getBorder(brightness) : primaryColor,
              width: notification.isRead ? 0.5 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_getIconForType(notification.type), color: primaryColor, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.text, style: AppTextStyles.body(brightness)),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: AppTextStyles.subtitle(brightness).copyWith(color: AppColors.getPrimary(brightness)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleDailyReminder({
    int hour = 20,
    int minute = 0,
    String title = 'StepWise Reminder',
    String body = 'Don\'t forget to check your daily step progress!',
    int id = 0,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Daily Reminders',
          channelDescription: 'Daily reminder to check your steps',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleDailySummary({
    int hour = 21,
    int minute = 0,
    required int steps,
    required double distanceKm,
    int id = 1,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      'StepWise Daily Summary',
      'You walked $steps steps today (${distanceKm.toStringAsFixed(2)} km)!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'summary_channel',
          'Daily Summaries',
          channelDescription: 'Daily summary of your steps',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
} 