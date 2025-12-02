// screens/quiz_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/questions.dart';
import '../models/quiz_result.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  
  Timer? _timer;
  int _secondsRemaining = 60;
  
  dynamic _selectedAnswer;
  List<String> _selectedMultipleAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('questions').get();
      
      List<Question> allQuestions = snapshot.docs
          .map((doc) => Question.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
      
      allQuestions.shuffle();
      
      setState(() {
        _questions = allQuestions.take(10).toList();
        _isLoading = false;
      });
      
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: ${e.toString()}')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timeOut();
        }
      });
    });
  }

  void _timeOut() {
    _timer?.cancel();
    _saveResultAndNavigate(timedOut: true);
  }

  Future<void> _saveResultAndNavigate({required bool timedOut}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    QuizResult result = QuizResult(
      userId: user.uid,
      score: timedOut ? 0 : _score,
      totalQuestions: 10,
      completedAt: DateTime.now(),
      timedOut: timedOut,
    );

    try {
      await _firestore.collection('quiz_results').add(result.toFirestore());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving result: ${e.toString()}')),
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            score: timedOut ? 0 : _score,
            totalQuestions: 10,
            timedOut: timedOut,
          ),
        ),
      );
    }
  }

  void _submitAnswer() {
    if (_selectedAnswer == null && _selectedMultipleAnswers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer')),
      );
      return;
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    bool isCorrect;

    if (currentQuestion.type == QuestionType.multipleAnswer) {
      isCorrect = currentQuestion.checkAnswer(_selectedMultipleAnswers);
    } else {
      isCorrect = currentQuestion.checkAnswer(_selectedAnswer);
    }

    if (isCorrect) {
      _score++;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _selectedMultipleAnswers = [];
      });
    } else {
      _timer?.cancel();
      _saveResultAndNavigate(timedOut: false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildQuestionWidget() {
    if (_questions.isEmpty) return const SizedBox.shrink();

    final question = _questions[_currentQuestionIndex];

    switch (question.type) {
      case QuestionType.trueFalse:
        return _buildTrueFalseQuestion(question);
      case QuestionType.multipleAnswer:
        return _buildMultipleAnswerQuestion(question);
      default:
        return _buildMultipleChoiceQuestion(question);
    }
  }

  Widget _buildMultipleChoiceQuestion(Question question) {
    return Column(
      children: question.options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedAnswer = option;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedAnswer == option
                    ? Colors.blue.shade100
                    : Colors.white,
                border: Border.all(
                  color: _selectedAnswer == option
                      ? Colors.blue
                      : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _selectedAnswer == option
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseQuestion(Question question) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedAnswer = 'True';
              });
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _selectedAnswer == 'True'
                    ? Colors.green.shade100
                    : Colors.white,
                border: Border.all(
                  color: _selectedAnswer == 'True'
                      ? Colors.green
                      : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: _selectedAnswer == 'True'
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'True',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: _selectedAnswer == 'True'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedAnswer = 'False';
              });
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _selectedAnswer == 'False'
                    ? Colors.red.shade100
                    : Colors.white,
                border: Border.all(
                  color: _selectedAnswer == 'False'
                      ? Colors.red
                      : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cancel,
                    size: 48,
                    color: _selectedAnswer == 'False'
                        ? Colors.red
                        : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'False',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: _selectedAnswer == 'False'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultipleAnswerQuestion(Question question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text(
            'Select all that apply:',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
        ...question.options.map((option) {
          final isSelected = _selectedMultipleAnswers.contains(option);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedMultipleAnswers.remove(option);
                  } else {
                    _selectedMultipleAnswers.add(option);
                  }
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade100 : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(
          child: Text('No questions available'),
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentQuestionIndex + 1}/10'),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _secondsRemaining <= 10
                    ? Colors.red.shade100
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: _secondsRemaining <= 10 ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_secondsRemaining s',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          _secondsRemaining <= 10 ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    question.questionText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildQuestionWidget(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    _currentQuestionIndex < _questions.length - 1
                        ? 'Next Question'
                        : 'Finish Quiz',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}