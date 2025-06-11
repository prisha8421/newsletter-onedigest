import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

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
  bool showDigest = false;
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5E35B1), // Slightly darker purple
                    Color(0xFF7E57C2), // Original deep purple
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    user != null ? 'Welcome, $userName!' : 'Welcome!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your personalized news experience',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: Colors.deepPurple.withOpacity(0.1),
                        highlightColor: Colors.deepPurple.withOpacity(0.05),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
                        },
                        child: ListTile(
                          leading: const Icon(Icons.search, color: Colors.deepPurple),
                          title: const Text(
                            'Search Articles',
                            style: TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (user != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: Colors.deepPurple.withOpacity(0.1),
                          highlightColor: Colors.deepPurple.withOpacity(0.05),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToneFormatPage())),
                          child: ListTile(
                            leading: const Icon(Icons.tune, color: Colors.deepPurple),
                            title: const Text(
                              'Tone & Format',
                              style: TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: Colors.deepPurple.withOpacity(0.1),
                          highlightColor: Colors.deepPurple.withOpacity(0.05),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguagePage())),
                          child: ListTile(
                            leading: const Icon(Icons.language, color: Colors.deepPurple),
                            title: const Text(
                              'Language Preferences',
                              style: TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: Colors.deepPurple.withOpacity(0.1),
                          highlightColor: Colors.deepPurple.withOpacity(0.05),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliverySettingsPage())),
                          child: ListTile(
                            leading: const Icon(Icons.schedule, color: Colors.deepPurple),
                            title: const Text(
                              'Delivery Settings',
                              style: TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: Colors.deepPurple.withOpacity(0.1),
                          highlightColor: Colors.deepPurple.withOpacity(0.05),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryPage())),
                          child: ListTile(
                            leading: const Icon(Icons.notes, color: Colors.deepPurple),
                            title: const Text(
                              'Summary Settings',
                              style: TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: Colors.deepPurple.withOpacity(0.1),
                          highlightColor: Colors.deepPurple.withOpacity(0.05),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const TopicPreferencePage()));
                          },
                          child: ListTile(
                            leading: const Icon(Icons.list_alt, color: Colors.deepPurple),
                            title: const Text(
                              'Topic Preferences',
                              style: TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: Colors.deepPurple.withOpacity(0.1),
                          highlightColor: Colors.deepPurple.withOpacity(0.05),
                          onTap: () {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
                          },
                          child: ListTile(
                            leading: const Icon(Icons.login, color: Colors.deepPurple),
                            title: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (user != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.deepPurple.withOpacity(0.1),
                    highlightColor: Colors.deepPurple.withOpacity(0.05),
                    onTap: _logout,
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.deepPurple),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => showDigest = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: showDigest ? const Color(0xFF8981DF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      color: showDigest ? Colors.white : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Digest',
                      style: TextStyle(
                        color: showDigest ? Colors.white : Colors.grey.shade600,
                        fontWeight: showDigest ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => showDigest = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !showDigest ? const Color(0xFF8981DF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      color: !showDigest ? Colors.white : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'For You',
                      style: TextStyle(
                        color: !showDigest ? Colors.white : Colors.grey.shade600,
                        fontWeight: !showDigest ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsFeed() {
    if (isLoading) {
      return Center(
        child: Lottie.asset(
          'assets/icon/loading_plane.json',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      );
    }

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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "OneDigest",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 30,
              color: Color(0xFF8981DF),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30, color: Color(0xFF8981DF)),
            onPressed: _showProfileMenu,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
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
                _buildToggleButtons(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildNewsFeed()),
        ],
      ),
    );
  }
}
