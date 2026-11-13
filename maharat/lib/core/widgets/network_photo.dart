import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A rounded photo tile with loading and failure states. Tapping opens it full
/// screen.
class NetworkPhoto extends StatelessWidget {
  final String url;
  final double width;
  final double height;

  const NetworkPhoto({
    super.key,
    required this.url,
    required this.width,
    required this.height,
  });

  void _openFullScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: width,
          height: height,
          color: AppColors.lightMint,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal strip of job photos. Renders nothing when there are none.
class JobPhotoStrip extends StatelessWidget {
  final List<String> urls;

  const JobPhotoStrip({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, index) =>
              NetworkPhoto(url: urls[index], width: 72, height: 72),
        ),
      ),
    );
  }
}
