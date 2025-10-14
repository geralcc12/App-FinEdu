import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Otorga un logro a un usuario si aún no lo tiene.
  Future<void> awardAchievement(String achievementId) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final DocumentReference achievementDoc = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('achievements')
        .doc(achievementId);

    final DocumentSnapshot snapshot = await achievementDoc.get();

    // Si el logro no existe, lo creamos.
    if (!snapshot.exists) {
      await achievementDoc.set({
        'id': achievementId,
        'awardedAt': Timestamp.now(),
      });
    }
  }

  // Obtiene la lista de IDs de los logros que un usuario ha ganado.
  Future<Set<String>> getUnlockedAchievementIds() async {
    final User? user = _auth.currentUser;
    if (user == null) return {};

    final QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('achievements')
        .get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }
}
