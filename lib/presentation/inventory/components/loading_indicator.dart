import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final bool isProcessingImages;
  final int imageCount;

  const LoadingIndicator({
    super.key,
    required this.isProcessingImages,
    this.imageCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (isProcessingImages) ...[
            const SizedBox(height: 16),
            Text(
              'Processing images...',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              imageCount > 1 
                  ? 'Processing $imageCount images'
                  : 'This may take a moment',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
} 