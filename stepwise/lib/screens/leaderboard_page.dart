import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

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
    _leaderboardStream = _getLeaderboardStream();
  }

  Stream<QuerySnapshot> _getLeaderboardStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('steps', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<void> _refresh() async {
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
        title: Text(
          '🏆 Leaderboard',
          style: AppTextStyles.title(brightness).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
            tooltip: 'Refresh',
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
                      'Be the first to log some steps!',
                      style: AppTextStyles.body(brightness).copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final users = snapshot.data!.docs;
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = users[index].data() as Map<String, dynamic>;
                final isCurrentUser = currentUser != null && user['userId'] == currentUser.uid;
                final steps = user['steps'] ?? 0;
                final name = user['name'] ?? 'Unknown';
                final position = index + 1;
                
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