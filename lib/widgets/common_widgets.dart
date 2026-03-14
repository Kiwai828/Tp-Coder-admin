import 'package:flutter/material.dart';
import '../config/theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color; String text;
    switch (status) {
      case 'success': case 'completed': color = AppColors.accentGreen; text = 'Success'; break;
      case 'failed': color = AppColors.accentRed; text = 'Failed'; break;
      case 'building': color = AppColors.accentYellow; text = 'Building'; break;
      default: color = AppColors.primaryLight; text = 'Active';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final IconData? icon;
  const GradientButton({super.key, required this.text, required this.onPressed, this.isLoading = false, this.width, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity, height: 50,
      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Material(color: Colors.transparent, child: InkWell(onTap: isLoading ? null : onPressed, borderRadius: BorderRadius.circular(12),
        child: Center(child: isLoading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
              Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ])))),
    );
  }
}

class ProjectTypeIcon extends StatelessWidget {
  final String type;
  final double size;
  const ProjectTypeIcon({super.key, required this.type, this.size = 40});

  @override
  Widget build(BuildContext context) {
    IconData icon; Color color;
    switch (type) {
      case 'website': icon = Icons.language; color = AppColors.accent; break;
      case 'android': icon = Icons.android; color = AppColors.accentGreen; break;
      case 'ios': icon = Icons.apple; color = Colors.white70; break;
      default: icon = Icons.code; color = AppColors.primaryLight;
    }
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.buttonText, this.onButtonPressed});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: AppColors.primaryLight, size: 28)),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.darkTextMuted)),
      if (buttonText != null && onButtonPressed != null) ...[const SizedBox(height: 20), GradientButton(text: buttonText!, onPressed: onButtonPressed!, width: 180)],
    ])));
  }
}

String timeAgo(DateTime dt) {
  final d = DateTime.now().difference(dt);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  return '${d.inDays}d';
}
