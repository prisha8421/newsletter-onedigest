import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';
import '../secrets.dart';

class WebSearchService {
  static const String _apiKey = 'Secrets.newsApiKey'; // Replace with your key
  static const String _endpoint = 'https://newsapi.org/v2/everything';

  static Future<List<NewsArticle>> searchArticles(String query) async {
    final url = Uri.parse(
      '$_endpoint?q=$query&sortBy=publishedAt&apiKey=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final articles = jsonData['articles'] as List;

      return articles.map((json) {
        return NewsArticle(
          id: json['url'], // Use URL as a unique ID
          title: json['title'] ?? '',
          description: json['description'] ?? '',
          url: json['url'] ?? '',
          imageUrl: json['urlToImage'] ?? '',
        );
      }).toList();
    } else {
      throw Exception('Failed to fetch articles');
    }
  }
}
