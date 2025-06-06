import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PDFService {
  Future<File> generateNewsletterPDF(List<Map<String, dynamic>> articles) async {
    print("📄 Starting PDF generation...");
    final pdf = pw.Document();

    // Load the NotoSans font (supports Unicode)
    final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    // Add title page
    print("📝 Adding header page...");
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Your Daily Newsletter',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: ttf),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                style: pw.TextStyle(fontSize: 14, font: ttf),
              ),
            ],
          );
        },
      ),
    );

    int index = 1;
    for (var article in articles) {
      final title = article['title'] ?? 'No Title';
      final summary = article['summary'];
      final tone = article['tone'] ?? 'Neutral';
      final language = article['language'] ?? 'English';
      final format = (article['format'] ?? 'Paragraph').toLowerCase();
      final url = article['link'] ?? '';

      print("📰 Adding article $index: $title");

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: ttf),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Tone: $tone | Language: $language | Format: ${format[0].toUpperCase()}${format.substring(1)}',
                  style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, font: ttf),
                ),
                pw.SizedBox(height: 10),

                // Conditionally format summary
                if (format == 'bullet points')
                  ..._buildBulletSummary(summary, ttf)
                else
                  pw.Text(
                    summary is List ? summary.join('\n') : summary.toString(),
                    style: pw.TextStyle(fontSize: 13, font: ttf),
                  ),

                pw.SizedBox(height: 10),
                if (url.isNotEmpty)
                  pw.Text('Read more: $url',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.blue, font: ttf)),
              ],
            );
          },
        ),
      );

      index++;
    }

    print("📦 Saving PDF to temporary directory...");
    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/newsletter_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    print("✅ PDF successfully saved at: $filePath");
    return file;
  }

  /// Builds a bullet point summary from either a list or a long string.
  List<pw.Widget> _buildBulletSummary(dynamic summary, pw.Font font) {
    List<String> bulletItems;

    if (summary is List) {
      bulletItems = summary.map((e) => e.toString()).toList();
    } else if (summary is String) {
      bulletItems = summary
          .split(RegExp(r'\.\s+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => s.endsWith('.') ? s : '$s.')
          .toList();
    } else {
      bulletItems = ['Invalid summary format'];
    }

    return [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: bulletItems.map((sentence) {
          return pw.Bullet(
            text: sentence,
            style: pw.TextStyle(fontSize: 13, font: font),
          );
        }).toList(),
      )
    ];
  }
}
