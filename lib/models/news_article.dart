class NewsArticle {
  final String title;
  final String description;
  final String link;
  final String? thumbnail;
  final String? pubDate;
  final String? source;

  NewsArticle({
    required this.title,
    required this.description,
    required this.link,
    this.thumbnail,
    this.pubDate,
    this.source,
  });
}
