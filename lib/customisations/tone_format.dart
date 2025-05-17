import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ToneFormatPage extends StatefulWidget {
  const ToneFormatPage({super.key});

  @override
  State<ToneFormatPage> createState() => _ToneFormatPageState();
}

class _ToneFormatPageState extends State<ToneFormatPage> {
  String selectedTone = 'Casual';
  String selectedFormat = 'Bullet Points';

  final List<String> toneOptions = ['Casual', 'Formal', 'Friendly', 'Professional'];
  final List<String> formatOptions = ['Bullet Points', 'Paragraph', 'Brief Highlights'];

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
        'preferences': {
          'tone': selectedTone,
          'format': selectedFormat,
        }
      }, SetOptions(merge: true));
    }
  }

  Future<void> saveToneAndFormat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await userDoc.set({
        'preferences': {
          'tone': selectedTone,
          'format': selectedFormat,
        }
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: $selectedTone tone, $selectedFormat format')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preferences: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tone & Format'),
        backgroundColor: const Color(0xFF8981DF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your preferred tone:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3F3986)),
            ),
            const SizedBox(height: 16),
            for (String tone in toneOptions)
              RadioListTile<String>(
                title: Text(tone),
                value: tone,
                groupValue: selectedTone,
                activeColor: const Color(0xFF3F3986),
                onChanged: (value) => setState(() => selectedTone = value!),
              ),
            const SizedBox(height: 24),
            const Text(
              'Choose your preferred format:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3F3986)),
            ),
            const SizedBox(height: 16),
            for (String format in formatOptions)
              RadioListTile<String>(
                title: Text(format),
                value: format,
                groupValue: selectedFormat,
                activeColor: const Color(0xFF3F3986),
                onChanged: (value) => setState(() => selectedFormat = value!),
              ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: saveToneAndFormat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F3986),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Save Preferences',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
