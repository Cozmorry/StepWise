import 'package:hive/hive.dart';

part 'activity_record.g.dart';

@HiveType(typeId: 0)
class ActivityRecord extends HiveObject {
  @HiveField(0)
  late DateTime date;

  @HiveField(1)
  late int steps;

  @HiveField(2)
  late double distance; // in km

  @HiveField(3)
  late int calories; // in kcal

  ActivityRecord({
    required this.date,
    required this.steps,
    this.distance = 0.0,
    this.calories = 0,
  });
} 