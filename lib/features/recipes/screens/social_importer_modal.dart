import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/recipes_provider.dart';
import 'recipe_detail_screen.dart';

class SocialImporterModal extends ConsumerStatefulWidget {
  const SocialImporterModal({super.key});

  @override
  ConsumerState<SocialImporterModal> createState() => _SocialImporterModalState();
}

class _SocialImporterModalState extends ConsumerState<SocialImporterModal> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final text = _urlController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recipe = await GeminiAIService.importRecipeFromSocialMedia(linkOrText: text);
      ref.read(recipesProvider.notifier).addRecipe(recipe);

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Не удалось распознать рецепт. Попробуйте другую ссылку.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 24),
              ),
              const SizedBox(width: 12),
              Text('AI Импорт из соцсетей', style: AppTypography.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Вставьте ссылку на видео из Instagram Reels, TikTok, YouTube или страницу с рецептом. Sprout мгновенно расшифрует ингредиенты и тайминги.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://instagram.com/reel/... или tiktok.com/@...',
              prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded, size: 20),
                tooltip: 'Вставить из буфера',
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _urlController.text = data!.text!;
                  }
                },
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(_errorMessage!, style: const TextStyle(color: AppColors.urgentExpiring, fontSize: 13)),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _import,
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('ИИ расшифровывает видео...'),
                      ],
                    )
                  : const Text('Расшифровать и добавить рецепт ✨'),
            ),
          ),
        ],
      ),
    );
  }
}
