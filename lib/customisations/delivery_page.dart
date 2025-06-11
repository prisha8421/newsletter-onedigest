import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import '../services/scheduler_service.dart';

class DeliverySettingsPage extends StatefulWidget {
  const DeliverySettingsPage({super.key});

  @override
  State<DeliverySettingsPage> createState() => _DeliverySettingsPageState();
}

class _DeliverySettingsPageState extends State<DeliverySettingsPage> {
  String selectedDelivery = 'email';
  bool isSending = false;
  bool showSuccessAnimation = false;
  bool showSaveAnimation = false;
  final Set<String> selectedChannels = {};
  User? user;
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool isEmailEnabled = true;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadUserSettings();
    _loadDeliveryPreference();
  }

  Future<void> _loadUserSettings() async {
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
    final prefs = userDoc.data()?['preferences'] ?? {};
    final channels = prefs['channels'];
    final deliveryTime = prefs['deliveryTime'] ?? '09:00';
    final emailEnabled = prefs['emailEnabled'] ?? true;

    setState(() {
      isEmailEnabled = emailEnabled;
    });

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
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'email': user!.email,
        'preferences': {
          'channels': ['Email'],
          'deliveryTime': '09:00',
          'emailEnabled': true,
        },
      }, SetOptions(merge: true));
    }

    setState(() {});
  }

  Future<void> _loadDeliveryPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final prefs = userDoc.data()?['preferences'] ?? {};
    final delivery = prefs['delivery'];

    setState(() {
      if (delivery != null) {
        selectedDelivery = delivery;
      }
    });

    // If delivery preference is missing, set default
    if (delivery == null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': {'delivery': selectedDelivery},
      }, SetOptions(merge: true));
    }
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
    setState(() => isSending = true);
    try {
      final schedulerService = SchedulerService();
      await schedulerService.sendScheduledNewsletter();

      if (!mounted) return;
      setState(() {
        isSending = false;
        showSuccessAnimation = true;
      });

      // Hide the success animation after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            showSuccessAnimation = false;
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending newsletter: $e')));
    }
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final timeString =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

      // Update delivery time in scheduler
      final schedulerService = SchedulerService();
      await schedulerService.updateDeliveryTime(timeString);

      // Save other preferences
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': {
          'delivery': selectedDelivery,
          'channels': selectedChannels.toList(),
          'emailEnabled': isEmailEnabled,
        },
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        showSaveAnimation = true;
      });

      // Hide the save animation after 2 seconds and then navigate back
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            showSaveAnimation = false;
          });
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving delivery preference: $e')),
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
                        'Delivery Settings',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose how you want to receive your news updates.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Email Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.6),
                                  ],
                                ),
                              ),
                              child: _NotificationToggle(
                                title: 'Email',
                                subtitle: 'Receive updates via email',
                                value: isEmailEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    isEmailEnabled = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Delivery Time Selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Time',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daily at',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _selectTime,
                              icon: const Icon(
                                Icons.access_time,
                                color: Color(0xFF8981DF),
                              ),
                              label: Text(
                                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Color(0xFF8981DF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Send Now Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSending ? null : sendImmediateNewsletter,
                      icon:
                          isSending
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        isSending ? 'Sending...' : 'Send Newsletter Now',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8981DF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Save Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF8981DF)),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Color(0xFF8981DF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          // Success Animation Overlay for Newsletter
          if (showSuccessAnimation)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Lottie.asset(
                  'assets/icon/mail_sent2.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
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

class _NotificationToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: value ? const Color(0xFFF5F3FF) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF8981DF),
            ),
          ],
        ),
      ),
    );
  }
}
