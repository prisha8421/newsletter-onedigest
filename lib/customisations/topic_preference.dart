import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopicPreferencePage extends StatefulWidget {
  const TopicPreferencePage({super.key});

  @override
  State<TopicPreferencePage> createState() => _TopicPreferencePageState();
}

class _TopicPreferencePageState extends State<TopicPreferencePage> {
  final List<String> allTopics = [
    'Technology',
    'Health',
    'Finance',
    'Politics',
    'Entertainment',
    'Sports',
    'Science',
    'Travel',
    'Education',
  ];

  final Set<String> selectedTopics = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final prefs = userDoc.data()?['preferences'] ?? {};
    final topics = prefs['topics'];

    if (topics != null && topics is List) {
      setState(() {
        selectedTopics.addAll(topics.cast<String>().where((t) => allTopics.contains(t)));
      });
    } else {
      // If no preferences found, set default (e.g., 'Technology') and update Firestore
      setState(() {
        selectedTopics.add('Technology');
      });
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': {
          'topics': selectedTopics.toList(),
        }
      }, SetOptions(merge: true));
    }
  }

  void toggleTopic(String topic) {
    setState(() {
      if (selectedTopics.contains(topic)) {
        selectedTopics.remove(topic);
      } else {
        selectedTopics.add(topic);
      }
    });
  }

  Future<void> savePreferences() async {
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
          'topics': selectedTopics.toList(),
        }
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferences saved: ${selectedTopics.join(', ')}')),
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
        title: const Text('Choose Your Topics'),
        backgroundColor: const Color(0xFF8981DF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pick topics you’re interested in:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: allTopics.map((topic) {
                final isSelected = selectedTopics.contains(topic);
                return ChoiceChip(
                  label: Text(topic),
                  selected: isSelected,
                  selectedColor: const Color(0xFF3F3986),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF3F3986),
                    fontWeight: FontWeight.w500,
                  ),
                  onSelected: (_) => toggleTopic(topic),
                  backgroundColor: const Color(0xFFE8E6FB),
                );
              }).toList(),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: savePreferences,
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
