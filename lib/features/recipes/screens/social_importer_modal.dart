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
        _errorMessage = 'Не удалось распознать рецепт. Проверьте ссылку.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Импорт из видео', style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Вставьте ссылку на видео или страницу с рецептом. Сервис извлечет ингредиенты, шаги и тайминги.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://instagram.com/reel/... или tiktok.com/@...',
              prefixIcon: const Icon(Icons.link_rounded, size: 20, color: AppColors.textTertiary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded, size: 18),
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
            Text(_errorMessage!, style: const TextStyle(color: AppColors.statusUrgent, fontSize: 12)),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _import,
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 10),
                        Text('Распознавание...'),
                      ],
                    )
                  : const Text('Импортировать рецепт'),
            ),
          ),
        ],
      ),
    );
  }
}
