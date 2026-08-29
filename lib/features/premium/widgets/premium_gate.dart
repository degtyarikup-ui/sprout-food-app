import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/premium_provider.dart';
import '../screens/paywall_modal.dart';

class PremiumGate {
  static Future<bool> check(
    BuildContext context,
    WidgetRef ref, {
    String? featureName,
  }) async {
    final isPremium = ref.read(premiumProvider).isPremium;
    if (isPremium) {
      return true;
    }

    final activated = await PaywallModal.show(context, featureName: featureName);
    return activated;
  }
}
