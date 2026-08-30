import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  final bool showOnlineBadge;
  final bool isOnline;

  const AppAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.size = 48,
    this.showOnlineBadge = false,
    this.isOnline = true,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'S';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValidUrl = photoUrl != null &&
        photoUrl!.trim().isNotEmpty &&
        (photoUrl!.startsWith('http://') || photoUrl!.startsWith('https://'));

    final avatarWidget = ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: hasValidUrl
            ? Image.network(
                photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildFallback();
                },
              )
            : _buildFallback(),
      ),
    );

    if (!showOnlineBadge) return avatarWidget;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarWidget,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.primary : AppColors.textTertiary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.40,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
