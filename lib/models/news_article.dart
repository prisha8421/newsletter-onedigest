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

  // Generate a consistent ID for an article
  static String generateId(String url, String title) {
    // Create a unique ID by combining URL and title
    final String combined = '$url:$title';
    // Use a simple hash function to generate a consistent ID
    return combined.hashCode.toString();
  }

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
    final title = map['title'] ?? '';
    final url = map['url'] ?? '';
    return NewsArticle(
      id: generateId(url, title),
      title: title,
      description: map['description'] ?? '',
      url: url,
      imageUrl: map['urlToImage'] ?? '',
    );
  }
}
