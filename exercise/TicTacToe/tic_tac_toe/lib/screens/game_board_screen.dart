import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class GameBoardScreen extends StatefulWidget {
  final String gameId;

  const GameBoardScreen({super.key, required this.gameId});

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  List<dynamic>? _localBoardState;
  User? _currentUser;
  Map<String, dynamic>? _currentGameData;
  bool _hasShownGameOverDialog = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    developer.log(
      "GameBoardScreen Init - User: ${_currentUser?.uid}",
      name: "GameBoardScreen",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game ${widget.gameId.substring(0, 6)}...'),
        actions: [
          if (_currentGameData?['status'] == 'waiting' &&
              _currentGameData?['playerX']?['userId'] == _currentUser?.uid)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Cancel Game',
              onPressed: _cancelGame,
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('games')
            .doc(widget.gameId)
            .snapshots(),
        builder: (context, snapshot) {
          // Update local state
          if (snapshot.hasData && snapshot.data!.exists) {
            _currentGameData = snapshot.data!.data() as Map<String, dynamic>;
            _localBoardState = List<dynamic>.from(
              _currentGameData!['board'] ?? List.filled(9, null),
            );

            // Show game over dialog
            if (_currentGameData!['status'] == 'completed' && 
                !_hasShownGameOverDialog) {
              _hasShownGameOverDialog = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showGameOverDialog();
              });
            }
          } else if (snapshot.connectionState == ConnectionState.active &&
              snapshot.hasData &&
              !snapshot.data!.exists) {
            _currentGameData = null;
            _localBoardState = null;
          }

          // Loading/error states
          if (_currentGameData == null) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading game: ${snapshot.error}'),
              );
            }
            return const Center(
              child: Text('Game not found or has been deleted.'),
            );
          }

          final game = _currentGameData!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _buildPlayerInfo(game),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 450,
                      maxHeight: 450,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildBoard(game),
                    ),
                  ),
                ),
              ),
              _buildGameStatus(game),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerInfo(Map<String, dynamic> game) {
    final user = _currentUser;
    if (user == null) return const Text('Not logged in');

    // Show join button if waiting and user is not player X
    if (game['status'] == 'waiting' &&
        game['playerO'] == null &&
        game['playerX']?['userId'] != user.uid) {
      return ElevatedButton.icon(
        onPressed: () => _joinGame(user),
        icon: const Icon(Icons.person_add),
        label: const Text('Join as Player O'),
      );
    }

    String playerXName = game['playerX']?['displayName'] ?? 'Player X';
    String playerOName = game['playerO']?['displayName'] ?? 'Waiting...';
    String? playerXPhoto = game['playerX']?['photoURL'];
    String? playerOPhoto = game['playerO']?['photoURL'];
    
    String currentTurn = game['currentTurn'] ?? '';
    bool isXTurn = currentTurn == 'X';
    bool isCompleted = game['status'] == 'completed';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildPlayerCard(
              playerXName,
              'X',
              playerXPhoto,
              isXTurn && !isCompleted,
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildPlayerCard(
              playerOName,
              'O',
              playerOPhoto,
              !isXTurn && !isCompleted && game['playerO'] != null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(
    String name,
    String symbol,
    String? photoUrl,
    bool isActive,
  ) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.green : Colors.grey.shade300,
              width: isActive ? 3 : 2,
            ),
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    symbol,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: symbol == 'X' ? Colors.red : Colors.blue,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.green : null,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBoard(Map<String, dynamic> game) {
    final boardList = _localBoardState ?? List.filled(9, null);
    final user = _currentUser;

    if (user == null) {
      return const Center(child: Text('Login required to play.'));
    }

    final currentUserUID = user.uid;
    final gameStatus = game['status'];
    final currentTurn = game['currentTurn'];
    final playerXUserId = game['playerX']?['userId'];
    final playerOUserId = game['playerO']?['userId'];

    bool isMyTurn = false;
    if (gameStatus == 'active') {
      if (currentTurn == 'X' && playerXUserId == currentUserUID) {
        isMyTurn = true;
      } else if (currentTurn == 'O' && playerOUserId == currentUserUID) {
        isMyTurn = true;
      }
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        String notation = _getChessNotation(index);
        String? cellValue = boardList.length > index
            ? boardList[index]?.toString()
            : null;
        String displayValue = cellValue ?? notation;

        bool canTap = gameStatus == 'active' && 
                     isMyTurn && 
                     cellValue == null;

        return GestureDetector(
          onTap: canTap
              ? () {
                  final player = (playerXUserId == currentUserUID) ? 'X' : 'O';
                  
                  // Optimistic update
                  setState(() {
                    _localBoardState ??= List.filled(9, null);
                    if (_localBoardState![index] == null) {
                      _localBoardState![index] = player;
                    }
                  });

                  _makeMove(index, game, player);
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8.0),
              color: canTap
                  ? Colors.lightBlue.shade50
                  : (cellValue == null
                      ? Colors.white
                      : Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: cellValue == 'X'
                      ? Colors.red
                      : (cellValue == 'O'
                          ? Colors.blue
                          : (canTap
                              ? Colors.black54
                              : Colors.grey.shade600)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameStatus(Map<String, dynamic> game) {
    final status = game['status'];
    final currentTurn = game['currentTurn'];
    final winner = game['winner'];
    final user = _currentUser;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (status == 'waiting') {
      statusText = 'Waiting for opponent to join...';
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
    } else if (status == 'completed') {
      if (winner == 'draw') {
        statusText = 'Game ended in a draw!';
        statusColor = Colors.grey;
        statusIcon = Icons.handshake;
      } else {
        String winnerName;
        String? winnerUserId;
        
        if (winner == 'X') {
          winnerName = game['playerX']?['displayName'] ?? 'Player X';
          winnerUserId = game['playerX']?['userId'];
        } else {
          winnerName = game['playerO']?['displayName'] ?? 'Player O';
          winnerUserId = game['playerO']?['userId'];
        }
        
        if (winnerUserId == user?.uid) {
          statusText = 'You won! 🎉';
          statusColor = Colors.green;
          statusIcon = Icons.emoji_events;
        } else {
          statusText = '$winnerName won!';
          statusColor = Colors.red;
          statusIcon = Icons.close;
        }
      }
    } else {
      // Active game
      final playerXUserId = game['playerX']?['userId'];
      final playerOUserId = game['playerO']?['userId'];
      final isMyTurn = (currentTurn == 'X' && playerXUserId == user?.uid) ||
                       (currentTurn == 'O' && playerOUserId == user?.uid);

      statusText = isMyTurn ? 'Your turn!' : 'Opponent\'s turn';
      statusColor = isMyTurn ? Colors.green : Colors.orange;
      statusIcon = isMyTurn ? Icons.touch_app : Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  void _joinGame(User user) async {
    try {
      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .update({
        'playerO': {
          'userId': user.uid,
          'displayName': user.displayName ?? user.email ?? 'Player O',
          'photoURL': user.photoURL,
        },
        'status': 'active',
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining game: $e')),
        );
      }
    }
  }

  void _makeMove(int index, Map<String, dynamic> game, String player) async {
    final boardAfterMove = List<dynamic>.from(
      _localBoardState ?? List.filled(9, null),
    );

    // Verify move is still valid
    if (index < 0 ||
        index >= boardAfterMove.length ||
        boardAfterMove[index] != player) {
      developer.log("Invalid move detected, skipping Firestore update");
      return;
    }

    final move = {
      'position': index,
      'player': player,
      'notation': _getChessNotation(index),
    };

    String? winner = _checkWinner(boardAfterMove);
    String nextTurn = player == 'X' ? 'O' : 'X';

    Map<String, dynamic> updateData = {
      'board': boardAfterMove,
      'moves': FieldValue.arrayUnion([move]),
      'lastMoveTimestamp': FieldValue.serverTimestamp(),
    };

    if (winner != null) {
      updateData['winner'] = winner;
      updateData['status'] = 'completed';
      updateData['endedAt'] = FieldValue.serverTimestamp();
      
      // Update player stats
      await _updatePlayerStats(game, winner);
    } else {
      updateData['currentTurn'] = nextTurn;
      if (game['status'] != 'active') {
        updateData['status'] = 'active';
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .update(updateData);
    } catch (e) {
      developer.log("Firestore update failed: $e", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error making move: $e')),
        );
      }
    }
  }

  Future<void> _updatePlayerStats(
    Map<String, dynamic> game,
    String winner,
  ) async {
    final player1Id = game['playerX']?['userId'];
    final player2Id = game['playerO']?['userId'];

    if (player1Id == null || player2Id == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final player1Ref = FirebaseFirestore.instance
        .collection('users')
        .doc(player1Id);
    final player2Ref = FirebaseFirestore.instance
        .collection('users')
        .doc(player2Id);

    if (winner == 'draw') {
      batch.update(player1Ref, {
        'gamesPlayed': FieldValue.increment(1),
        'gamesDraw': FieldValue.increment(1),
      });
      batch.update(player2Ref, {
        'gamesPlayed': FieldValue.increment(1),
        'gamesDraw': FieldValue.increment(1),
      });
    } else {
      final winnerId = winner == 'X' ? player1Id : player2Id;
      final loserId = winner == 'X' ? player2Id : player1Id;

      final winnerRef = winnerId == player1Id ? player1Ref : player2Ref;
      final loserRef = winnerId == player1Id ? player2Ref : player1Ref;

      batch.update(winnerRef, {
        'gamesPlayed': FieldValue.increment(1),
        'gamesWon': FieldValue.increment(1),
      });
      batch.update(loserRef, {
        'gamesPlayed': FieldValue.increment(1),
        'gamesLost': FieldValue.increment(1),
      });
    }

    await batch.commit();
  }

  void _showGameOverDialog() {
    if (!mounted) return;

    final game = _currentGameData;
    if (game == null) return;

    final winner = game['winner'];
    final user = _currentUser;

    String title;
    String message;
    IconData icon;
    Color iconColor;

    if (winner == 'draw') {
      title = 'It\'s a Draw!';
      message = 'Well played by both players!';
      icon = Icons.handshake;
      iconColor = Colors.orange;
    } else {
      String? winnerUserId;
      if (winner == 'X') {
        winnerUserId = game['playerX']?['userId'];
      } else {
        winnerUserId = game['playerO']?['userId'];
      }

      if (winnerUserId == user?.uid) {
        title = 'You Won! 🎉';
        message = 'Congratulations on your victory!';
        icon = Icons.emoji_events;
        iconColor = Colors.green;
      } else {
        title = 'You Lost';
        message = 'Better luck next time!';
        icon = Icons.close;
        iconColor = Colors.red;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Games'),
          ),
        ],
      ),
    );
  }

  void _cancelGame() async {
    try {
      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .delete();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error canceling game: $e')),
        );
      }
    }
  }

  String _getChessNotation(int index) {
    final row = ['a', 'b', 'c'][index ~/ 3];
    final col = ['1', '2', '3'][index % 3];
    return '$row$col';
  }

  String? _checkWinner(List board) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6], // Diagonals
    ];

    for (var line in lines) {
      if (board.length > line[2] &&
          board[line[0]] != null &&
          board[line[0]] == board[line[1]] &&
          board[line[0]] == board[line[2]]) {
        return board[line[0]]?.toString();
      }
    }

    if (!board.contains(null)) return 'draw';
    return null;
  }
}