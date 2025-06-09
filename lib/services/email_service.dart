import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import '../secrets.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SendGrid SMTP configuration
  static const String _smtpServer = 'smtp.sendgrid.net';
  static const int _smtpPort = 587;
  static const bool _smtpSsl = false;
  static const String _senderEmail = 'onedigest@gmail.com';
  static final String _apiKey = Secrets.emailApiKey;


  Future<void> sendNewsletterEmail(File pdfFile, String? recipientEmail) async {
    print("📤 Preparing to send email...");

    final email = recipientEmail ?? _auth.currentUser?.email;
    if (email == null) {
      print("❌ No recipient email found.");
      throw Exception('No recipient email available');
    }

    final message = Message()
      ..from = Address(_senderEmail, 'OneDigest Newsletter')
      ..recipients.add(email)
      ..subject = 'Your Daily Newsletter - ${DateTime.now().toString().split(' ')[0]}'
      ..text = 'Please find attached your personalized daily newsletter.'
      ..attachments = [
        FileAttachment(pdfFile)
          ..location = Location.attachment
          ..cid = '<newsletter>'
      ];

    final smtpServer = SmtpServer(
      _smtpServer,
      port: _smtpPort,
      username: 'apikey',
      password: _apiKey,
      ssl: _smtpSsl,
    );

    try {
      print("📧 Sending email to $email via SendGrid...");
      final sendReport = await send(message, smtpServer);
      print("✅ Email sent successfully: ${sendReport.toString()}");
    } catch (e) {
      print("❌ Failed to send email: $e");
      rethrow;
    }
  }

  Future<void> updateEmailPreferences({
    required String deliveryTime,
    required String emailAddress,
  }) async {
    print("🛠️ Updating email preferences in Firestore...");

    final user = _auth.currentUser;
    if (user == null) {
      print("❌ No authenticated user.");
      throw Exception('User not authenticated');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'preferences': {
        'deliveryTime': deliveryTime,
        'emailAddress': emailAddress,
      },
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print("✅ Email preferences updated for user: ${user.uid}");
  }
}
