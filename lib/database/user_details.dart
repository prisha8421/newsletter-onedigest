import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDetails {
 static Future<void> saveUserData(User user, String nickname) async {
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

  await userDoc.set({
    'name': nickname,
    'email': user.email,
    'joinedAt': FieldValue.serverTimestamp(),
    'preferences': {
      'topics': [],
      'delivery': 'daily',
      'language': 'en',
    },
  }, SetOptions(merge: true));
}

  

  static Future<Map<String, dynamic>?> getUserPreferences(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['preferences'];
  }
}
