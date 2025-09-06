

import 'package:flutter/material.dart';

import '../../../shared/widgets/loading_indicator.dart';

class VideoCardShimmer extends StatelessWidget {
  const VideoCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail shimmer
          const SkeletonLoader(
            width: double.infinity,
            height: 200,
            borderRadius: 16,
          ),

          // Content shimmer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 16,
                  borderRadius: (4),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 14,
                  borderRadius: (4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SkeletonLoader(
                      width: 24,
                      height: 24,
                      borderRadius: (12),
                    ),
                    const SizedBox(width: 8),
                    SkeletonLoader(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 12,
                      borderRadius: (4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}