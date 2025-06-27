import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'notifications_page.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  late Box<Reminder> _reminderBox;

  @override
  void initState() {
    super.initState();
    _reminderBox = Hive.box<Reminder>('reminders');
  }

  void _addReminderDialog() async {
    TimeOfDay? selectedTime = TimeOfDay.now();
    final messageController = TextEditingController();
    String repeat = 'none';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Time:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime!,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: Text(selectedTime!.format(context)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: repeat,
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('One-time')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (val) {
                  if (val != null) repeat = val;
                },
                decoration: const InputDecoration(labelText: 'Repeat'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (messageController.text.trim().isEmpty || selectedTime == null) return;
                final now = DateTime.now();
                var reminderTime = DateTime(now.year, now.month, now.day, selectedTime!.hour, selectedTime!.minute);
                if (reminderTime.isBefore(now)) {
                  if (repeat == 'weekly') {
                    reminderTime = reminderTime.add(const Duration(days: 7));
                  } else {
                    reminderTime = reminderTime.add(const Duration(days: 1));
                  }
                }
                final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
                final reminder = Reminder(
                  id: const Uuid().v4(),
                  time: reminderTime,
                  message: messageController.text.trim(),
                  repeat: repeat,
                  notificationId: notificationId,
                );
                await _reminderBox.add(reminder);
                await NotificationHelper.scheduleReminder(
                  id: notificationId,
                  title: 'StepWise Reminder',
                  body: reminder.message,
                  dateTime: reminder.time,
                  repeat: reminder.repeat,
                );
                if (mounted) setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteReminder(int index) async {
    final reminder = _reminderBox.getAt(index);
    if (reminder != null) {
      await NotificationHelper.notificationsPlugin.cancel(reminder.notificationId);
    }
    await _reminderBox.deleteAt(index);
    if (mounted) setState(() {});
  }

  void _editReminderDialog(Reminder reminder, int index) async {
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(reminder.time);
    final messageController = TextEditingController(text: reminder.message);
    String repeat = reminder.repeat;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Time:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: Text(selectedTime.format(context)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: repeat,
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('One-time')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (val) {
                  if (val != null) repeat = val;
                },
                decoration: const InputDecoration(labelText: 'Repeat'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (messageController.text.trim().isEmpty || selectedTime == null) return;
                final now = DateTime.now();
                var newTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
                if (newTime.isBefore(now)) {
                  if (repeat == 'weekly') {
                    newTime = newTime.add(const Duration(days: 7));
                  } else {
                    newTime = newTime.add(const Duration(days: 1));
                  }
                }
                await NotificationHelper.notificationsPlugin.cancel(reminder.notificationId);
                final updatedReminder = Reminder(
                  id: reminder.id,
                  time: newTime,
                  message: messageController.text.trim(),
                  repeat: repeat,
                  notificationId: reminder.notificationId,
                );
                await _reminderBox.putAt(index, updatedReminder);
                await NotificationHelper.scheduleReminder(
                  id: updatedReminder.notificationId,
                  title: 'StepWise Reminder',
                  body: updatedReminder.message,
                  dateTime: updatedReminder.time,
                  repeat: updatedReminder.repeat,
                );
                if (mounted) setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final reminders = _reminderBox.values.toList();
    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(brightness),
        elevation: 0,
        title: Text('Reminders', style: AppTextStyles.title(brightness)),
        centerTitle: true,
      ),
      body: reminders.isEmpty
          ? const Center(child: Text('No reminders yet.'))
          : ListView.builder(
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return Dismissible(
                  key: Key(reminder.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteReminder(index),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _editReminderDialog(reminder, index),
                    child: Card(
                      color: AppColors.getSecondary(brightness),
                      child: ListTile(
                        leading: const Icon(Icons.alarm),
                        title: Text(reminder.message),
                        subtitle: Text(
                          '${TimeOfDay.fromDateTime(reminder.time).format(context)} • ${reminder.repeat == 'none' ? 'One-time' : reminder.repeat.capitalize()} Reminder',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminderDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
} 