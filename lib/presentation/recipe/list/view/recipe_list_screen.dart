import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saucerer_flutter/domain/entities/recipe_entity.dart';
import 'package:saucerer_flutter/presentation/recipe/list/viewmodel/recipe_list_viewmodel.dart';
import 'package:saucerer_flutter/core/routes/app_router.dart';
import 'package:saucerer_flutter/core/config/recipe_card_widget.dart';
import 'package:saucerer_flutter/core/config/app_colors.dart';

class RecipeListScreen extends ConsumerWidget {
  final bool showAppBar;

  const RecipeListScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeListState = ref.watch(recipeListViewModelProvider);

    return Scaffold(
      appBar:
          showAppBar
              ? AppBar(
                title: const Text('나의 레시피'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      context.push(AppRoutes.search);
                    },
                    tooltip: '재료로 검색',
                  ),
                ],
              )
              : null,
      body: RefreshIndicator(
        onRefresh:
            () => ref.read(recipeListViewModelProvider.notifier).refresh(),
        child: recipeListState.when(
          data: (recipes) {
            if (recipes.isEmpty) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.lightCream.withValues(alpha: 0.3),
                        AppColors.accent.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 요리 아이콘 그룹
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.restaurant_menu,
                            size: 60,
                            color: AppColors.warmWhite,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
                        '아직 레시피가 없습니다',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textBrown,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      Text(
                        '나만의 특별한 소스 레시피를\n만들어보세요!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textBrown.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // 버튼들
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push(AppRoutes.recipeCreate);
                            },
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('레시피 추가'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              context.push(AppRoutes.search);
                            },
                            icon: const Icon(Icons.search, size: 20),
                            label: const Text('재료 검색'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return RecipeCardWidget(
                  recipe: recipe,
                  onTap: () {
                    context.push('/recipes/${recipe.id}');
                  },
                  onDelete:
                      () => _showDeleteConfirmDialog(context, ref, recipe),
                  heroTag: 'recipe_card_${recipe.id}',
                );
              },
            );
          },
          error: (error, stackTrace) {
            // As per GEMINI.md, display errors using SelectableText.rich
            return Center(
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '오류가 발생했습니다:\n\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: error.toString()),
                  ],
                ),
                style: const TextStyle(color: Colors.red),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            context.push(AppRoutes.recipeCreate);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          splashColor: AppColors.warmWhite.withValues(alpha: 0.2),
          icon: const Icon(Icons.add, color: AppColors.warmWhite, size: 24),
          label: const Text(
            '레시피 추가',
            style: TextStyle(
              color: AppColors.warmWhite,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    RecipeEntity recipe,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('레시피 삭제'),
            content: Text(
              '\'${recipe.name}\' 레시피를 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  try {
                    await ref
                        .read(recipeListViewModelProvider.notifier)
                        .deleteRecipe(recipe.id);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('\'${recipe.name}\' 레시피가 삭제되었습니다'),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('삭제 실패: $error'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
    );
  }
}
