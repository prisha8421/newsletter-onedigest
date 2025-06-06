import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import '../secrets.dart';

class PersonalizedNewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _newsApiKey = Secrets.newsApiKey;

  // ✅ Fetch user-selected topics from Firestore
  Future<List<String>> getUserTopics(String userId) async {
    print('📥 Fetching user topics for userId: $userId');
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final topics = userDoc.data()?['preferences']?['topics'] ?? [];
      print('✅ Retrieved topics: $topics');
      return List<String>.from(topics);
    } catch (e) {
      print('❌ Error fetching user topics: $e');
      return [];
    }
  }

  // ✅ Fetch full user preferences from Firestore
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    print('📥 Fetching user preferences for userId: $userId');
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final preferences = userDoc.data()?['preferences'];
      print('✅ User preferences: $preferences');
      return preferences;
    } catch (e) {
      print('❌ Error fetching user preferences: $e');
      return null;
    }
  }

  // ✅ Fetch news articles for the topics (LIMITED TO 3 PER TOPIC)
  Future<List<Map<String, dynamic>>> fetchNewsForTopics(List<String> topics) async {
    print('🔍 Fetching news for topics: $topics');
    final List<Map<String, dynamic>> articles = [];

    for (var topic in topics) {
      try {
        print('🌐 Fetching news for topic: $topic');
        final response = await http.get(
          Uri.parse(
            'https://newsapi.org/v2/everything?q=$topic&sortBy=publishedAt&pageSize=3&apiKey=$_newsApiKey',
          ),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final fetchedArticles = data['articles'] ?? [];
          print('✅ Fetched ${fetchedArticles.length} articles for "$topic"');

          for (var article in fetchedArticles) {
            try {
              final url = article['url'] ?? '';
              final content = await fetchFullArticleContent(url);

              articles.add({
                'topic': topic,
                'title': (article['title'] ?? 'No Title').trim(),
                'description': (article['description'] ?? 'No Description').trim(),
                'content': content.length > 1000
                    ? '${content.substring(0, 1000)}...'
                    : content,
                'url': url,
              });
            } catch (innerError) {
              print('⚠️ Skipped article due to parsing error: $innerError');
            }
          }
        } else {
          print('❌ API error for "$topic": ${response.statusCode} - ${response.reasonPhrase}');
        }
      } catch (e) {
        print('❌ Exception fetching news for "$topic": $e');
      }
    }

    print('📦 Total articles fetched (max 3 per topic): ${articles.length}');
    return articles;
  }

  // ✅ Fetch full article content from the URL
  Future<String> fetchFullArticleContent(String url) async {
    print('🔍 Fetching full content from: $url');
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final text = document.body?.text ?? 'Content unavailable';
        final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
        print('✅ Clean content fetched from: $url');
        return cleaned;
      } else {
        print('⚠️ Failed to fetch full content: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching full article content: $e');
    }
    return 'Full content could not be fetched';
  }
}
