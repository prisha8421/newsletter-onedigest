import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/auth_page.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NewsletterApp());
}

class NewsletterApp extends StatelessWidget {
  const NewsletterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneDigest',
      theme: ThemeData(
        primaryColor: const Color(0xFF3F3986),
        scaffoldBackgroundColor: const Color(0xFFF5F5FF),
        fontFamily: 'Sans',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF3F3986)),
        ),
      ),
      home: const AuthWrapper(), // 👈 Controlled by login state
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return const HomePage(); // logged in
        } else {
          return const AuthPage(); // not logged in
        }
      },
    );
  }
}
