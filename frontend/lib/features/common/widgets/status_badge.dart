import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.primaryContainer;
    Color fg = AppColors.primary;

    final lower = label.toLowerCase();
    if (lower == 'professional') {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1D4ED8);
    } else if (lower == 'cultural') {
      bg = const Color(0xFFEDE9FE);
      fg = const Color(0xFF6D28D9);
    } else if (lower == 'private') {
      bg = const Color(0xFFFCE7F3);
      fg = const Color(0xFFBE185D);
    } else if (lower == 'accepted' || lower == 'completed' || lower == 'attended') {
      bg = AppColors.successContainer;
      fg = AppColors.success;
    } else if (lower == 'pending') {
      bg = AppColors.warningContainer;
      fg = AppColors.warning;
    } else if (lower == 'rejected' || lower == 'redflag') {
      bg = AppColors.errorContainer;
      fg = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor ?? fg,
        ),
      ),
    );
  }
}
