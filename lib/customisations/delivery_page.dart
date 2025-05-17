import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeliverySettingsPage extends StatefulWidget {
  const DeliverySettingsPage({super.key});

  @override
  State<DeliverySettingsPage> createState() => _DeliverySettingsPageState();
}

class _DeliverySettingsPageState extends State<DeliverySettingsPage> {
  final Set<String> selectedChannels = {};

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final prefs = userDoc.data()?['preferences'] ?? {};
    final channels = prefs['channels'];

    if (channels is List && channels.isNotEmpty) {
      selectedChannels.addAll(channels.map((e) => e.toString()));
    } else {
      // Set default as 'Email'
      selectedChannels.add('Email');
      // Save default to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'preferences': {'channels': ['Email']}
      }, SetOptions(merge: true));
    }

    setState(() {});
  }

  void toggleChannel(String channel) {
    setState(() {
      if (selectedChannels.contains(channel)) {
        selectedChannels.remove(channel);
      } else {
        selectedChannels.add(channel);
      }
    });
  }

  Future<void> saveSettings() async {
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
          'channels': selectedChannels.toList(),
        }
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Settings'),
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
            const Text('Delivery Channels:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Wrap(
              spacing: 10,
              children: ['Email', 'Push'].map((channel) {
                final isSelected = selectedChannels.contains(channel);
                return FilterChip(
                  label: Text(channel),
                  selected: isSelected,
                  selectedColor: const Color(0xFF3F3986),
                  onSelected: (_) => toggleChannel(channel),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF3F3986),
                  ),
                  backgroundColor: const Color(0xFFE8E6FB),
                );
              }).toList(),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F3986),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Save Settings'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
