import 'package:flutter/material.dart';

class TrendingTopicsWidget extends StatefulWidget {
  final List<String> topics;
  final String? selectedTopic;
  final void Function(String topic) onTopicSelected;

  const TrendingTopicsWidget({
    super.key,
    required this.topics,
    required this.onTopicSelected,
    this.selectedTopic,
  });

  @override
  State<TrendingTopicsWidget> createState() => _TrendingTopicsWidgetState();
}

class _TrendingTopicsWidgetState extends State<TrendingTopicsWidget> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isPaused = false;
  double _scrollPosition = 0;
  double _maxScroll = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    if (widget.topics.isEmpty) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      _maxScroll = _scrollController.position.maxScrollExtent;
      _animateScroll();
    });
  }

  void _animateScroll() {
    if (!mounted || _isPaused) return;

    _scrollPosition += 0.5;
    if (_scrollPosition >= _maxScroll) {
      _scrollPosition = 0;
    }

    _scrollController.animateTo(
      _scrollPosition,
      duration: const Duration(milliseconds: 20),
      curve: Curves.linear,
    ).then((_) {
      if (mounted && !_isPaused) {
        _animateScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.topics.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '🔥 Trending Topics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTapDown: (_) => setState(() => _isPaused = true),
            onTapUp: (_) => setState(() {
              _isPaused = false;
              _animateScroll();
            }),
            onTapCancel: () => setState(() {
              _isPaused = false;
              _animateScroll();
            }),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: widget.topics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final topic = widget.topics[index];
                  final isSelected = topic == widget.selectedTopic;

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: const Color(0xFF6B4EFF).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: ActionChip(
                      label: Text(
                        topic,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF6B4EFF),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: isSelected ? const Color(0xFF6B4EFF) : const Color(0xFFE8E4FF),
                      onPressed: () => widget.onTopicSelected(topic),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
