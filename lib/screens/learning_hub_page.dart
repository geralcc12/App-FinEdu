import 'package:flutter/material.dart';
import '../data/learning_data.dart';
import 'learning_topic_detail_page.dart';

class LearningHubPage extends StatelessWidget {
  const LearningHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Aprendizaje'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aprende a tu Ritmo',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: learningTopics.length,
                itemBuilder: (context, index) {
                  final topic = learningTopics[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: const Color(0xFF2C2C2C), // Fondo oscuro para la tarjeta
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        topic.icon,
                        color: Colors.white70, // Icono más claro
                        size: 40,
                      ),
                      title: Text(
                        topic.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Texto del título en blanco
                        ),
                      ),
                      subtitle: Text(
                        'Toca para aprender más',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7), // Subtítulo más sutil
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LearningTopicDetailPage(topic: topic),
                          ),
                        );
                      },
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