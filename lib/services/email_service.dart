import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SendGrid SMTP configuration
  static const String _smtpServer = 'smtp.sendgrid.net';
  static const int _smtpPort = 587;  // SendGrid requires port 587 for TLS
  static const bool _smtpSsl = false; // SendGrid uses STARTTLS, not SSL
  static const String _senderEmail = 'onedigest@gmail.com';
  static const String _apiKey = '{API_KEY}'; // Your SendGrid API Key

  Future<void> sendNewsletterEmail(File pdfFile, String recipientEmail) async {
    print('\n=== Email Sending Details ===');
    print('From: $_senderEmail');
    print('Recipient email parameter: $recipientEmail');
    print('Current user email: ${_auth.currentUser?.email}');
    
    final email = recipientEmail ?? _auth.currentUser?.email;
    if (email == null) throw Exception('No email address available');

    print('Final recipient email address: $email');
    print('PDF file exists: ${await pdfFile.exists()}');
    print('PDF file size: ${await pdfFile.length()} bytes');
    print('===========================\n');

    // Create email message
    final message = Message()
      ..from = Address(_senderEmail, 'Your Newsletter App')
      ..recipients.add(email)
      ..subject = 'Your Daily Newsletter - ${DateTime.now().toString().split(' ')[0]}'
      ..text = 'Please find attached your daily newsletter.'
      ..attachments = [
        FileAttachment(pdfFile)
          ..location = Location.attachment
          ..cid = '<newsletter>'
      ];

    try {
      print('Configuring SendGrid SMTP server...');
      print('Using SendGrid server: $_smtpServer');
      print('Using sender email: $_senderEmail');
      
      // Configure SendGrid SMTP server
      final smtpServer = SmtpServer(
        _smtpServer,
        port: _smtpPort,
        username: 'apikey', // SendGrid requires 'apikey' as the username
        password: _apiKey,  // Your SendGrid API Key as the password
        ssl: _smtpSsl,
        allowInsecure: false,
      );

      print('Attempting to send email...');
      final sendReport = await send(message, smtpServer);
      
      // Print the complete send report
      print('\n=== Send Report ===');
      print('Status: ${sendReport.toString()}');
      
      // Check if the email was actually sent
      final reportString = sendReport.toString().toLowerCase();
      if (reportString.contains('successfully sent') || reportString.contains('ok')) {
        print('Email was successfully sent via SendGrid');
        print('From: $_senderEmail');
        print('To: $email');
        print('===================\n');
        return; // Successfully sent, exit the function
      }
      
      // If we get here, there might be an issue
      print('Warning: Email might not have been sent successfully');
      print('Full send report: $sendReport');
      print('===================\n');
      
      // SendGrid-specific error handling
      if (reportString.contains('unauthorized')) {
        throw Exception('SendGrid authentication failed. Please check your API key.');
      } else if (reportString.contains('sender not verified')) {
        throw Exception('Sender email not verified in SendGrid. Please verify $_senderEmail in your SendGrid account.');
      } else if (reportString.contains('domain not verified')) {
        throw Exception('Domain not verified in SendGrid. Please verify your domain in SendGrid settings.');
      } else {
        throw Exception('Email was not accepted by SendGrid server: ${sendReport.toString()}');
      }
    } catch (e, stackTrace) {
      print('\n=== Error Details ===');
      print('Error sending email: $e');
      print('Stack trace: $stackTrace');
      print('===================\n');
      
      // SendGrid-specific error messages
      if (e.toString().contains('SocketException')) {
        throw Exception('Could not connect to SendGrid server. Please check your internet connection.');
      } else if (e.toString().contains('authentication')) {
        throw Exception('SendGrid authentication failed. Please verify your API key.');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Connection to SendGrid server timed out. Please try again.');
      } else if (e.toString().contains('tls')) {
        throw Exception('TLS connection failed. Please check your network settings.');
      }
      
      throw Exception('Failed to send email: $e');
    }
  }

  Future<void> updateEmailPreferences({
    required String deliveryTime,
    required String emailAddress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(user.uid).set({
      'preferences': {
        'deliveryTime': deliveryTime,
        'emailAddress': emailAddress,
      },
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
} 