import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_newsletter/customisations/delivery_page.dart';
import 'package:new_newsletter/customisations/language_page.dart';
import 'package:new_newsletter/customisations/summary_page.dart';
import 'package:new_newsletter/customisations/tone_format.dart';
import 'package:new_newsletter/services/news_service.dart';

import 'package:new_newsletter/models/news_article.dart';
import 'package:new_newsletter/widgets/article_card.dart';
import 'auth_page.dart';
import 'profile_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchAllArticles();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserName(); // Refresh on dependency change (e.g. after login)
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

  Future<void> _fetchAllArticles() async {
    setState(() => isLoading = true);
    try {
      List<NewsArticle> fetchedArticles = await fetchLatestArticles();
      fetchedArticles.sort((a, b) => (b.pubDate ?? '').compareTo(a.pubDate ?? ''));
      setState(() {
        allArticles = fetchedArticles;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load latest articles: $e');
      setState(() => isLoading = false);
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logout successful!')));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('📰 OneDigest', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesOverviewPage()));
            },
          ),
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

    if (allArticles.isEmpty) {
      return const Center(child: Text('No articles found.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchAllArticles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allArticles.length,
        itemBuilder: (context, index) {
          final article = allArticles[index];
          return ArticleCard(article: article);
        },
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
          _buildHeader(),
          _buildToggleButtons(),
          const SizedBox(height: 10),
          Expanded(child: _buildNewsFeed()),
        ],
      ),
    );
  }
}
