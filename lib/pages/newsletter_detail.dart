
import 'package:flutter/material.dart';

class NewsletterDetailPage extends StatelessWidget {
  final Map<String, String> item;

  const NewsletterDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? 'No Title';
    final summary = item['summary'] ?? 'No Summary Available';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.pink.shade200,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade100, Colors.orange.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  summary,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                SizedBox(height: 24),
                Text(
                  "More content coming soon...",
                  style: TextStyle(fontStyle: FontStyle.italic),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
