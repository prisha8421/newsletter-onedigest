// lib/services/trending_service.dart
import 'package:collection/collection.dart';
import '../models/news_article.dart';

class TrendingService {
  static final Set<String> _stopWords = {
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'in', 'on',
    'for', 'of', 'and', 'to', 'with', 'from', 'by', 'at', 'as', 'it', 'that',
    'this', 'these', 'those', 'will', 'would', 'can', 'could', 'should', 'has',
    'have', 'had', 'but', 'if', 'or', 'not', 'about', 'also', 'more', 'than',
    'its', 'he', 'she', 'they', 'we', 'you', 'i', 'their', 'his', 'her', 'them',
    'our', 'us', 'may', 'just', 'so', 'new', 'latest', 'breaking'
  };

  static List<String> getTrendingTopics(List<NewsArticle> articles, {int topN = 8}) {
    final Map<String, int> biGramCounts = {};

    for (var article in articles) {
      final content = '${article.title} ${article.description}'.toLowerCase();

      final words = content
          .replaceAll(RegExp(r'[^\w\s]'), '') // remove punctuation
          .split(RegExp(r'\s+')) // split into words
          .where((word) => word.length > 2 && !_stopWords.contains(word))
          .toList();

      // Create bi-grams (pairs of adjacent words)
      for (var i = 0; i < words.length - 1; i++) {
        final biGram = '${words[i]} ${words[i + 1]}';
        biGramCounts[biGram] = (biGramCounts[biGram] ?? 0) + 1;
      }
    }

    final sorted = biGramCounts.entries
        .where((e) => e.value > 1) // Optional: filter out rare pairs
        .sorted((a, b) => b.value.compareTo(a.value));

    return sorted.take(topN).map((e) => e.key).toList();
  }
}
