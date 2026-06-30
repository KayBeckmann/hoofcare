import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class KategorieBadge extends StatelessWidget {
  final String kategorie;
  const KategorieBadge({super.key, required this.kategorie});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kategorie) {
      'A' => (AppColors.chipRegular, AppColors.chipRegularText),
      'C' => (AppColors.chipAkut, AppColors.chipAkutText),
      _ => (AppColors.chipGeplant, AppColors.chipGeplantText),
    };

    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        kategorie,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
