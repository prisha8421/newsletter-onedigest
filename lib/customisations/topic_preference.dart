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
    'Updated',
    'Politics',
    'Technology',
    'Sports',
    'International',
    'Media',
    'Education',
    'Science',
    'Finance',
  ];

  final Map<String, IconData> topicIcons = {
    'Updated': Icons.description,
    'Politics': Icons.gavel,
    'Technology': Icons.lightbulb,
    'Sports': Icons.sports_basketball,
    'International': Icons.public,
    'Media': Icons.movie,
    'Education': Icons.school,
    'Science': Icons.science,
    'Finance': Icons.attach_money,
  };

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
                        'Select Categories',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose your interests here and get the best news recommendations.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Categories Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    children: allTopics.map((topic) {
                      final isSelected = selectedTopics.contains(topic);
                      return _CategoryCard(
                        topic: topic,
                        icon: topicIcons[topic]!,
                        isSelected: isSelected,
                        onTap: () => toggleTopic(topic),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30),
                // Continue Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: savePreferences,
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
            top: 40.0, // Adjust as needed to align with the top of the phone's safe area
            left: 16.0, // Standard left padding
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String topic;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    Key? key,
    required this.topic,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8981DF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 10),
            Text(
              topic,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
