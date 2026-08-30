import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/telegram_web_app_service.dart';
import 'core/theme/app_theme.dart';
import 'features/family/providers/family_provider.dart';
import 'features/navigation/main_scaffold.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/onboarding/screens/onboarding_quiz_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Telegram WebApp SDK if running inside Telegram
  TelegramWebAppService.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize date formatting locales
  await initializeDateFormatting('ru', null);

  runApp(
    const ProviderScope(
      child: SproutApp(),
    ),
  );
}

class SproutApp extends ConsumerWidget {
  const SproutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep familyProvider active from the root so auto-sync is always live
    ref.watch(familyProvider);
    final hasCompletedOnboarding = ref.watch(onboardingProvider);

    return MaterialApp(
      title: 'Sprout — Умная Еда',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: hasCompletedOnboarding
          ? const MainScaffold()
          : const OnboardingQuizScreen(),
    );
  }
}
