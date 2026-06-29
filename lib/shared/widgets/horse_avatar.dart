import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HorseAvatar extends StatelessWidget {
  final String? photoPath;
  final double radius;

  const HorseAvatar({super.key, this.photoPath, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    if (photoPath != null) {
      final file = File(photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
        );
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.3),
      child: Icon(Icons.pets, color: AppColors.primary, size: radius),
    );
  }
}

class OwnerAvatar extends StatelessWidget {
  final double radius;
  const OwnerAvatar({super.key, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surfaceContainerHigh,
      child: Icon(Icons.person_outline, color: AppColors.onSurfaceVariant, size: radius),
    );
  }
}
