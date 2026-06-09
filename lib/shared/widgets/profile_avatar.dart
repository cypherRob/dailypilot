import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.fallbackIcon = Icons.person_outline,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl?.trim();
    final size = radius * 2;

    if (cleanUrl == null || cleanUrl.isEmpty) {
      return _fallback(context, size);
    }

    return ClipOval(
      child: Image.network(
        cleanUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(context, size),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _fallback(context, size);
        },
      ),
    );
  }

  Widget _fallback(BuildContext context, double size) {
    return CircleAvatar(
      radius: radius,
      child: Icon(fallbackIcon, size: size * 0.5),
    );
  }
}
