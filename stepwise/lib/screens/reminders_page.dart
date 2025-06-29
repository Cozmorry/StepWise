import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'notifications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  late Box<Reminder> _reminderBox;
  bool _showHint = false;
  bool _isAddingReminder = false;

  @override
  void initState() {
    super.initState();
    _initializeReminderBox();
    _checkFirstTime();
  }

  Future<void> _initializeReminderBox() async {
    _reminderBox = Hive.box<Reminder>('reminders');
    await _cleanupDuplicateReminders();
  }

  Future<void> _cleanupDuplicateReminders() async {
    final reminders = _reminderBox.values.toList();
    final seenReminders = <String>{};
    final duplicates = <int>[];
    
    for (int i = 0; i < reminders.length; i++) {
      final reminder = reminders[i];
      final key = '${reminder.message}_${reminder.time.hour}_${reminder.time.minute}_${reminder.repeat}';
      
      if (seenReminders.contains(key)) {
        duplicates.add(i);
      } else {
        seenReminders.add(key);
      }
    }
    
    // Remove duplicates in reverse order to maintain correct indices
    for (int i = duplicates.length - 1; i >= 0; i--) {
      await _reminderBox.deleteAt(duplicates[i]);
    }
    
    if (duplicates.isNotEmpty && mounted) {
      setState(() {});
    }
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenHint = prefs.getBool('reminders_hint_seen') ?? false;
    if (!hasSeenHint) {
      setState(() {
        _showHint = true;
      });
    }
  }

  Future<void> _dismissHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_hint_seen', true);
    setState(() {
      _showHint = false;
    });
  }

  void _addReminderDialog() async {
    if (_isAddingReminder) return; // Prevent multiple dialogs
    
    TimeOfDay selectedTime = TimeOfDay.now();
    final messageController = TextEditingController();
    String repeat = 'none';
    
    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Enter your reminder message',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
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
                            setDialogState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        child: Text(
                          selectedTime.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: repeat,
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('One-time')),
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          repeat = val;
                        });
                      }
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
                  onPressed: _isAddingReminder ? null : () async {
                    final message = messageController.text.trim();
                    if (message.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a reminder message'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    setDialogState(() {
                      _isAddingReminder = true;
                    });
                    
                    try {
                      final now = DateTime.now();
                      var reminderTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
                      
                      // If the time has already passed today, schedule for tomorrow
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
                        message: message,
                        repeat: repeat,
                        notificationId: notificationId,
                      );
                      
                      // Check for duplicate reminders
                      final existingReminders = _reminderBox.values.toList();
                      final isDuplicate = existingReminders.any((r) => 
                        r.message == reminder.message && 
                        r.time.hour == reminder.time.hour && 
                        r.time.minute == reminder.time.minute &&
                        r.repeat == reminder.repeat
                      );
                      
                      if (isDuplicate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('A similar reminder already exists'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        setDialogState(() {
                          _isAddingReminder = false;
                        });
                        return;
                      }
                      
                      await _reminderBox.add(reminder);
                      await NotificationHelper.scheduleReminder(
                        id: notificationId,
                        title: 'StepWise Reminder',
                        body: reminder.message,
                        dateTime: reminder.time,
                        repeat: reminder.repeat,
                      );
                      
                      if (mounted) {
                        setState(() {});
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reminder set for ${TimeOfDay.fromDateTime(reminder.time).format(context)}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error creating reminder: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      setDialogState(() {
                        _isAddingReminder = false;
                      });
                    }
                  },
                  child: _isAddingReminder 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteReminder(int index) async {
    try {
      final reminders = _reminderBox.values.toList();
      if (index >= 0 && index < reminders.length) {
        final reminder = reminders[index];
        await NotificationHelper.notificationsPlugin.cancel(reminder.notificationId);
        await _reminderBox.deleteAt(index);
        
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearAllReminders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Reminders'),
        content: const Text('Are you sure you want to delete all reminders? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Cancel all notifications
      for (final reminder in _reminderBox.values) {
        await NotificationHelper.notificationsPlugin.cancel(reminder.notificationId);
      }
      
      // Clear all reminders from storage
      await _reminderBox.clear();
      
      if (mounted) setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All reminders cleared'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editReminderDialog(Reminder reminder, int index) async {
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(reminder.time);
    final messageController = TextEditingController(text: reminder.message);
    String repeat = reminder.repeat;
    bool isSaving = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Enter your reminder message',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
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
                            setDialogState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        child: Text(
                          selectedTime.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: repeat,
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('One-time')),
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          repeat = val;
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Repeat'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final message = messageController.text.trim();
                    if (message.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a reminder message'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    setDialogState(() {
                      isSaving = true;
                    });
                    
                    try {
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
                        message: message,
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
                      
                      if (mounted) {
                        setState(() {});
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reminder updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating reminder: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      setDialogState(() {
                        isSaving = false;
                      });
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Ensure we get a fresh list of reminders and sort them by time
    final reminders = _reminderBox.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(brightness),
        elevation: 0,
        title: Text('Reminders', style: AppTextStyles.title(brightness)),
        centerTitle: true,
        actions: [
          if (reminders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllReminders,
              tooltip: 'Clear all reminders',
            ),
        ],
      ),
      body: reminders.isEmpty
          ? _buildEmptyState(brightness)
          : Column(
              children: [
                if (_showHint) _buildHintBanner(brightness),
                Expanded(
                  child: ListView.builder(
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
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.alarm),
                              title: Text(reminder.message),
                              subtitle: Text(
                                '${TimeOfDay.fromDateTime(reminder.time).format(context)} • ${reminder.repeat == 'none' ? 'One-time' : reminder.repeat.capitalize()} Reminder',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editReminderDialog(reminder, index),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isAddingReminder ? null : _addReminderDialog,
        child: _isAddingReminder 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off_outlined,
            size: 80,
            color: AppColors.getSecondary(brightness),
          ),
          const SizedBox(height: 20),
          Text(
            'No Reminders Yet',
            style: AppTextStyles.heading(brightness),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first reminder',
            style: AppTextStyles.subtitle(brightness),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHintBanner(Brightness brightness) {
    return Card(
      color: AppColors.getSecondary(brightness),
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.alarm,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⏰ Set reminders!',
                    style: AppTextStyles.subtitle(brightness).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add reminders and stay on track',
                    style: AppTextStyles.body(brightness),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey[600]),
              onPressed: _dismissHint,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
} 