import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/scheduler_service.dart';

class DeliverySettingsPage extends StatefulWidget {
  const DeliverySettingsPage({super.key});

  @override
  State<DeliverySettingsPage> createState() => _DeliverySettingsPageState();
}

class _DeliverySettingsPageState extends State<DeliverySettingsPage> {
  final Set<String> selectedChannels = {};
  User? user;
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final prefs = userDoc.data()?['preferences'] ?? {};
    final channels = prefs['channels'];
    final deliveryTime = prefs['deliveryTime'] ?? '09:00';

    // Parse the delivery time
    final timeParts = deliveryTime.split(':');
    selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    if (channels is List && channels.isNotEmpty) {
      selectedChannels.addAll(channels.map((e) => e.toString()));
    } else {
      // Set default as 'Email'
      selectedChannels.add('Email');
      // Save default to Firestore along with email
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'email': user!.email,
        'preferences': {
          'channels': ['Email'],
          'deliveryTime': '09:00',
        }
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3F3986),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF3F3986),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> sendImmediateNewsletter() async {
    if (user == null) return;

    setState(() {
      isSending = true;
    });

    try {
      final schedulerService = SchedulerService();
      await schedulerService.sendScheduledNewsletter();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Newsletter sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending newsletter: $e')),
      );
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  Future<void> saveSettings() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

    try {
      await userDoc.set({
        'email': user!.email,
        'preferences': {
          'channels': selectedChannels.toList(),
          'deliveryTime': timeString,
        }
      }, SetOptions(merge: true));

      // Restart the scheduler with new time
      final schedulerService = SchedulerService();
      await schedulerService.startScheduler();

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
            const SizedBox(height: 24),
            const Text('Delivery Time:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF3F3986)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF3F3986)),
                    const SizedBox(width: 8),
                    Text(
                      selectedTime.format(context),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF3F3986),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isSending ? null : sendImmediateNewsletter,
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(isSending ? 'Sending...' : 'Send Newsletter Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F3986),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
