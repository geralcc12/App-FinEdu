import 'package:flutter/material.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class LearningTopic {
  final String id;
  final String title;
  final String content;
  final IconData icon;
  final List<QuizQuestion> quiz;

  LearningTopic({
    required this.id,
    required this.title,
    required this.content,
    required this.icon,
    this.quiz = const [],
  });
}
