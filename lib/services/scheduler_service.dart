import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/pdf_service.dart';
import '../services/email_service.dart';
import '../services/personalised_news_service.dart';
import '../services/customised_article.dart'; // Add this line

class SchedulerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EmailService _emailService = EmailService();

  late final CustomizedArticleService _customizedService;

  Timer? _schedulerTimer;

  SchedulerService() {
    final newsService = PersonalizedNewsService();
    final pdfService = PDFService();
    const aiServiceUrl = 'https://api.openai.com/v1/chat/completions'; // ✅ Replace with your actual endpoint

    _customizedService = CustomizedArticleService(
      newsService: newsService,
      pdfService: pdfService,
    );
  }

  /// Update delivery time and restart scheduler
  Future<void> updateDeliveryTime(String newDeliveryTime) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Update the delivery time in Firestore
    await _firestore.collection('users').doc(user.uid).update({
      'preferences.deliveryTime': newDeliveryTime,
    });

    // Restart the scheduler with the new time
    await startScheduler();
  }

  /// Start the scheduler for the current user
  Future<void> startScheduler() async {
    _schedulerTimer?.cancel();

    final user = _auth.currentUser;
    if (user == null) {
      print('No authenticated user, scheduler will not start.');
      return;
    }

    // Get user preferences
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final preferences = userDoc.data()?['preferences'] ?? {};
    final deliveryTime = preferences['deliveryTime'] ?? '12:43';

    final now = DateTime.now();
    final deliveryDateTime = _parseDeliveryTime(deliveryTime);
    final timeUntilDelivery = _calculateTimeUntilDelivery(now, deliveryDateTime);

    print('📆 Scheduling newsletter delivery in $timeUntilDelivery');

    _schedulerTimer = Timer(timeUntilDelivery, () async {
      try {
        await sendScheduledNewsletter();
      } catch (e) {
        print('❌ Error in scheduled newsletter: $e');
      }
      // Reschedule after sending
      await startScheduler();
    });
  }

  /// Send the scheduled newsletter
  Future<void> sendScheduledNewsletter() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final emailAddress =
        userDoc.data()?['preferences']?['emailAddress'] ?? user.email;

    if (emailAddress == null) {
      throw Exception('No email address available for the user');
    }

    print('📰 Generating customized newsletter for ${user.email}');

    final File? pdfFile =
        await _customizedService.generateCustomizedNewsletter(user.uid);

    if (pdfFile == null) {
      print('❌ Failed to generate customized newsletter PDF');
      return;
    }

    await _emailService.sendNewsletterEmail(pdfFile, emailAddress);
    await _updateLastDeliveryTime();
  }

  /// Parse delivery time string (e.g. "09:30")
  DateTime _parseDeliveryTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Calculate delay until next delivery time
  Duration _calculateTimeUntilDelivery(DateTime now, DateTime deliveryTime) {
    var duration = deliveryTime.difference(now);
    if (duration.isNegative) {
      duration += const Duration(days: 1);
    }
    return duration;
  }

  /// Save last delivery timestamp to Firestore
  Future<void> _updateLastDeliveryTime() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'lastDelivery': FieldValue.serverTimestamp(),
    });
  }

  /// Stop the scheduler
  void dispose() {
    _schedulerTimer?.cancel();
  }
}
