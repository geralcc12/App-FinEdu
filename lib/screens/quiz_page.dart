import 'package:flutter/material.dart';
import '../models/learning_topic.dart';

class QuizPage extends StatefulWidget {
  final LearningTopic topic;

  const QuizPage({Key? key, required this.topic}) : super(key: key);

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentQuestionIndex = 0;
  int _score = 0;

  void _answerQuestion(int selectedOptionIndex) {
    if (selectedOptionIndex == widget.topic.quiz[_currentQuestionIndex].correctAnswerIndex) {
      _score++;
    }

    setState(() {
      if (_currentQuestionIndex < widget.topic.quiz.length - 1) {
        _currentQuestionIndex++;
      } else {
        // Quiz finished, show results
        _showResultDialog();
      }
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¡Quiz Terminado!'),
        content: Text('Tu puntuación es: $_score / ${widget.topic.quiz.length}'),
        actions: <Widget>[
          TextButton(
            child: Text('Reintentar'),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _currentQuestionIndex = 0;
                _score = 0;
              });
            },
          ),
          TextButton(
            child: Text('Cerrar'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Go back to the topic detail page
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.topic.quiz[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.topic.title}'),
        backgroundColor: const Color(0xFF1C1C1E), // Dark background
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121212), // Even darker background
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pregunta ${_currentQuestionIndex + 1}/${widget.topic.quiz.length}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Text(
                currentQuestion.question,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22.0),
              ),
            ),
            const SizedBox(height: 30),
            ...currentQuestion.options.asMap().entries.map((entry) {
              int idx = entry.key;
              String text = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: ElevatedButton(
                  onPressed: () => _answerQuestion(idx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333), // Dark buttons
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(text, style: TextStyle(fontSize: 18)),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
