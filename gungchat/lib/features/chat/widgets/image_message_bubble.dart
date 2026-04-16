import 'package:flutter/material.dart';

class ImageMessageBubble extends StatelessWidget {
  const ImageMessageBubble({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_outlined),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
