import 'package:flutter/material.dart';
class NewsCard extends StatefulWidget {
  final Article article;
  final bool isDigest;
  final VoidCallback? onTap;

  const NewsCard({
    super.key,
    required this.article,
    this.isDigest = false,
    this.onTap,
  });

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleButtonPress() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.article.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.article.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  widget.article.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.article.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.article.source,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      children: [
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: IconButton(
                            icon: Icon(
                              widget.article.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: widget.article.isBookmarked ? Colors.deepPurple : Colors.grey,
                            ),
                            onPressed: () {
                              _handleButtonPress();
                              // Add bookmark functionality
                            },
                          ),
                        ),
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: IconButton(
                            icon: Icon(
                              widget.article.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                              color: widget.article.isLiked ? Colors.deepPurple : Colors.grey,
                            ),
                            onPressed: () {
                              _handleButtonPress();
                              // Add like functionality
                            },
                          ),
                        ),
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: IconButton(
                            icon: Icon(
                              widget.article.isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                              color: widget.article.isDisliked ? Colors.deepPurple : Colors.grey,
                            ),
                            onPressed: () {
                              _handleButtonPress();
                              // Add dislike functionality
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 