import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../customisations/delivery_page.dart';
import '../customisations/language_page.dart';
import '../customisations/summary_page.dart';
import '../customisations/tone_format.dart';
import '../services/news_service.dart';
import '../models/news_article.dart';
import '../widgets/article_card.dart';
import 'auth_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showDigest = true;
  String userName = 'User';
  List<NewsArticle> allArticles = [];
  bool isLoading = true;
  final Set<String> bookmarkedIds = {};
  final Map<String, bool> likedArticles = {};
  final Map<String, bool> dislikedArticles = {};

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadBookmarks();
    _fetchAllArticles();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['name'] ?? 'User';
        });
      }
    } else {
      setState(() {
        userName = 'Guest';
      });
    }
  }

  Future<void> _loadBookmarks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .get();

    setState(() {
      bookmarkedIds.clear();
      bookmarkedIds.addAll(snapshot.docs.map((doc) => doc.id));
    });
  }

  Future<void> _fetchAllArticles() async {
    setState(() => isLoading = true);
    try {
      List<NewsArticle> fetchedArticles = await NewsService.fetchLatestArticles();
      setState(() {
        allArticles = fetchedArticles;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load latest articles: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logout successful!')));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        await user.delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted successfully!')));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.deepPurple),
            child: Text(
              user != null ? 'Welcome, $userName!' : 'Welcome!',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Tone & Format'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToneFormatPage())),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language Preferences'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguagePage())),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Delivery Settings'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliverySettingsPage())),
            ),
            ListTile(
              leading: const Icon(Icons.notes),
              title: const Text('Summary Settings'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryPage())),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Digest'),
            selected: showDigest,
            onSelected: (val) => setState(() => showDigest = true),
          ),
          const SizedBox(width: 10),
          ChoiceChip(
            label: const Text('Latest'),
            selected: !showDigest,
            onSelected: (val) => setState(() => showDigest = false),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsFeed() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    List<NewsArticle> displayedArticles = showDigest
        ? allArticles.where((a) => bookmarkedIds.contains(a.id)).toList()
        : allArticles;

    if (displayedArticles.isEmpty) {
      return Center(child: Text(showDigest ? 'No bookmarked articles.' : 'No articles found.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchAllArticles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayedArticles.length,
        itemBuilder: (context, index) {
          final article = displayedArticles[index];
          final isBookmarked = bookmarkedIds.contains(article.id);
          final isLiked = likedArticles[article.id] ?? false;
          final isDisliked = dislikedArticles[article.id] ?? false;

          return ArticleCard(
            key: ValueKey(article.id),
            article: article,
            isBookmarked: isBookmarked,
            isLiked: isLiked,
            isDisliked: isDisliked,
            onBookmarkToggle: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login to bookmark')),
                );
                return;
              }

              final docRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('bookmarks')
                  .doc(article.id);

              setState(() {
                if (isBookmarked) {
                  docRef.delete();
                  bookmarkedIds.remove(article.id);
                } else {
                  docRef.set(article.toMap());
                  bookmarkedIds.add(article.id);
                }
              });
            },
            onLikeToggle: () {
              setState(() {
                final current = likedArticles[article.id] ?? false;
                likedArticles[article.id] = !current;
                if (!current) dislikedArticles[article.id] = false;
              });
            },
            onDislikeToggle: () {
              setState(() {
                final current = dislikedArticles[article.id] ?? false;
                dislikedArticles[article.id] = !current;
                if (!current) likedArticles[article.id] = false;
              });
            },
          );
        },
      ),
    );
  }

  void _showProfileMenu() {
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('View/Edit Preferences'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ToneFormatPage()));
              },
            ),
            if (user != null) ...[
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  await _logout();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Delete Account'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _deleteAccount();
                  }
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OneDigest")),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📰 OneDigest', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.account_circle, size: 30),
                  onPressed: () => _showProfileMenu(),
                ),
              ],
            ),
          ),
          _buildToggleButtons(),
          const SizedBox(height: 10),
          Expanded(child: _buildNewsFeed()),
        ],
      ),
    );
  }
}
