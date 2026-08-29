import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum FreshnessCategory {
  urgent,  // 1-2 days left
  soon,    // 3-5 days left
  good,    // 6+ days left
  pantry,  // Long shelf life / frozen
}

extension FreshnessCategoryExtension on FreshnessCategory {
  String get label {
    switch (this) {
      case FreshnessCategory.urgent:
        return 'Срочно съесть (1-2 дня)';
      case FreshnessCategory.soon:
        return 'Скоро истекает (3-5 дней)';
      case FreshnessCategory.good:
        return 'Свежее (6+ дней)';
      case FreshnessCategory.pantry:
        return 'Долгосрочно / Морозилка';
    }
  }

  String get shortLabel {
    switch (this) {
      case FreshnessCategory.urgent:
        return '🔥 Срочно';
      case FreshnessCategory.soon:
        return '⏳ 3-5 дн.';
      case FreshnessCategory.good:
        return '🌱 Свежее';
      case FreshnessCategory.pantry:
        return '❄️ Долго';
    }
  }

  Color get color {
    switch (this) {
      case FreshnessCategory.urgent:
        return AppColors.urgentExpiring;
      case FreshnessCategory.soon:
        return AppColors.soonExpiring;
      case FreshnessCategory.good:
        return AppColors.freshGood;
      case FreshnessCategory.pantry:
        return AppColors.frozenPantry;
    }
  }
}
