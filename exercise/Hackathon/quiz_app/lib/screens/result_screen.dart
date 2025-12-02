// screens/result_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final bool timedOut;

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.timedOut,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / totalQuestions * 100).round();
    
    String message;
    Color messageColor;
    IconData icon;

    if (timedOut) {
      message = 'Time\'s Up!';
      messageColor = Colors.red;
      icon = Icons.timer_off;
    } else if (percentage >= 80) {
      message = 'Excellent!';
      messageColor = Colors.green;
      icon = Icons.emoji_events;
    } else if (percentage >= 60) {
      message = 'Good Job!';
      messageColor = Colors.blue;
      icon = Icons.thumb_up;
    } else if (percentage >= 40) {
      message = 'Not Bad!';
      messageColor = Colors.orange;
      icon = Icons.sentiment_satisfied;
    } else {
      message = 'Keep Trying!';
      messageColor = Colors.red;
      icon = Icons.sentiment_dissatisfied;
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              messageColor.withOpacity(0.2),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 100,
                  color: messageColor,
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: messageColor,
                  ),
                ),
                const SizedBox(height: 12),
                if (timedOut)
                  const Text(
                    'You ran out of time!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 48),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Text(
                          'Your Score',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: messageColor,
                              ),
                            ),
                            Text(
                              '/$totalQuestions',
                              style: const TextStyle(
                                fontSize: 36,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: messageColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}