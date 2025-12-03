import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_list_screen.dart';
import 'leaderboard_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Map<String, dynamic>? _userStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _userStats = doc.data();
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      // StreamBuilder in main.dart will handle navigation
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tic-Tac-Toe'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.games), text: 'Games'),
              Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Stats',
              onPressed: _loadUserStats,
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'logout') {
                  _signOut();
                } else if (value == 'profile') {
                  _showProfileDialog();
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildUserHeader(user),
            Expanded(
              child: TabBarView(
                children: [
                  GameListScreen(),
                  const LeaderboardScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(User? user) {
    if (_isLoadingStats) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final gamesPlayed = _userStats?['gamesPlayed'] ?? 0;
    final gamesWon = _userStats?['gamesWon'] ?? 0;
    final gamesLost = _userStats?['gamesLost'] ?? 0;
    final gamesDraw = _userStats?['gamesDraw'] ?? 0;
    final winRate = gamesPlayed > 0 
        ? (gamesWon / gamesPlayed * 100).toStringAsFixed(1) 
        : '0.0';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? user?.email ?? 'Player',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Win Rate: $winRate% | Games: $gamesPlayed',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'W:$gamesWon L:$gamesLost D:$gamesDraw',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final gamesPlayed = _userStats?['gamesPlayed'] ?? 0;
    final gamesWon = _userStats?['gamesWon'] ?? 0;
    final gamesLost = _userStats?['gamesLost'] ?? 0;
    final gamesDraw = _userStats?['gamesDraw'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Player Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Name: ${user.displayName ?? "N/A"}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${user.email ?? "N/A"}',
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 24),
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Games Played: $gamesPlayed'),
            Text('Wins: $gamesWon', style: const TextStyle(color: Colors.green)),
            Text('Losses: $gamesLost', style: const TextStyle(color: Colors.red)),
            Text('Draws: $gamesDraw', style: const TextStyle(color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}