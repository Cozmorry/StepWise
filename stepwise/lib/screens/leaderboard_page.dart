import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<QuerySnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchLeaderboard();
  }

  Future<QuerySnapshot> _fetchLeaderboard() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('steps', descending: true)
        .limit(10)
        .get();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _fetchLeaderboard();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<QuerySnapshot>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No leaderboard data available.'));
            }
            final users = snapshot.data!.docs;
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = users[index].data() as Map<String, dynamic>;
                final isCurrentUser = currentUser != null && user['userId'] == currentUser.uid;
                return Card(
                  color: isCurrentUser ? Colors.amber.withOpacity(0.2) : Theme.of(context).cardColor,
                  elevation: isCurrentUser ? 4 : 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrentUser ? Colors.amber : Colors.blueGrey,
                      child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(user['name'] ?? 'Unknown', style: TextStyle(fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text('${user['steps'] ?? 0} steps'),
                    trailing: isCurrentUser ? const Icon(Icons.star, color: Colors.amber) : null,
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