import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/news_article.dart';
import '../services/news_api_search_service.dart';
import '../widgets/article_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<NewsArticle> _results = [];
  bool _loading = false;

  void _searchArticles(String query) async {
    if (query.isEmpty) return;

    setState(() => _loading = true);
    final articles = await NewsApiSearchService.searchArticles(query);
    setState(() {
      _results = articles;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Articles')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchArticles,
              decoration: InputDecoration(
                hintText: 'Search news...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _results.clear());
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          if (_results.isEmpty && !_loading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/icon/waiting2.json',
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "No results found.",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  return ArticleCard(
                    article: _results[index],
                    isBookmarked: false,
                    isLiked: false,
                    isDisliked: false,
                    onBookmarkToggle: () {},
                    onLikeToggle: () {},
                    onDislikeToggle: () {},
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
