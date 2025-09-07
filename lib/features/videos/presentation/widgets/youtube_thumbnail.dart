import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/util_service.dart';
import '../../../../core/theme/app_colors.dart';

class YouTubeThumbnailImage extends StatefulWidget {
  final String videoId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const YouTubeThumbnailImage({
    super.key,
    required this.videoId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<YouTubeThumbnailImage> createState() => _YouTubeThumbnailImageState();
}

class _YouTubeThumbnailImageState extends State<YouTubeThumbnailImage> {
  int _currentQualityIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (!YouTubeThumbnailUtils.isValidVideoId(widget.videoId)) {
      return _buildErrorWidget();
    }

    final thumbnailUrls = YouTubeThumbnailUtils.getAllThumbnailUrls(widget.videoId);

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: thumbnailUrls[_currentQualityIndex],
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => widget.placeholder ?? _buildPlaceholder(),
        errorWidget: (context, url, error) {
          // Try next quality if current one fails
          if (_currentQualityIndex < thumbnailUrls.length - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentQualityIndex++;
                });
              }
            });
            return _buildPlaceholder();
          }

          // All qualities failed, show error widget
          return widget.errorWidget ?? _buildErrorWidget();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 40,
              color: AppColors.primaryGreen.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Video',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
