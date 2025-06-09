import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/news_service.dart';
import '../models/news_article.dart';
import '../widgets/article_card.dart';
import '../services/trending_service.dart';
import '../widgets/trending_topics_widget.dart';

import '../customisations/delivery_page.dart';
import '../customisations/language_page.dart';
import '../customisations/summary_page.dart';
import '../customisations/tone_format.dart';
import '../customisations/topic_preference.dart'; // <-- Added this
import 'auth_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showDigest = true;
  String userName = 'User';
  List<NewsArticle> allArticles = [];
  List<String> trendingTopics = [];
  bool isLoading = true;
  final Set<String> bookmarkedIds = {};
  final Map<String, bool> likedArticles = {};
  final Map<String, bool> dislikedArticles = {};
  String? selectedTopic;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadUserPreferences();
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

  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bookmarksSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .get();

    final likesSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('likes')
        .get();

    final dislikesSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dislikes')
        .get();

    setState(() {
      bookmarkedIds.clear();
      bookmarkedIds.addAll(bookmarksSnap.docs.map((doc) => doc.id));

      likedArticles.clear();
      likedArticles.addEntries(likesSnap.docs.map((doc) => MapEntry(doc.id, true)));

      dislikedArticles.clear();
      dislikedArticles.addEntries(dislikesSnap.docs.map((doc) => MapEntry(doc.id, true)));
    });
  }

  Future<void> _fetchAllArticles() async {
    setState(() => isLoading = true);
    try {
      List<NewsArticle> fetchedArticles = await NewsService.fetchLatestArticles();
      setState(() {
        allArticles = fetchedArticles;
        trendingTopics = TrendingService.getTrendingTopics(fetchedArticles);
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
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search Articles'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
            },
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
              leading: const Icon(Icons.list_alt),
              title: const Text('Topic Preferences'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TopicPreferencePage()));
              },
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
    if (isLoading) return const Center(child: CircularProgressIndicator());

    List<NewsArticle> displayedArticles = (showDigest
            ? allArticles.where((a) => bookmarkedIds.contains(a.id))
            : allArticles)
        .where((a) => !(dislikedArticles[a.id] ?? false))
        .toList();

    if (selectedTopic != null) {
      displayedArticles = displayedArticles.where((article) {
        final content = '${article.title} ${article.description}'.toLowerCase();
        return content.contains(selectedTopic!.toLowerCase());
      }).toList();
    }

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

              try {
                if (isBookmarked) {
                  await docRef.delete();
                  setState(() {
                    bookmarkedIds.remove(article.id);
                  });
                } else {
                  await docRef.set(article.toMap());
                  setState(() {
                    bookmarkedIds.add(article.id);
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating bookmark: $e')),
                );
              }
            },
            onLikeToggle: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              final likedRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('likes')
                  .doc(article.id);

              final dislikedRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('dislikes')
                  .doc(article.id);

              final currentLiked = likedArticles[article.id] ?? false;

              try {
                if (!currentLiked) {
                  await likedRef.set({'liked': true});
                  await dislikedRef.delete();
                } else {
                  await likedRef.delete();
                }

                setState(() {
                  likedArticles[article.id] = !currentLiked;
                  dislikedArticles[article.id] = false;
                });
              } catch (e) {
                debugPrint("Error storing like: $e");
              }
            },
            onDislikeToggle: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              final dislikedRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('dislikes')
                  .doc(article.id);

              final likedRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('likes')
                  .doc(article.id);

              final currentDisliked = dislikedArticles[article.id] ?? false;

              setState(() {
                dislikedArticles[article.id] = !currentDisliked;
                likedArticles[article.id] = false;
              });

              if (!currentDisliked) {
                await dislikedRef.set({'disliked': true});
                await likedRef.delete();
              } else {
                await dislikedRef.delete();
              }
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
      appBar: AppBar(
        title: const Text("📰 OneDigest"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: _showProfileMenu,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrendingTopicsWidget(
            topics: trendingTopics,
            selectedTopic: selectedTopic,
            onTopicSelected: (topic) {
              setState(() {
                if (selectedTopic == topic) {
                  selectedTopic = null;
                } else {
                  selectedTopic = topic;
                }
              });
            },
          ),
          const SizedBox(height: 10),
          _buildToggleButtons(),
          const SizedBox(height: 10),
          Expanded(child: _buildNewsFeed()),
        ],
      ),
    );
  }
}
