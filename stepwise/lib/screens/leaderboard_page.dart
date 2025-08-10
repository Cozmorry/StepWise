import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/leaderboard_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Stream<QuerySnapshot> _leaderboardStream;

  @override
  void initState() {
    super.initState();
    _initializeLeaderboard();
  }

  Future<void> _initializeLeaderboard() async {
    // Perform daily reset check when leaderboard is opened
    await LeaderboardService.performDailyResetIfNeeded();
    setState(() {
      _leaderboardStream = _getLeaderboardStream();
    });
  }

  Stream<QuerySnapshot> _getLeaderboardStream() {
    return LeaderboardService.getDailyLeaderboardStream();
  }

  Future<void> _refresh() async {
    // Perform daily reset check on refresh
    await LeaderboardService.performDailyResetIfNeeded();
    setState(() {
      _leaderboardStream = _getLeaderboardStream();
    });
  }

  Widget _buildPositionBadge(int position, bool isCurrentUser, Brightness brightness) {
    // Special styling for top 3 positions
    if (position == 1) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 24,
          ),
        ),
      );
    } else if (position == 2) {
      return Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC0C0C0), Color(0xFFA0A0A0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.workspace_premium,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    } else if (position == 3) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCD7F32), Color(0xFFB8860B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.star,
            color: Colors.white,
            size: 18,
          ),
        ),
      );
    } else {
      // Regular positions
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isCurrentUser 
              ? AppColors.getPrimary(brightness)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '#$position',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCurrentUser ? Colors.white : Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
  }

  Color _getCardColor(int position, bool isCurrentUser, Brightness brightness) {
    if (isCurrentUser) {
      return AppColors.getPrimary(brightness).withOpacity(0.15);
    }
    
    switch (position) {
      case 1:
        return const Color(0xFFFFF8E1); // Light gold background
      case 2:
        return const Color(0xFFF5F5F5); // Light silver background
      case 3:
        return const Color(0xFFFDF5E6); // Light bronze background
      default:
        return AppColors.getSecondary(brightness);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.getPrimary(brightness),
        elevation: 0,
        title: Column(
          children: [
            Text(
              '🏆 Leaderboard',
              style: AppTextStyles.title(brightness).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Daily Steps',
              style: AppTextStyles.body(brightness).copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
          // Manual reset button for testing (can be removed in production)
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.white),
            onPressed: () async {
              await LeaderboardService.manualReset();
              _refresh();
            },
            tooltip: 'Manual Reset (Testing)',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: StreamBuilder<QuerySnapshot>(
          stream: _leaderboardStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading leaderboard: ${snapshot.error}',
                      style: AppTextStyles.body(brightness),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimary(brightness),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.leaderboard_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No leaderboard data available.',
                      style: AppTextStyles.subtitle(brightness).copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to log some steps today!',
                      style: AppTextStyles.body(brightness).copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Leaderboard resets daily at midnight',
                        style: AppTextStyles.body(brightness).copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final allUsers = snapshot.data!.docs;
            
            // Filter out users who haven't been active today and have less than 1 step
            final today = DateTime.now();
            final activeUsers = allUsers.where((doc) {
              final userData = doc.data() as Map<String, dynamic>;
              final lastActiveStr = userData['lastActiveDate'];
              final dailySteps = userData['dailySteps'] ?? 0;
              
              // Filter out users with less than 1 step
              if (dailySteps < 1) return false;
              
              if (lastActiveStr == null) return false;
              
              try {
                final lastActive = DateTime.parse(lastActiveStr);
                return lastActive.year == today.year && 
                       lastActive.month == today.month && 
                       lastActive.day == today.day;
              } catch (e) {
                return false;
              }
            }).take(10).toList();
            
            if (activeUsers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active users today',
                      style: AppTextStyles.subtitle(brightness).copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to log some steps today!',
                      style: AppTextStyles.body(brightness).copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Leaderboard resets daily at midnight',
                        style: AppTextStyles.body(brightness).copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: activeUsers.length + 1, // +1 for the reset info header
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                // Show reset info at the top
                if (index == 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Today\'s leaderboard • Resets daily at midnight',
                            style: AppTextStyles.body(brightness).copyWith(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final user = activeUsers[index - 1].data() as Map<String, dynamic>;
                final isCurrentUser = currentUser != null && user['userId'] == currentUser.uid;
                final steps = user['dailySteps'] ?? 0;
                final name = user['name'] ?? 'Unknown';
                final position = index;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Card(
                    color: _getCardColor(position, isCurrentUser, brightness),
                    elevation: position <= 3 ? 6 : 2,
                    shadowColor: position == 1 
                        ? Colors.amber.withOpacity(0.3)
                        : position == 2 
                            ? Colors.grey.withOpacity(0.3)
                            : position == 3
                                ? Colors.brown.withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isCurrentUser 
                          ? BorderSide(
                              color: AppColors.getPrimary(brightness),
                              width: 2,
                            )
                          : position <= 3
                              ? BorderSide(
                                  color: position == 1 
                                      ? Colors.amber.shade400
                                      : position == 2
                                          ? Colors.grey.shade400
                                          : Colors.brown.shade400,
                                  width: 1.5,
                                )
                              : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildPositionBadge(position, isCurrentUser, brightness),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: AppTextStyles.subtitle(brightness).copyWith(
                                          fontWeight: isCurrentUser 
                                              ? FontWeight.bold 
                                              : position <= 3 
                                                  ? FontWeight.w600 
                                                  : FontWeight.normal,
                                          color: isCurrentUser 
                                              ? AppColors.getPrimary(brightness)
                                              : position == 1
                                                  ? Colors.amber.shade800
                                                  : position == 2
                                                      ? Colors.grey.shade700
                                                      : position == 3
                                                          ? Colors.brown.shade700
                                                          : null,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentUser)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.getPrimary(brightness),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'YOU',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.directions_walk,
                                      size: 16,
                                      color: position == 1
                                          ? Colors.amber.shade700
                                          : position == 2
                                              ? Colors.grey.shade600
                                              : position == 3
                                                  ? Colors.brown.shade600
                                                  : Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$steps steps',
                                      style: AppTextStyles.body(brightness).copyWith(
                                        fontWeight: position <= 3 
                                            ? FontWeight.w600 
                                            : FontWeight.normal,
                                        color: position == 1
                                            ? Colors.amber.shade700
                                            : position == 2
                                                ? Colors.grey.shade600
                                                : position == 3
                                                    ? Colors.brown.shade600
                                                    : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (position <= 3)
                            Icon(
                              position == 1 
                                  ? Icons.emoji_events
                                  : position == 2
                                      ? Icons.workspace_premium
                                      : Icons.star,
                              color: position == 1
                                  ? Colors.amber.shade600
                                  : position == 2
                                      ? Colors.grey.shade500
                                      : Colors.brown.shade500,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 