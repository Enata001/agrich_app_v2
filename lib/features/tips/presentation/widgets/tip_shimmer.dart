import 'package:flutter/material.dart';

import '../../../shared/widgets/loading_indicator.dart';

class TipCardShimmer extends StatelessWidget {
  const TipCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: const SkeletonLoader(
        width: double.infinity,
        height: 120,
      ),
    );
  }
}