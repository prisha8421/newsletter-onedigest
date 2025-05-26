import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_newsletter/services/pdf_service.dart';
import 'package:new_newsletter/services/email_service.dart';

class SchedulerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PDFService _pdfService = PDFService();
  final EmailService _emailService = EmailService();
  Timer? _schedulerTimer;

  Future<void> startScheduler() async {
    // Cancel any existing timer
    _schedulerTimer?.cancel();

    // Get user preferences
    final userDoc = await _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .get();

    final preferences = userDoc.data()?['preferences'] ?? {};
    final deliveryTime = preferences['deliveryTime'] ?? '09:00'; // Default to 9 AM

    // Calculate time until next delivery
    final now = DateTime.now();
    final deliveryDateTime = _parseDeliveryTime(deliveryTime);
    final timeUntilDelivery = _calculateTimeUntilDelivery(now, deliveryDateTime);

    // Schedule the next delivery
    _schedulerTimer = Timer(timeUntilDelivery, () async {
      await sendScheduledNewsletter();
      // Schedule the next delivery
      startScheduler();
    });
  }

  Future<void> sendScheduledNewsletter() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user's email preferences
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      final emailAddress = user.email; // Use the authenticated user's email
      if (emailAddress == null) {
        throw Exception('No email address available for the user');
      }

      // Get articles since last delivery
      final lastDelivery = await _getLastDeliveryTime();
      final articles = await _getArticlesSinceLastDelivery(lastDelivery);

      if (articles.isEmpty) {
        throw Exception('No new articles to send');
      }

      // Generate PDF
      final pdfFile = await _pdfService.generateNewsletterPDF(articles);

      // Send email
      await _emailService.sendNewsletterEmail(pdfFile, emailAddress);

      // Update last delivery time
      await _updateLastDeliveryTime();
    } catch (e) {
      print('Error sending scheduled newsletter: $e');
      rethrow; // Rethrow to handle in the UI
    }
  }

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

  Duration _calculateTimeUntilDelivery(DateTime now, DateTime deliveryTime) {
    var timeUntilDelivery = deliveryTime.difference(now);
    if (timeUntilDelivery.isNegative) {
      // If delivery time has passed today, schedule for tomorrow
      timeUntilDelivery = timeUntilDelivery + const Duration(days: 1);
    }
    return timeUntilDelivery;
  }

  Future<DateTime?> _getLastDeliveryTime() async {
    final userDoc = await _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .get();
    final lastDelivery = userDoc.data()?['lastDelivery'];
    return lastDelivery?.toDate();
  }

  Future<void> _updateLastDeliveryTime() async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .update({
      'lastDelivery': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> _getArticlesSinceLastDelivery(
      DateTime? lastDelivery) async {
    // For now, return some dummy articles for testing
    return [
      {
        'title': 'Test Article 1',
        'description': 'This is a test article for the newsletter.',
        'url': 'https://example.com/article1',
      },
      {
        'title': 'Test Article 2',
        'description': 'Another test article for the newsletter.',
        'url': 'https://example.com/article2',
      },
    ];
  }

  void dispose() {
    _schedulerTimer?.cancel();
  }
} 