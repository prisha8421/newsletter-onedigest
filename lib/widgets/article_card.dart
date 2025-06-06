import 'package:flutter/material.dart';
import '../models/news_article.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleCard extends StatelessWidget {
  final NewsArticle article;
  final bool isBookmarked;
  final bool isLiked;
  final bool isDisliked;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onDislikeToggle;

  const ArticleCard({
    super.key,
    required this.article,
    this.isBookmarked = false,
    this.isLiked = false,
    this.isDisliked = false,
    this.onBookmarkToggle,
    this.onLikeToggle,
    this.onDislikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launchURL(context, article.url),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                child: Image.network(
                  article.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.thumb_up,
                          color: isLiked ? Colors.green : Colors.grey,
                        ),
                        onPressed: onLikeToggle,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.thumb_down,
                          color: isDisliked ? Colors.red : Colors.grey,
                        ),
                        onPressed: onDislikeToggle,
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? Colors.amber : null,
                        ),
                        onPressed: onBookmarkToggle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch the article')),
      );
    }
  }
}
