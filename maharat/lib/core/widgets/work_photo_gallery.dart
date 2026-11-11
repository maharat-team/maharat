import 'package:flutter/material.dart';
import '../../models/worker_model.dart';
import '../constants/app_constants.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../utils/error_messages.dart';
import 'network_photo.dart';

/// A worker's portfolio. Read-only unless [onAdd] and [onDelete] are given.
class WorkPhotoGallery extends StatefulWidget {
  final List<WorkPhoto> photos;
  final Future<void> Function()? onAdd;
  final Future<void> Function(WorkPhoto photo)? onDelete;

  const WorkPhotoGallery({
    super.key,
    required this.photos,
    this.onAdd,
    this.onDelete,
  });

  @override
  State<WorkPhotoGallery> createState() => _WorkPhotoGalleryState();
}

class _WorkPhotoGalleryState extends State<WorkPhotoGallery> {
  bool _isBusy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmDelete(WorkPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('Remove this photo?', 'یہ تصویر ہٹا دیں؟')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('Cancel', 'منسوخ')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ctx.tr('Remove', 'ہٹائیں'),
              style: const TextStyle(color: AppColors.statusRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _run(() => widget.onDelete!(photo));
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _isBusy ? null : () => _run(widget.onAdd!),
      child: Container(
        width: 110,
        margin: const EdgeInsetsDirectional.only(end: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Center(
          child: _isBusy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('Add Photo', 'تصویر شامل کریں'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPhoto(WorkPhoto photo) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: Stack(
        children: [
          NetworkPhoto(url: photo.url, width: 130, height: 110),
          if (widget.onDelete != null)
            PositionedDirectional(
              top: 4,
              end: 4,
              child: GestureDetector(
                onTap: _isBusy ? null : () => _confirmDelete(photo),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.statusRed,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAdd =
        widget.onAdd != null &&
        widget.photos.length < AppConstants.maxWorkPhotos;

    if (widget.photos.isEmpty && !canAdd) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          context.tr(
            'No work photos added yet.',
            'ابھی تک کام کی کوئی تصویر نہیں لگائی گئی۔',
          ),
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (canAdd) _buildAddTile(),
          ...widget.photos.map(_buildPhoto),
        ],
      ),
    );
  }
}
