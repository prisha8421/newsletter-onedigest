// lib/services/trending_service.dart
import '../models/news_article.dart';

class TrendingService {
  // Basic stopwords to ignore
  static const List<String> _stopwords = [
    'the', 'and', 'to', 'of', 'in', 'a', 'on', 'for', 'with', 'is', 'are',
    'by', 'at', 'an', 'as', 'be', 'this', 'that', 'from', 'it', 'has', 'its',
    'was', 'will', 'about', 'after', 'into', 'you', 'but', 'their', 'they',
    'not', 'have', 'he', 'she', 'we', 'i', 'or', 'up', 'new', 'news', 'more',
    'one', 'all', 'over', 'out', 'his', 'her', 'them', 'which', 'who', 'what',
    'when', 'how', 'just', 'been', 'than', 'some', 'also', 'so', 'if'
  ];

  static List<String> getTrendingTopics(List<NewsArticle> articles, {int maxTopics = 12}) {
    final Map<String, int> wordFrequency = {};

    for (var article in articles) {
      final text = '${article.title} ${article.description}'.toLowerCase();
      final words = text
          .replaceAll(RegExp(r'[^\w\s]'), '') // remove punctuation
          .split(RegExp(r'\s+'))              // split by spaces
          .where((word) =>
              word.length > 2 &&
              !_stopwords.contains(word) &&
              !word.contains(RegExp(r'\d')))   // filter numbers & stopwords
          .toList();

      for (var word in words) {
        wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
      }
    }

    // Sort words by frequency and return top N
    final sortedWords = wordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords.take(maxTopics).map((e) => e.key).toList();
  }
}
