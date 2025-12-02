class QuizResult {
  final String userId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final bool timedOut;

  QuizResult({
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.timedOut,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt,
      'timedOut': timedOut,
    };
  }

  factory QuizResult.fromFirestore(Map<String, dynamic> data) {
    return QuizResult(
      userId: data['userId'],
      score: data['score'],
      totalQuestions: data['totalQuestions'],
      completedAt: (data['completedAt'] as dynamic).toDate(),
      timedOut: data['timedOut'] ?? false,
    );
  }
}