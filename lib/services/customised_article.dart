import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../services/personalised_news_service.dart';
import '../services/pdf_service.dart';
import '../secrets.dart'; // contains openRouterApiKey

class CustomizedArticleService {
  final PersonalizedNewsService newsService;
  final PDFService pdfService;

  CustomizedArticleService({
    required this.newsService,
    required this.pdfService,
  });

  Future<File?> generateCustomizedNewsletter(String userId) async {
    print("🚀 Starting newsletter generation for user: $userId");

    try {
      // STEP 1: Fetch preferences
      print("📥 Fetching user preferences...");
      final userPreferences = await newsService.getUserPreferences(userId);

      if (userPreferences == null) {
        print("❌ User preferences not found for $userId");
        return null;
      }

      final topics = List<String>.from(userPreferences['topics'] ?? []);
      print("📚 User topics: $topics");

      if (topics.isEmpty) {
        print("⚠️ No topics found for user $userId");
        return null;
      }

      // STEP 2: Fetch one article per topic
      print("📰 Fetching one news article per topic...");
      final List<Map<String, dynamic>> selectedArticles = [];

      final String tone = userPreferences['tone'] ?? 'Neutral';
      final String language = userPreferences['language'] ?? 'English';
      final String summaryDepth = userPreferences['summaryDepth'] ?? 'Brief Summary';
      final String format = userPreferences['format'] ?? 'Paragraph';

      for (String topic in topics) {
        final topicArticles = await newsService.fetchNewsForTopics([topic]);
        if (topicArticles.isNotEmpty) {
          final article = topicArticles.first;
          final content = article['content'] ?? '';
          final description = article['description'] ?? '';

          selectedArticles.add({
            'title': article['title'] ?? '',
            'description': description.length > 300
                ? description.substring(0, 300)
                : description,
            'content': content.length > 1000
                ? content.substring(0, 1000)
                : content,
            'url': article['url'] ?? '',
            // 👇 Inject preferences into each article
            'tone': tone,
            'language': language,
            'summaryDepth': summaryDepth,
            'format': format,
          });
        }
      }

      if (selectedArticles.isEmpty) {
        print("⚠️ No articles found for selected topics.");
        return null;
      }

      print("📦 Total selected articles: ${selectedArticles.length}");

      // STEP 3: Build prompt
      print("✏️ Constructing prompt...");

 final prompt = '''
You are an intelligent assistant tasked with rewriting and summarizing news articles.

Each article includes its own preferences:
- tone
- language
- format
- summaryDepth

Use the preferences provided **within each article object** to generate the rewritten title and customized summary.

🧠 SummaryDepth meanings:
- "Brief Summary" = 2–3 concise sentences.
- "Medium Length" = 1 short paragraph (5–6 sentences).
- "In-depth Article" = detailed summary covering all important points, multiple paragraphs or 6–10 bullet points.

🔁 Instructions:
- Rewrite the title (if needed).
- Summarize the content according to that article’s summaryDepth, format, tone, and language.
- If format is "Bullet Points", provide structured bullet points (not sentences mashed together).
- Output must be valid JSON only (no markdown, no extra comments).

📤 INPUT ARTICLES:
${json.encode(selectedArticles)}

📥 OUTPUT FORMAT:
Return only this JSON structure:

{
  "customizedArticles": [
    {
      "title": "Customized title",
      "summary": "Customized summary (bullet points OR paragraph)",
      "tone": "Tone used",
      "language": "Language used",
      "format": "Format used",
      "link": "Original article URL"
    }
  ]
}
''';


      // STEP 4: Call OpenRouter
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $Secrets.openRouterApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "mistralai/mistral-7b-instruct",
          "messages": [
            {"role": "user", "content": prompt}
          ]
        }),
      );

      print("📨 OpenRouter response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final content = result['choices'][0]['message']['content'];

        print("📬 Raw model output:\n$content");

        late final Map<String, dynamic> extractedJson;
        try {
          final cleaned = content.trim();
          extractedJson = json.decode(cleaned);
        } catch (e) {
          print("❌ Failed to decode model output: $e");
          return null;
        }

        final dynamic customizedRaw = extractedJson['customizedArticles'];

        if (customizedRaw is! List) {
          print("❌ 'customizedArticles' is not a List");
          return null;
        }

        final customizedArticles = customizedRaw.map<Map<String, dynamic>>((item) {
          return Map<String, dynamic>.from(item);
        }).toList();

        print("📄 Generating PDF...");
        final pdfFile = await pdfService.generateNewsletterPDF(customizedArticles);

        print("✅ PDF generated at: ${pdfFile.path}");
        return pdfFile;
      } else {
        print("❌ OpenRouter failed with status: ${response.statusCode}");
        print("Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error during newsletter generation: $e");
      return null;
    }
  }
}
