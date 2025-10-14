import 'package:aplicaciones_moviles/data/achievements_data.dart';
import 'package:aplicaciones_moviles/models/achievement.dart';
import 'package:aplicaciones_moviles/services/achievement_service.dart';
import 'package:aplicaciones_moviles/widgets/achievement_item.dart';
import 'package:flutter/material.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final AchievementService _achievementService = AchievementService();
  late Future<Set<String>> _unlockedAchievementIdsFuture;

  @override
  void initState() {
    super.initState();
    _unlockedAchievementIdsFuture = _achievementService.getUnlockedAchievementIds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Logros'),
        backgroundColor: Colors.amber, // A fun color for achievements
      ),
      body: FutureBuilder<Set<String>>(
        future: _unlockedAchievementIdsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar los logros: ${snapshot.error}'));
          }

          final unlockedIds = snapshot.data ?? {};

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: allAchievements.length,
            itemBuilder: (context, index) {
              final achievement = allAchievements[index];
              final isUnlocked = unlockedIds.contains(achievement.id);

              return AchievementItem(
                achievement: achievement,
                isUnlocked: isUnlocked,
              );
            },
          );
        },
      ),
    );
  }
}
