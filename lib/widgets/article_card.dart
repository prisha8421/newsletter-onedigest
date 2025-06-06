import 'package:flutter/material.dart';
import '../models/news_article.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleCard extends StatefulWidget {
  final NewsArticle article;
  final bool isBookmarked;
  final bool isLiked;
  final bool isDisliked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onLikeToggle;
  final VoidCallback onDislikeToggle;

  const ArticleCard({
    Key? key,
    required this.article,
    required this.isBookmarked,
    required this.isLiked,
    required this.isDisliked,
    required this.onBookmarkToggle,
    required this.onLikeToggle,
    required this.onDislikeToggle,
  }) : super(key: key);

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  final FlutterTts flutterTts = FlutterTts();

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop(); // stop TTS if widget is disposed
    super.dispose();
  }

  Future<void> _launchArticleUrl() async {
    final url = Uri.tryParse(widget.article.url);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch article")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _launchArticleUrl,
        child: Column(
          children: [
            if (widget.article.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  widget.article.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.article.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(widget.article.description),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () => _speak(widget.article.description),
                      ),
                      IconButton(
                        icon: Icon(widget.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined),
                        onPressed: widget.onLikeToggle,
                      ),
                      IconButton(
                        icon: Icon(widget.isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined),
                        onPressed: widget.onDislikeToggle,
                      ),
                      IconButton(
                        icon: Icon(widget.isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
                        onPressed: widget.onBookmarkToggle,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
