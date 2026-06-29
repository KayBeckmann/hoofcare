import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum TreatmentStatus { regular, akut, geplant }

TreatmentStatus statusFromString(String s) {
  switch (s.toLowerCase()) {
    case 'akut':
      return TreatmentStatus.akut;
    case 'geplant':
      return TreatmentStatus.geplant;
    default:
      return TreatmentStatus.regular;
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final TreatmentStatus status;

  const StatusChip({super.key, required this.label, required this.status});

  factory StatusChip.fromString(String value) {
    return StatusChip(label: value, status: statusFromString(value));
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      TreatmentStatus.akut => (AppColors.chipAkut, AppColors.chipAkutText),
      TreatmentStatus.geplant => (AppColors.chipGeplant, AppColors.chipGeplantText),
      TreatmentStatus.regular => (AppColors.chipRegular, AppColors.chipRegularText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
