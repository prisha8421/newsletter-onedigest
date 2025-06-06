import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_article.dart';

class NewsService {
  static Future<List<NewsArticle>> fetchLatestArticles() async {
    List<NewsArticle> articles = [];

    final allFeedUrls = [
      'https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml',
      'https://feeds.bbci.co.uk/news/rss.xml',
      'https://www.aljazeera.com/xml/rss/all.xml',
      'https://rss.cnn.com/rss/cnn_topstories.rss',
      'https://www.theguardian.com/world/rss',
       'https://www.indiatoday.in/rss/1206571',
       'https://feeds.feedburner.com/ndtvnews-india-news'
    ];

    for (final feedUrl in allFeedUrls) {
      try {
        final response = await http.get(Uri.parse(feedUrl));

        if (response.statusCode == 200) {
          final document = XmlDocument.parse(response.body);
          final items = document.findAllElements('item');

          for (final item in items.take(5)) {
            final title = item.getElement('title')?.text ?? 'No title';
            final rawDescription = item.getElement('description')?.text ?? 'No description';
            final description = stripHtmlTags(rawDescription);
            final link = item.getElement('link')?.text ?? '';
            final pubDate = item.getElement('pubDate')?.text ?? '';

            final thumbnail = item
                    .findElements('media:thumbnail')
                    .firstOrNull
                    ?.getAttribute('url') ??
                item
                    .findElements('enclosure')
                    .firstOrNull
                    ?.getAttribute('url') ??
                '';

            articles.add(NewsArticle(
              id: link, // using URL as unique ID
              title: title,
              description: description,
              url: link,
              imageUrl: thumbnail,
            ));
          }
        }
      } catch (e) {
        print('Error fetching feed $feedUrl: $e');
        continue;
      }
    }

    return articles;
  }

  static String stripHtmlTags(String htmlText) {
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlText.replaceAll(exp, '').trim();
  }
}
