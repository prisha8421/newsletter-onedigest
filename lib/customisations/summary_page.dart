import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  String selectedDepth = 'Brief Summary';

  final List<String> summaryOptions = [
    'Brief Summary',
    'Medium Length',
    'In-depth Article',
  ];

  @override
  void initState() {
    super.initState();
    _loadSummaryPreference();
  }

  Future<void> _loadSummaryPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final prefs = userDoc.data()?['preferences'] ?? {};
    final savedDepth = prefs['summaryDepth'];

    if (savedDepth != null && summaryOptions.contains(savedDepth)) {
      setState(() {
        selectedDepth = savedDepth;
      });
    } else {
      // Set and save default if none exists
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'preferences': {'summaryDepth': 'Brief Summary'}
      }, SetOptions(merge: true));
    }
  }

  Future<void> saveSummaryPreference() async {
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
          'summaryDepth': selectedDepth,
        }
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved preference: $selectedDepth')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preference: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary Customisation'),
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
              'Choose your preferred content depth:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3F3986),
              ),
            ),
            const SizedBox(height: 24),
            for (String option in summaryOptions)
              ListTile(
                title: Text(option),
                leading: Radio<String>(
                  value: option,
                  groupValue: selectedDepth,
                  onChanged: (value) {
                    setState(() {
                      selectedDepth = value!;
                    });
                  },
                ),
              ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: saveSummaryPreference,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F3986),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Save Preference',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
