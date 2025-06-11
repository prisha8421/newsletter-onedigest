import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../database/user_details.dart';

class ToneFormatPage extends StatefulWidget {
  const ToneFormatPage({super.key});

  @override
  State<ToneFormatPage> createState() => _ToneFormatPageState();
}

class _ToneFormatPageState extends State<ToneFormatPage> {
  String selectedTone = 'Casual';
  String selectedFormat = 'Bullet Points';
  bool showSaveAnimation = false;

  final List<String> toneOptions = [
    'Casual',
    'Professional',
    'Humorous',
    'Simple',
    'Formal',
    'Friendly',
  ];
  final List<String> formatOptions = [
    'Bullet Points',
    'Paragraph',
    'Brief Highlights',
  ];

  @override
  void initState() {
    super.initState();
    _loadToneAndFormat();
  }

  Future<void> _loadToneAndFormat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final prefs = userDoc.data()?['preferences'] ?? {};

    final tone = prefs['tone'];
    final format = prefs['format'];

    setState(() {
      if (tone != null && toneOptions.contains(tone)) {
        selectedTone = tone;
      }
      if (format != null && formatOptions.contains(format)) {
        selectedFormat = format;
      }
    });

    // If any of the preferences were missing, set defaults
    if (tone == null || format == null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': {'tone': selectedTone, 'format': selectedFormat},
      }, SetOptions(merge: true));
    }
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': {
          'tone': selectedTone,
          'format': selectedFormat,
        }
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        showSaveAnimation = true;
      });

      // Hide the save animation after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            showSaveAnimation = false;
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preferences: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Tone & Format',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose how you want your news to be presented.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tone Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Tone',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: toneOptions.map((tone) {
                          final isSelected = selectedTone == tone;
                          return _OptionCard(
                            text: tone,
                            isSelected: isSelected,
                            onTap: () => setState(() => selectedTone = tone),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Format Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Format',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: formatOptions.map((format) {
                          final isSelected = selectedFormat == format;
                          return _OptionCard(
                            text: format,
                            isSelected: isSelected,
                            onTap: () => setState(() => selectedFormat = format),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Save Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40.0,
            left: 16.0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Save Success Animation Overlay
          if (showSaveAnimation)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Lottie.asset(
                  'assets/icon/done.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8981DF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
