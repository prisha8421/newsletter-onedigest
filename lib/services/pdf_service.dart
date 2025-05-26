import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

class PDFService {
  Future<File> generateNewsletterPDF(List<Map<String, dynamic>> articles) async {
    final pdf = pw.Document();

    // Add a title page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Your Daily Digest',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Generated on: ${DateTime.now().toString().split(' ')[0]}',
                  style: pw.TextStyle(fontSize: 14)),
            ],
          );
        },
      ),
    );

    // Add content pages
    for (var article in articles) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 1,
                  child: pw.Text(article['title'] ?? 'No Title',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                if (article['description'] != null)
                  pw.Text(article['description'],
                      style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 10),
                if (article['url'] != null)
                  pw.Text('Read more: ${article['url']}',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.blue)),
              ],
            );
          },
        ),
      );
    }

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/newsletter_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
} 