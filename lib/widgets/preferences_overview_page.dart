import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../customisations/summary_page.dart';
import '../customisations/language_page.dart';
import '../customisations/delivery_page.dart';
import '../customisations/tone_format.dart';
import '../customisations/topic_preference.dart';
import '../pages/home_page.dart';

class PreferencesOverviewPage extends StatefulWidget {
  const PreferencesOverviewPage({super.key});

  @override
  State<PreferencesOverviewPage> createState() => _PreferencesOverviewPageState();
}

class _PreferencesOverviewPageState extends State<PreferencesOverviewPage> {
  Map<String, dynamic> preferences = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        preferences = userDoc.data()?['preferences'] ?? {};
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading preferences: $e')));
    }
  }

  String _getSummaryDepthLabel(String? value) {
    const options = ['Brief Summary', 'Medium Length', 'In-depth Article'];
    return options.contains(value) ? value! : 'Brief Summary';
  }

  String _getLanguageLabel(String? code) {
    const languageMap = {
      'en': 'English', 'hi': 'Hindi', 'es': 'Spanish', 'fr': 'French',
      'de': 'German', 'zh': 'Chinese', 'ja': 'Japanese', 'ar': 'Arabic', 'pt': 'Portuguese'
    };
    return languageMap[code] ?? 'English';
  }

  String _getToneFormatLabel(String? value) {
    const options = {'formal': 'Formal', 'casual': 'Casual', 'professional': 'Professional'};
    return options[value] ?? 'Default';
  }

  String _getDeliverySettingsLabel(String? value) {
    const options = {'email': 'Email', 'push': 'Push Notification', 'sms': 'SMS'};
    return options[value] ?? 'Default';
  }

  String _getTopicsLabel(dynamic value) {
    return (value is List && value.isNotEmpty) ? value.join(', ') : 'No topics selected';
  }

  void _navigateTo(Widget targetPage) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage));
    await _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Preferences'),
        backgroundColor: const Color(0xFF8981DF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text('Topics & Preferences'),
              subtitle: Text(_getTopicsLabel(preferences['topics'])),
              trailing: ElevatedButton(
                onPressed: () => _navigateTo(const TopicPreferencePage()),
                child: const Text('Change'),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Summary Depth'),
              subtitle: Text(_getSummaryDepthLabel(preferences['summaryDepth'])),
              trailing: ElevatedButton(
                onPressed: () => _navigateTo(const SummaryPage()),
                child: const Text('Change'),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Tone & Format'),
              subtitle: Text(_getToneFormatLabel(preferences['toneFormat'])),
              trailing: ElevatedButton(
                onPressed: () => _navigateTo(const ToneFormatPage()),
                child: const Text('Change'),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Language'),
              subtitle: Text(_getLanguageLabel(preferences['language'])),
              trailing: ElevatedButton(
                onPressed: () => _navigateTo(const LanguagePage()),
                child: const Text('Change'),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Delivery Settings'),
              subtitle: Text(_getDeliverySettingsLabel(preferences['deliverySettings'])),
              trailing: ElevatedButton(
                onPressed: () => _navigateTo(const DeliverySettingsPage()),
                child: const Text('Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}