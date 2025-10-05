import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/learning_topic.dart';
import '../screens/quiz_page.dart';

class LearningTopicDetailPage extends StatelessWidget {
  final LearningTopic topic;

  const LearningTopicDetailPage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      appBar: AppBar(
        title: Text(topic.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Using MarkdownStyleSheet to force text colors to be light
            MarkdownBody(
              data: topic.content,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  color: Color(0xFFE0E0E0), // Light gray for paragraphs
                  fontSize: 16,
                  height: 1.5,
                ),
                h1: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                h2: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                h3: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.8,
                ),
                listBullet: const TextStyle(color: Color(0xFFE0E0E0)),
                strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            if (topic.quiz.isNotEmpty)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.videogame_asset_rounded),
                  label: const Text('¡Ponte a prueba!'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.amber.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizPage(topic: topic),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
