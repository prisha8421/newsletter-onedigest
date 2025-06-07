import 'package:flutter/material.dart';

class TrendingTopicsWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (topics.isEmpty) return const SizedBox.shrink();

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
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topics.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final topic = topics[index];
                final isSelected = topic == selectedTopic;

                return ActionChip(
                  label: Text(
                    topic,
                    style: TextStyle(
                      color: isSelected ? Colors.deepPurple : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  backgroundColor: isSelected ? Colors.white : Colors.deepPurple,
                  onPressed: () => onTopicSelected(topic),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
