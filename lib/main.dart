import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../pages/auth_page.dart';
import '../pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const OneDigestApp());
}

class OneDigestApp extends StatelessWidget {
  const OneDigestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneDigest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamilyFallback: [
          'NotoSans', // Ensure this matches the font family defined in pubspec.yaml
        ],
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData) {
            return const AuthPage(); // User is not logged in
          }

          return const HomePage(); // User is logged in
        },
      ),
    );
  }
}
