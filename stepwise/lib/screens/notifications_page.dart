import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:hive/hive.dart';

enum NotificationType { achievement, tip, general }

class NotificationItem extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String text;
  @HiveField(2)
  final DateTime timestamp;
  @HiveField(3)
  final NotificationType type;
  @HiveField(4)
  bool isRead;

  NotificationItem({
    required this.id,
    required this.text,
    required this.timestamp,
    this.type = NotificationType.general,
    this.isRead = false,
  });
}

class NotificationItemAdapter extends TypeAdapter<NotificationItem> {
  @override
  final int typeId = 3;

  @override
  NotificationItem read(BinaryReader reader) {
    return NotificationItem(
      id: reader.readString(),
      text: reader.readString(),
      timestamp: DateTime.parse(reader.readString()),
      type: NotificationType.values[reader.readInt()],
      isRead: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, NotificationItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.text);
    writer.writeString(obj.timestamp.toIso8601String());
    writer.writeInt(obj.type.index);
    writer.writeBool(obj.isRead);
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  int _currentIndex = 0;
  late Box<NotificationItem> _notificationBox;

  @override
  void initState() {
    super.initState();
    _notificationBox = Hive.box<NotificationItem>('notifications');
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
    final notification = _notificationBox.values.firstWhere(
      (n) => n.id == id,
      orElse: () => NotificationItem(id: '', text: '', timestamp: DateTime.now(), type: NotificationType.general),
    );
    if (notification.id.isNotEmpty) {
      notification.isRead = true;
      notification.save();
      setState(() {});
    }
  }

  void _deleteNotification(String id) {
    final notification = _notificationBox.values.firstWhere(
      (n) => n.id == id,
      orElse: () => NotificationItem(id: '', text: '', timestamp: DateTime.now(), type: NotificationType.general),
    );
    if (notification.id.isNotEmpty) {
      notification.delete();
      setState(() {});
    }
  }

  void _clearAll() {
    _notificationBox.clear();
    setState(() {});
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
    final notifications = _notificationBox.values.toList().reversed.toList();
    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(brightness),
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.title(brightness)),
        centerTitle: true,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Clear All',
                style: AppTextStyles.button(brightness).copyWith(color: AppColors.getPrimary(brightness)),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(brightness)
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
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

  static Future<void> showReminder({
    String title = 'StepWise Reminder',
    String body = 'Don\'t forget to check your daily step progress!',
    int id = 0,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Daily Reminders',
          channelDescription: 'Daily reminder to check your steps',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> showSummary({
    required int steps,
    required double distanceKm,
    int id = 1,
  }) async {
    await _notificationsPlugin.show(
      id,
      'StepWise Daily Summary',
      'You walked $steps steps today (${distanceKm.toStringAsFixed(2)} km)!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'summary_channel',
          'Daily Summaries',
          channelDescription: 'Daily summary of your steps',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
} 