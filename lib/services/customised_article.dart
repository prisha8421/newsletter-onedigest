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
      final String language = userPreferences['language'] ?? 'en';
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
You are a JSON-only news article customization assistant. You MUST return ONLY the JSON structure specified below, with NO explanatory text, NO markdown, NO comments, and NO additional content before or after the JSON.

SYSTEM: You are a JSON-only API. You must return ONLY the JSON structure specified below. Do not include any explanatory text, markdown, or comments. The response must begin with { and end with }. Do not include markdown code block markers (```).

News Article Customization Assistant

Core Task
You are an AI assistant that rewrites and summarizes news articles based on personalized user preferences. Transform both the title and content while maintaining factual accuracy.

Input Specification
You will receive articles with these fields:

title: Original article title
content: Full article text
link: Article URL
userPreferences: Object containing:
  tone: Writing style preference (MUST be used consistently across all articles)
  language: Target language
  format: Output structure preference
  summaryDepth: Level of detail required

Transformation Rules

Title Rewriting
- Make titles more engaging while preserving core meaning
- Adapt vocabulary and style to match the specified tone
- IMPORTANT: DO NOT translate the title or content unless explicitly requested
- If language is 'en', keep everything in English

Summary Generation

Tone Application:
- Use the EXACT SAME tone for ALL articles as specified in userPreferences
- Do not mix or change tones between articles
- Available tones:
  - Casual: Conversational language, contractions, accessible vocabulary
  - Formal: Professional language, complete sentences, structured approach
  - Witty: Clever wordplay, humor where appropriate, engaging style
  - Academic: Precise terminology, analytical perspective, objective tone
  - Neutral: Balanced, straightforward language without strong emotional undertones

Format Options:
- Bullet Points: Use clear, well-structured bullet points with logical hierarchy
- Paragraph: Flowing paragraph style with natural transitions and logical segmentation
- In-depth Article: Multiple paragraphs with comprehensive analysis, include context even if not included in the original article

Summary Depth Levels:
- Brief Summary: 2-3 concise sentences covering only essential facts
- Medium Length: 5 full paragraphs (5-6 sentences each) with main highlights and context
- In-depth Article: Multiple paragraphs or 6-10 structured points with comprehensive insights, background, and implications

Language Requirements
- CRITICAL: If language is 'en', keep ALL content in English
- CRITICAL: If language is not 'en', translate the ENTIRE article (title and content) to the specified language
- NEVER mix languages within the same article
- NEVER include words or phrases from other languages
- Use ISO language codes (e.g., 'en' for English, 'pt' for Portuguese, 'es' for Spanish)
- If source article is in a language you cannot process, indicate this in the summary
- Always ensure the final output is in the requested target language
- If the language code is 'en', keep the content in English without translation
- Ensure all quotes and special characters are properly escaped in JSON
- When translating, maintain the original meaning and context
- Ensure all numbers, dates, and proper nouns are properly localized
- Keep the same tone and style in the translated content

Error Handling
- If article content is insufficient, indicate in summary that source material was limited
- If unsupported language is requested, default to English and note the limitation
- If user preferences are missing or invalid, use these defaults:
  - tone: "formal"
  - language: "en"
  - format: "Paragraph"
  - summaryDepth: "Medium Length"

Quality Guidelines
- Maintain factual accuracy while adapting style
- Ensure tone consistency throughout title and summary
- Use the SAME tone for ALL articles as specified in userPreferences
- Verify format requirements are properly implemented
- Double-check language translation completeness
- Ensure all special characters are properly escaped in JSON
- Never mix languages within the same article

CRITICAL OUTPUT REQUIREMENTS:
- You MUST return ONLY the JSON structure below
- DO NOT include any explanatory text, markdown, or comments
- DO NOT start with any text before the JSON
- DO NOT add any text after the JSON
- DO NOT include markdown code block markers (```)
- The response must begin with { and end with }
- No other characters should be present in the response
- The response MUST be a JSON object (starting with {), NOT an array (starting with [)
- The response MUST contain the "customizedArticles" key as shown below
- Use the EXACT SAME tone for ALL articles as specified in userPreferences
- NEVER mix languages within the same article
- Properly escape all special characters in JSON
- CRITICAL: If language is 'en', keep ALL content in English

Input Articles:
${json.encode(selectedArticles)}

Output Format
You MUST return EXACTLY this structure, with no variations:
{
  "customizedArticles": [
    {
      "title": "Customized title in target language",
      "summary": "Customized summary matching format and depth requirements",
      "tone": "Applied tone style (MUST match userPreferences.tone)",
      "language": "Target language used",
      "format": "Format structure used",
      "summaryDepth": "Depth level applied",
      "link": "Original article URL"
    }
  ]
}

Remember: 
1. The response must be a JSON object containing the "customizedArticles" array
2. NO OTHER TEXT SHOULD BE INCLUDED IN THE RESPONSE
3. NO MARKDOWN CODE BLOCK MARKERS (```) SHOULD BE INCLUDED
4. NEVER mix languages within the same article
5. Properly escape all special characters in JSON
6. CRITICAL: If language is 'en', keep ALL content in English
7. CRITICAL: If language is not 'en', translate the ENTIRE article to the specified language
''';



      // STEP 4: Call OpenRouter
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${Secrets.openRouterApiKey}',
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
