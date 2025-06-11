import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> with SingleTickerProviderStateMixin {
  String selectedDepth = 'Brief Summary';
  bool showSaveAnimation = false;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  final List<String> depthOptions = [
    'Brief Summary',
    'Medium Length',
    'In-depth Article',
  ];

  @override
  void initState() {
    super.initState();
    _loadSummaryPreference();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    double targetProgress = 0;
    switch (selectedDepth) {
      case 'Brief Summary':
        targetProgress = 0;
        break;
      case 'Medium Length':
        targetProgress = 0.5;
        break;
      case 'In-depth Article':
        targetProgress = 1;
        break;
    }

    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: targetProgress,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward(from: 0);
  }

  Future<void> _loadSummaryPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final prefs = userDoc.data()?['preferences'] ?? {};
    final depth = prefs['summaryDepth'];

    setState(() {
      if (depth != null && depthOptions.contains(depth)) {
        selectedDepth = depth;
      }
    });

    // If summary depth preference is missing, set default
    if (depth == null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': {'summaryDepth': selectedDepth},
      }, SetOptions(merge: true));
    }
    _updateProgress();
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': {
          'summaryDepth': selectedDepth,
        }
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        showSaveAnimation = true;
      });

      // Hide the save animation after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            showSaveAnimation = false;
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving summary preference: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Summary Settings',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose how detailed you want your news summaries to be.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Summary Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Summary Depth',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Depth Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _DepthIndicator(
                                  label: 'Brief',
                                  isSelected: selectedDepth == 'Brief Summary',
                                  position: 0,
                                ),
                                Expanded(
                                  child: AnimatedBuilder(
                                    animation: _progressAnimation,
                                    builder: (context, child) {
                                      return Stack(
                                        children: [
                                          Container(
                                            height: 4,
                                            color: Colors.grey.shade300,
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: _progressAnimation.value,
                                            child: Container(
                                              height: 4,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    const Color(0xFF8981DF).withOpacity(0.3),
                                                    const Color(0xFF8981DF).withOpacity(0.7),
                                                    const Color(0xFF8981DF),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                _DepthIndicator(
                                  label: 'Medium',
                                  isSelected: selectedDepth == 'Medium Length',
                                  position: 1,
                                ),
                                Expanded(
                                  child: AnimatedBuilder(
                                    animation: _progressAnimation,
                                    builder: (context, child) {
                                      return Stack(
                                        children: [
                                          Container(
                                            height: 4,
                                            color: Colors.grey.shade300,
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: _progressAnimation.value,
                                            child: Container(
                                              height: 4,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    const Color(0xFF8981DF).withOpacity(0.3),
                                                    const Color(0xFF8981DF).withOpacity(0.7),
                                                    const Color(0xFF8981DF),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                _DepthIndicator(
                                  label: 'In-depth',
                                  isSelected: selectedDepth == 'In-depth Article',
                                  position: 2,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: depthOptions.map((depth) {
                            final isSelected = selectedDepth == depth;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.85,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF8981DF) : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedDepth = depth;
                                      });
                                      _updateProgress();
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected ? const Color(0xFF8981DF) : Colors.grey.shade200,
                                              border: Border.all(
                                                color: isSelected ? const Color(0xFF8981DF) : Colors.grey.shade300,
                                                width: 2,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 16,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              depth,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isSelected ? const Color(0xFF8981DF) : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Save Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40.0,
            left: 16.0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Save Success Animation Overlay
          if (showSaveAnimation)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Lottie.asset(
                  'assets/icon/done.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DepthIndicator extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int position;

  const _DepthIndicator({
    super.key,
    required this.label,
    required this.isSelected,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFF8981DF) : Colors.grey.shade300,
        border: Border.all(
          color: isSelected ? const Color(0xFF8981DF) : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              size: 12,
              color: Colors.white,
            )
          : null,
    );
  }
}
