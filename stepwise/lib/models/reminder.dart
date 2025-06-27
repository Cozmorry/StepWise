import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 4)
class Reminder extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime time;

  @HiveField(2)
  String message;

  @HiveField(3)
  String repeat; // 'none', 'daily', 'weekly'

  @HiveField(4)
  int notificationId;

  Reminder({
    required this.id,
    required this.time,
    required this.message,
    this.repeat = 'none',
    required this.notificationId,
  });
} 