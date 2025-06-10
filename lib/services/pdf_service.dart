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

    // Load the logo
    final logoData = await rootBundle.load("assets/icon/logo.png");
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Add title page with improved styling
    print("📝 Adding header page...");
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo
              pw.Center(
                child: pw.Image(
                  logoImage,
                  width: 225,
                  height: 225,
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColors.grey300,
                      width: 1,
                    ),
                  ),
                ),
                child: pw.Text(
                  'Your Daily Newsletter',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    font: ttf,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                style: pw.TextStyle(
                  fontSize: 14,
                  font: ttf,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Articles: ${articles.length}',
                style: pw.TextStyle(
                  fontSize: 14,
                  font: ttf,
                  color: PdfColors.grey700,
                ),
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
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Article number and title
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey300,
                        width: 1,
                      ),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Article $index',
                        style: pw.TextStyle(
                          fontSize: 14,
                          font: ttf,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          font: ttf,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),

                // Metadata
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Tone: $tone',
                        style: pw.TextStyle(fontSize: 12, font: ttf),
                      ),
                      pw.Text(
                        'Language: $language',
                        style: pw.TextStyle(fontSize: 12, font: ttf),
                      ),
                      pw.Text(
                        'Format: ${format[0].toUpperCase()}${format.substring(1)}',
                        style: pw.TextStyle(fontSize: 12, font: ttf),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Summary content
                if (format == 'bullet points')
                  ..._buildBulletSummary(summary, ttf)
                else
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Text(
                      summary is List ? summary.join('\n') : summary.toString(),
                      style: pw.TextStyle(
                        fontSize: 14,
                        font: ttf,
                        lineSpacing: 1.5,
                      ),
                    ),
                  ),

                pw.SizedBox(height: 20),
                if (url.isNotEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Text(
                      'Read more: $url',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.blue700,
                        font: ttf,
                      ),
                    ),
                  ),
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
      pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: bulletItems.map((sentence) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• ',
                    style: pw.TextStyle(
                      fontSize: 14,
                      font: font,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      sentence,
                      style: pw.TextStyle(
                        fontSize: 14,
                        font: font,
                        lineSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ];
  }
}
