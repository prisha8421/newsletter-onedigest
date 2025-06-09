import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';
import '../secrets.dart';

class NewsApiSearchService {
  // Use actual API key from secrets.dart
  static final _apiKey = Secrets.newsApiKey;
  static const _endpoint = 'https://newsapi.org/v2/everything';

  static Future<List<NewsArticle>> searchArticles(String query) async {
    final url = Uri.parse(
      "$_endpoint?q=${Uri.encodeQueryComponent(query)}&language=en&pageSize=20&apiKey=$_apiKey",
    );

    print("🔍 Searching NewsAPI with URL: $url");

    final response = await http.get(url);

    print("🛑 HTTP status: ${response.statusCode}");
    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      print("📃 NewsAPI response status: ${body['status']}");

      if (body['status'] == 'ok') {
        final List articles = body['articles'];
        print("✅ Found ${articles.length} articles");

        return articles.map((json) => NewsArticle.fromNewsApi(json)).toList();
      } else {
        print("❌ NewsAPI error message: ${body['message']}");
        return [];
      }
    } else {
      print("❌ HTTP error: ${response.statusCode} with body: ${response.body}");
      return [];
    }
  }
}
