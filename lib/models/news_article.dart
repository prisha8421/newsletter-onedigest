class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String url;
  final String imageUrl;

  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
  });

  // For Firestore and RSS parsing
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'imageUrl': imageUrl,
    };
  }

  // From Firestore
  factory NewsArticle.fromMap(Map<String, dynamic> map) {
    return NewsArticle(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      url: map['url'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  // From NewsAPI search result
  factory NewsArticle.fromNewsApi(Map<String, dynamic> map) {
    return NewsArticle(
      id: map['url'] ?? '', // Use URL as ID
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      url: map['url'] ?? '',
      imageUrl: map['urlToImage'] ?? '',
    );
  }
}
