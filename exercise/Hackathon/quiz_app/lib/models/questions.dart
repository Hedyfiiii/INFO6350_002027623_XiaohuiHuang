enum QuestionType {
  multipleChoice,
  trueFalse,
  multipleAnswer,
}

class Question {
  final String id;
  final String questionText;
  final QuestionType type;
  final List<String> options;
  final dynamic correctAnswer; // String for single, List<String> for multiple

  Question({
    required this.id,
    required this.questionText,
    required this.type,
    required this.options,
    required this.correctAnswer,
  });

  factory Question.fromFirestore(Map<String, dynamic> data, String id) {
    QuestionType type;
    switch (data['type']) {
      case 'trueFalse':
        type = QuestionType.trueFalse;
        break;
      case 'multipleAnswer':
        type = QuestionType.multipleAnswer;
        break;
      default:
        type = QuestionType.multipleChoice;
    }

    return Question(
      id: id,
      questionText: data['questionText'],
      type: type,
      options: List<String>.from(data['options']),
      correctAnswer: data['correctAnswer'],
    );
  }

  Map<String, dynamic> toFirestore() {
    String typeString;
    switch (type) {
      case QuestionType.trueFalse:
        typeString = 'trueFalse';
        break;
      case QuestionType.multipleAnswer:
        typeString = 'multipleAnswer';
        break;
      default:
        typeString = 'multipleChoice';
    }

    return {
      'questionText': questionText,
      'type': typeString,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }

  bool checkAnswer(dynamic userAnswer) {
    if (type == QuestionType.multipleAnswer) {
      List<String> correct = List<String>.from(correctAnswer);
      List<String> user = List<String>.from(userAnswer);
      
      if (correct.length != user.length) return false;
      
      correct.sort();
      user.sort();
      
      for (int i = 0; i < correct.length; i++) {
        if (correct[i] != user[i]) return false;
      }
      return true;
    } else {
      return userAnswer == correctAnswer;
    }
  }
}