import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDetails {
  
  static Future<void> saveUserData(User user, String nickname) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await userDoc.set({
      'nickname': nickname,
      'email': user.email,
      'joinedAt': FieldValue.serverTimestamp(),
   
      'preferences': {
        'topics': [],
        'delivery': 'daily',
        'language': 'en',
        'tone': 'Casual',
        'format': 'Bullet Points',
        'summaryDepth': 'Brief Summary',
      },
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getUserPreferences(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['preferences'];
  }

  static Future<void> updateUserPreferences(
      String uid, Map<String, dynamic> newPreferences) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    await userDoc.set({
      'preferences': newPreferences,
    }, SetOptions(merge: true));
  }
}
