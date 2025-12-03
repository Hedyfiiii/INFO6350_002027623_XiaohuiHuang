import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _sortBy = 'gamesWon'; // Default sort

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSortSelector(),
          Expanded(child: _buildLeaderboard()),
        ],
      ),
    );
  }

  Widget _buildSortSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Text(
              'Sort by:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'gamesWon',
                    label: Text('Wins'),
                    icon: Icon(Icons.emoji_events, size: 16),
                  ),
                  ButtonSegment(
                    value: 'gamesPlayed',
                    label: Text('Games'),
                    icon: Icon(Icons.sports_esports, size: 16),
                  ),
                ],
                selected: {_sortBy},
                onSelectionChanged: (Set<String> selected) {
                  setState(() {
                    _sortBy = selected.first;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('gamesPlayed', isGreaterThan: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading leaderboard: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No players yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to play!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Sort players client-side
        final players = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'uid': doc.id,
            'displayName': data['displayName'] ?? 'Unknown Player',
            'photoURL': data['photoURL'],
            'gamesPlayed': data['gamesPlayed'] ?? 0,
            'gamesWon': data['gamesWon'] ?? 0,
            'gamesLost': data['gamesLost'] ?? 0,
            'gamesDraw': data['gamesDraw'] ?? 0,
          };
        }).toList();

        // Sort by selected criteria
        players.sort((a, b) {
          final aValue = a[_sortBy] as int;
          final bValue = b[_sortBy] as int;
          
          if (aValue != bValue) {
            return bValue.compareTo(aValue); // Descending
          }
          
          // Tie-breaker: win rate
          final aWinRate = (a['gamesPlayed'] as int) > 0
              ? (a['gamesWon'] as int) / (a['gamesPlayed'] as int)
              : 0.0;
          final bWinRate = (b['gamesPlayed'] as int) > 0
              ? (b['gamesWon'] as int) / (b['gamesPlayed'] as int)
              : 0.0;
          
          return bWinRate.compareTo(aWinRate);
        });

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        return ListView.builder(
          itemCount: players.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final player = players[index];
            final isCurrentUser = player['uid'] == currentUserId;
            final rank = index + 1;

            return _buildPlayerCard(player, rank, isCurrentUser);
          },
        );
      },
    );
  }

  Widget _buildPlayerCard(
    Map<String, dynamic> player,
    int rank,
    bool isCurrentUser,
  ) {
    final gamesPlayed = player['gamesPlayed'] as int;
    final gamesWon = player['gamesWon'] as int;
    final gamesLost = player['gamesLost'] as int;
    final gamesDraw = player['gamesDraw'] as int;
    
    final winRate = gamesPlayed > 0
        ? (gamesWon / gamesPlayed * 100).toStringAsFixed(1)
        : '0.0';

    Color? rankColor;
    IconData? rankIcon;

    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey[400];
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown[300];
      rankIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrentUser ? Colors.blue.shade50 : null,
      elevation: isCurrentUser ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 40,
              child: rankIcon != null
                  ? Icon(rankIcon, color: rankColor, size: 32)
                  : Text(
                      '#$rank',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 12),
            
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: player['photoURL'] != null
                  ? NetworkImage(player['photoURL'])
                  : null,
              child: player['photoURL'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player['displayName'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isCurrentUser
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Win Rate: $winRate% | Games: $gamesPlayed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'W:$gamesWon L:$gamesLost D:$gamesDraw',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Highlighted stat
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    player[_sortBy].toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    _sortBy == 'gamesWon' ? 'Wins' : 'Games',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}