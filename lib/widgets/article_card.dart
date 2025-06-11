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
    super.key,
    required this.article,
    required this.isBookmarked,
    required this.isLiked,
    required this.isDisliked,
    required this.onBookmarkToggle,
    required this.onLikeToggle,
    required this.onDislikeToggle,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  final FlutterTts flutterTts = FlutterTts();
  bool isExpanded = false;
  static const int maxLines = 3;
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
  );

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
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

  bool _needsReadMore(String text) {
    _textPainter.text = TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black87,
        height: 1.4,
      ),
    );
    _textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 64); // Account for padding
    return _textPainter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _launchArticleUrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.article.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: isExpanded ? null : maxLines,
                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                  ),
                  if (_needsReadMore(widget.article.description))
                    TextButton(
                      onPressed: () => setState(() => isExpanded = !isExpanded),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        isExpanded ? 'Show less' : 'Read more',
                        style: const TextStyle(
                          color: Color(0xFF8981DF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: Color(0xFF8981DF)),
                            onPressed: () => _speak(widget.article.description),
                          ),
                          IconButton(
                            icon: Icon(
                              widget.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                              color: widget.isLiked ? const Color(0xFF8981DF) : Colors.grey,
                            ),
                            onPressed: widget.onLikeToggle,
                          ),
                          IconButton(
                            icon: Icon(
                              widget.isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                              color: widget.isDisliked ? const Color(0xFF8981DF) : Colors.grey,
                            ),
                            onPressed: widget.onDislikeToggle,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          widget.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                          color: widget.isBookmarked ? const Color(0xFF8981DF) : Colors.grey,
                        ),
                        onPressed: widget.onBookmarkToggle,
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
}
