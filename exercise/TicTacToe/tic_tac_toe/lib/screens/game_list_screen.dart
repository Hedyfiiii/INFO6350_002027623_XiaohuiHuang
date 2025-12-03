import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'game_board_screen.dart';
import 'dart:developer' as developer;

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _buildActiveGamesList(),
          ),
          Divider(height: 1.5, thickness: 1.5, color: Colors.grey[400]),
          _buildCompletedGamesSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewGame,
        icon: const Icon(Icons.add),
        label: const Text('New Game'),
      ),
    );
  }

  Widget _buildActiveGamesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games')
          .where('status', whereIn: ['active', 'waiting'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          developer.log('Firestore Stream Error (Active): ${snapshot.error}');
          
          // Check if it's an index error
          if (snapshot.error.toString().toLowerCase().contains('index')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'Firestore Index Required',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please create the required Firestore index.\nCheck the console for a link to create it.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Error loading games'),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }
        
        final docs = snapshot.data?.docs ?? [];
        
        developer.log(
          'Active games loaded: ${docs.length} games',
          name: 'GameListScreen',
        );
        
        // Debug: Print game details
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          developer.log(
            'Game ${doc.id}: status=${data['status']}, playerX=${data['playerX']?['displayName']}, playerO=${data['playerO']?['displayName']}',
            name: 'GameListScreen.Debug',
          );
        }
        
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No active games',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a new game to start playing!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _buildActiveGameTile(docs[index]);
          },
        );
      },
    );
  }

  Widget _buildCompletedGamesSection() {
    return ExpansionTile(
      title: _buildCompletedGamesHeader(),
      controlAffinity: ListTileControlAffinity.leading,
      initiallyExpanded: false,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.blueGrey[50],
      children: <Widget>[_buildCompletedGamesList()],
    );
  }

  Widget _buildCompletedGamesHeader() {
    final userId = _currentUser?.uid;
    if (userId == null) {
      return _buildHeaderContent('Completed Games', null);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games')
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildHeaderContent('Completed Games', null);
        }

        int userCompletedCount = 0;
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final playerXUserId = data['playerX']?['userId'];
            final playerOUserId = data['playerO']?['userId'];
            if (playerXUserId == userId || playerOUserId == userId) {
              userCompletedCount++;
            }
          }
        }
        return _buildHeaderContent('Completed Games', userCompletedCount);
      },
    );
  }

  Widget _buildHeaderContent(String title, int? count) {
    return Container(
      color: Colors.blueGrey[50],
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blueGrey[800],
              ),
            ),
          ),
          if (count != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                '($count)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.blueGrey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedGamesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games')
          .where('status', isEqualTo: 'completed')
          .orderBy('endedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          developer.log(
            "Error loading completed games: ${snapshot.error}",
            name: "GameListScreen.CompletedList",
            error: snapshot.error,
          );
          String errorText = 'Error loading completed games.';
          if (snapshot.error.toString().toLowerCase().contains('index')) {
            errorText += '\n\nPlease create the required Firestore index.\n'
                'Check console for index creation link.';
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text(errorText, textAlign: TextAlign.center)),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No completed games found.')),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            if (!mounted) return const SizedBox.shrink();
            return _buildCompletedGameTile(docs[index]);
          },
        );
      },
    );
  }

  Widget _buildActiveGameTile(DocumentSnapshot gameDoc) {
    var data = gameDoc.data() as Map<String, dynamic>? ?? {};
    var playerXData = data['playerX'] as Map<String, dynamic>? ?? {};
    var playerOData = data['playerO'] as Map<String, dynamic>?;

    String playerXName = playerXData['displayName'] ?? "Unknown Player";
    String playerOName = playerOData?['displayName'] ?? "Waiting...";
    var status = data['status'] ?? "Unknown";
    String displayStatus = status[0].toUpperCase() + status.substring(1);
    var createdAtData = data['createdAt'];
    String started = _formatTimestamp(createdAtData);

    String tileTitle;
    IconData leadingIcon;
    Color iconColor;

    if (status == 'waiting') {
      tileTitle = 'Game by $playerXName';
      leadingIcon = Icons.hourglass_empty;
      iconColor = Colors.orange;
    } else {
      tileTitle = '$playerXName vs $playerOName';
      // Check if it's current user's turn
      final currentTurn = data['currentTurn'];
      final isMyTurn = (currentTurn == 'X' && 
                       playerXData['userId'] == _currentUser?.uid) ||
                      (currentTurn == 'O' && 
                       playerOData?['userId'] == _currentUser?.uid);
      
      leadingIcon = isMyTurn ? Icons.touch_app : Icons.sports_esports;
      iconColor = isMyTurn ? Colors.green : Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(leadingIcon, color: iconColor, size: 32),
        title: Text(tileTitle),
        subtitle: Text('Status: $displayStatus\nStarted: $started'),
        trailing: status == 'waiting' && 
                 playerXData['userId'] != _currentUser?.uid
            ? ElevatedButton(
                onPressed: () => _joinGame(gameDoc.id),
                child: const Text('Join'),
              )
            : const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameBoardScreen(gameId: gameDoc.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletedGameTile(DocumentSnapshot gameDoc) {
    var data = gameDoc.data() as Map<String, dynamic>? ?? {};
    var playerXData = data['playerX'] as Map<String, dynamic>? ?? {};
    var playerOData = data['playerO'] as Map<String, dynamic>? ?? {};

    String playerXName = playerXData['displayName'] ?? "Player X";
    String playerOName = playerOData['displayName'] ?? "Player O";
    var winner = data['winner'];
    var endedAtData = data['endedAt'];
    String endedDate = _formatTimestamp(endedAtData);

    String resultText;
    Icon resultIcon;

    if (winner == 'draw') {
      resultText = 'Draw';
      resultIcon = const Icon(Icons.handshake_outlined, color: Colors.orange);
    } else if (winner == 'X') {
      resultText = 'Winner: $playerXName (X)';
      resultIcon = const Icon(Icons.emoji_events, color: Colors.green);
    } else if (winner == 'O') {
      resultText = 'Winner: $playerOName (O)';
      resultIcon = const Icon(Icons.emoji_events, color: Colors.green);
    } else {
      resultText = 'Result: Unknown';
      resultIcon = const Icon(Icons.question_mark, color: Colors.grey);
    }

    return ListTile(
      leading: resultIcon,
      title: Text('$playerXName vs $playerOName'),
      subtitle: Text('$resultText\nEnded: $endedDate'),
      dense: true,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameBoardScreen(gameId: gameDoc.id),
          ),
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestampData) {
    if (timestampData is Timestamp) {
      try {
        return DateFormat.yMd().add_jm().format(
          timestampData.toDate().toLocal(),
        );
      } catch (e) {
        final dt = timestampData.toDate().toLocal();
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
            '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }
    return "N/A";
  }

  Future<void> _joinGame(String gameId) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('games')
          .doc(gameId)
          .update({
        'playerO': {
          'userId': user.uid,
          'displayName': user.displayName ?? user.email ?? 'Player O',
        },
        'status': 'active',
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameBoardScreen(gameId: gameId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining game: $e')),
        );
      }
    }
  }

  Future<void> _createNewGame() async {
    final user = _currentUser;
    if (user == null) return;

    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final gameData = {
        'playerX': {
          'userId': user.uid,
          'displayName': user.displayName ?? user.email ?? 'Player X',
        },
        'playerO': null,
        'status': 'waiting',
        'currentTurn': 'X',
        'board': List.filled(9, null),
        'winner': null,
        'createdAt': FieldValue.serverTimestamp(),
        'moves': [],
        'endedAt': null,
      };
      
      var doc = await FirebaseFirestore.instance
          .collection('games')
          .add(gameData);

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameBoardScreen(gameId: doc.id),
        ),
      );
    } catch (e) {
      developer.log('Error creating game: $e');
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create game: $e')),
      );
    }
  }
}