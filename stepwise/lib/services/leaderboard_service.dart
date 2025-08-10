import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardService {
  static const String _lastResetKey = 'leaderboard_last_reset';
  static const String _dailyStepsKey = 'dailySteps';
  static const String _lastActiveDateKey = 'lastActiveDate';

  /// Check if leaderboard needs to be reset for a new day
  static Future<bool> _needsDailyReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString(_lastResetKey);
    
    if (lastResetStr == null) {
      // First time, set today as reset date
      await _setLastResetDate();
      return false;
    }
    
    final lastReset = DateTime.parse(lastResetStr);
    final today = DateTime.now();
    
    // Check if it's a new day (different date)
    return lastReset.year != today.year || 
           lastReset.month != today.month || 
           lastReset.day != today.day;
  }

  /// Set the last reset date to today
  static Future<void> _setLastResetDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastResetKey, DateTime.now().toIso8601String());
  }

  /// Reset all users' daily steps to 0
  static Future<void> _resetAllUsersDailySteps() async {
    try {
      print('🔄 Starting daily leaderboard reset...');
      
      // Get all users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      // Reset daily steps for all users
      final batch = FirebaseFirestore.instance.batch();
      int resetCount = 0;
      
      for (final doc in usersSnapshot.docs) {
        batch.update(doc.reference, {
          _dailyStepsKey: 0,
          _lastActiveDateKey: DateTime.now().toIso8601String(),
        });
        resetCount++;
      }
      
      await batch.commit();
      await _setLastResetDate();
      
      print('✅ Daily leaderboard reset completed. Reset $resetCount users.');
    } catch (e) {
      print('❌ Error during daily leaderboard reset: $e');
    }
  }

  /// Perform daily reset if needed
  static Future<void> performDailyResetIfNeeded() async {
    if (await _needsDailyReset()) {
      await _resetAllUsersDailySteps();
    }
  }

  /// Manual reset for testing purposes
  static Future<void> manualReset() async {
    await _resetAllUsersDailySteps();
  }

  /// Update user's daily steps for leaderboard
  static Future<void> updateUserDailySteps(int steps) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // First check if we need to reset
      await performDailyResetIfNeeded();
      
      // Update the user's daily steps
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        _dailyStepsKey: steps,
        _lastActiveDateKey: DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      
      print('✅ Updated daily steps for user: $steps');
    } catch (e) {
      print('❌ Error updating daily steps: $e');
    }
  }

  /// Get leaderboard stream with daily steps
  static Stream<QuerySnapshot> getDailyLeaderboardStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy(_dailyStepsKey, descending: true)
        .limit(20) // Get more to filter out inactive users
        .snapshots();
  }

  /// Get user's current daily steps
  static Future<int> getUserDailySteps() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        return doc.data()?[_dailyStepsKey] ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting user daily steps: $e');
      return 0;
    }
  }

  /// Check if user was active today
  static Future<bool> wasUserActiveToday() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        final lastActiveStr = doc.data()?[_lastActiveDateKey];
        if (lastActiveStr != null) {
          final lastActive = DateTime.parse(lastActiveStr);
          final today = DateTime.now();
          
          return lastActive.year == today.year && 
                 lastActive.month == today.month && 
                 lastActive.day == today.day;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error checking if user was active today: $e');
      return false;
    }
  }
}
