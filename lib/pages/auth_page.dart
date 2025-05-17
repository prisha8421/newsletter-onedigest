import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../database/user_details.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void toggleForm() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E6FB),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                isLogin ? 'Welcome Back 👋' : 'Create an Account ✨',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3F3986),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isLogin
                    ? 'Login to continue enjoying your personalized digests.'
                    : 'Sign up to start curating your perfect newsletter experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF3F3986).withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();

                  if (email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter both email and password.'),
                      ),
                    );
                    return;
                  }

                  try {
                    if (isLogin) {
                      final userCredential = await FirebaseAuth.instance
                          .signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      final user = userCredential.user;
                      if (user != null) {
                        await UserDetails.getUserPreferences(user.uid);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login successful!')),
                      );
                    } else {
                      final userCredential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      final user = userCredential.user;
                      if (user != null) {
                        await UserDetails.saveUserData(user);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account created successfully!'),
                        ),
                      );
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F3986),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  isLogin ? 'Login' : 'Sign Up',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: toggleForm,
                child: Text(
                  isLogin
                      ? "Don't have an account? Sign Up"
                      : "Already have an account? Login",
                  style: const TextStyle(
                    color: Color(0xFF3F3986),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
                child: const Text(
                  '← Back to Home',
                  style: TextStyle(
                    color: Color(0xFF3F3986),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD0CFF5).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        cursorColor: const Color(0xFF3F3986),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
          border: InputBorder.none,
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF3F3986), fontSize: 16),
          prefixIcon: Icon(icon, color: Color(0xFF3F3986)),
        ),
      ),
    );
  }
}
