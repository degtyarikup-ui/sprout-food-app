import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../family/providers/family_provider.dart';
import '../../family/screens/family_modals.dart';
import '../../onboarding/screens/onboarding_quiz_screen.dart';
import '../../premium/providers/premium_provider.dart';
import '../../premium/screens/paywall_modal.dart';
import '../models/user_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/user_preferences_provider.dart';
import 'preferences_modal.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController(text: GeminiAIService.apiKey);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Ключ Gemini API', style: AppTypography.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Укажите свой собственный ключ Gemini API для неограниченной генерации.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'AIzaSy...',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryForeground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () async {
                  final key = controller.text.trim();
                  if (key.isNotEmpty) {
                    await GeminiAIService.setApiKey(key);
                  }
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        content: Text('API-ключ успешно сохранен!'),
                      ),
                    );
                  }
                },
                child: const Text('Сохранить', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final premium = ref.watch(premiumProvider);
    final userPrefs = ref.watch(userPreferencesProvider);
    final family = ref.watch(familyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Профиль', style: AppTypography.displayMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // ── 1. User Header Card ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: user != null
                  ? Row(
                      children: [
                        AppAvatar(
                          photoUrl: user.photoUrl,
                          name: user.displayName,
                          size: 56,
                          showOnlineBadge: true,
                          isOnline: true,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.displayName,
                                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    user.authProviderType == 'telegram'
                                        ? Icons.send_rounded
                                        : Icons.check_circle_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (user.authProviderType == 'telegram') ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Telegram Mini App',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Войдите в аккаунт',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Синхронизируйте холодильник, меню и подписку на всех устройствах',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.surfaceMuted,
                                    foregroundColor: AppColors.textPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.g_mobiledata_rounded, size: 24, color: AppColors.primary),
                                  label: const Text('Google', style: TextStyle(fontWeight: FontWeight.w700)),
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    await ref.read(authProvider.notifier).signInWithGoogle();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                    foregroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.send_rounded, size: 18, color: AppColors.primary),
                                  label: const Text('Telegram', style: TextStyle(fontWeight: FontWeight.w700)),
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    await ref.read(authProvider.notifier).signInWithTelegramDemo();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),

            // ── 2. Family Sharing Group Card ───────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: family != null
                    ? AppColors.surface
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: family != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.family_restroom_rounded, size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        family.name,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${family.members.length} чел',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Общий холодильник и меню синхронизированы',
                                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Members list with avatars
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: family.members.map((member) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppAvatar(
                                    photoUrl: member.avatarUrl,
                                    name: member.name,
                                    size: 26,
                                    showOnlineBadge: true,
                                    isOnline: member.isOnline,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    member.name,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${member.role})',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Invite Partner / Manage
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.primaryForeground,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.share_rounded, size: 16),
                                  label: const Text('Пригласить партнера', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    FamilyModals.showInvitePartner(context, ref);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.exit_to_app_rounded, size: 20, color: AppColors.textTertiary),
                              tooltip: 'Покинуть семью',
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                await ref.read(familyProvider.notifier).leaveFamily();
                              },
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.family_restroom_rounded, size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Семейный доступ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                SizedBox(height: 2),
                                Text(
                                  'Совместный холодильник и меню для двоих',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.primaryForeground,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    FamilyModals.showCreateFamily(context, ref);
                                  },
                                  child: const Text('Создать семью', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.surfaceMuted,
                                    foregroundColor: AppColors.textPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    FamilyModals.showJoinFamily(context, ref);
                                  },
                                  child: const Text('Войти по коду', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),

            // ── 3. Premium Subscription Status Card ────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: premium.isPremium
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: premium.isPremium ? AppColors.primary : AppColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 20,
                          color: premium.isPremium ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              premium.isPremium ? 'Sprout Премиум активен' : 'Базовый тариф',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: premium.isPremium ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              premium.isPremium
                                  ? 'Тариф: ${premium.planName ?? 'Годовой'}'
                                  : 'Доступ к Шеф-ИИ сканеру и рецептам ограничен',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (!premium.isPremium)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.primaryForeground,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          PaywallModal.show(context);
                        },
                        child: const Text('Попробовать 7 дней бесплатно', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Все ИИ-функции разблокированы',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                        TextButton(
                          onPressed: () {
                            PaywallModal.show(context);
                          },
                          child: const Text('Тариф', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 4. Settings Sections ───────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.tune_rounded,
                    title: 'Персонализация питания',
                    subtitle: '${userPrefs.defaultServings} чел • ${userPrefs.diet.label}',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const PreferencesModal(),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildProfileTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Пересоставить рацион с нуля',
                    subtitle: 'Пройти онбординг-квиз заново',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OnboardingQuizScreen()),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildProfileTile(
                    icon: Icons.key_rounded,
                    title: 'Ключ Gemini API',
                    subtitle: GeminiAIService.hasApiKey ? 'Ключ подключен' : 'Не указан',
                    onTap: () => _showApiKeyDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 5. Logout Button ───────────────────────────────────────
            if (user != null)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _buildProfileTile(
                  icon: Icons.logout_rounded,
                  title: 'Выйти из аккаунта',
                  isDestructive: true,
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await ref.read(authProvider.notifier).signOut();
                  },
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.statusUrgent.withValues(alpha: 0.12)
              : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDestructive ? AppColors.statusUrgent : AppColors.textPrimary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDestructive ? AppColors.statusUrgent : AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: isDestructive
          ? null
          : const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textTertiary),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 18),
      child: Container(
        height: 1,
        color: AppColors.surfaceMuted,
      ),
    );
  }
}
