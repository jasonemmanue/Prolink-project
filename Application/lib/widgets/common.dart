import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool textVisible;
  const AppLogo({super.key, this.size = 40, this.textVisible = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset('assets/images/logo.png',
              width: size, height: size, fit: BoxFit.contain),
        ),
        if (textVisible) ...[
          const SizedBox(width: 10),
          Text(
            'ProLink',
            style: TextStyle(
              fontSize: size * 0.55,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
        ]
      ],
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  final int level; // 0..3
  const VerifiedBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    if (level == 0) return const SizedBox.shrink();
    final config = {
      1: (Colors.blue, Icons.verified, 'Vérifié'),
      2: (AppColors.accent, Icons.verified, 'Premium'),
      3: (Colors.purple, Icons.workspace_premium, 'Expert'),
    }[level]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: config.$1.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.$2, size: 12, color: config.$1),
          const SizedBox(width: 3),
          Text(config.$3,
              style: TextStyle(
                  fontSize: 10, color: config.$1, fontWeight: FontWeight.w600))
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String url;
  final double size;
  const Avatar({super.key, required this.url, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: AppColors.surface,
          width: size,
          height: size,
        ),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.surface,
          width: size,
          height: size,
          child: const Icon(Icons.person, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  const Pill({super.key, required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4)
        ],
        Text(label,
            style: TextStyle(
                fontSize: 12, color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

String formatXaf(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '${buf.toString()} XAF';
}
