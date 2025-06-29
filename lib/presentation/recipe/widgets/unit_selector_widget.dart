import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saucerer_flutter/domain/entities/seasoning_entity.dart';
import 'package:saucerer_flutter/domain/entities/category_entity.dart';
import 'package:saucerer_flutter/domain/usecases/create_seasoning_usecase.dart';
import 'package:saucerer_flutter/presentation/recipe/providers/units_provider.dart';
import 'package:saucerer_flutter/presentation/recipe/widgets/unit_category_dialog.dart';

class UnitSelectorWidget extends ConsumerStatefulWidget {
  final String selectedUnit;
  final Function(String) onUnitChanged;
  final InputDecoration? decoration;

  const UnitSelectorWidget({
    super.key,
    required this.selectedUnit,
    required this.onUnitChanged,
    this.decoration,
  });

  @override
  ConsumerState<UnitSelectorWidget> createState() => _UnitSelectorWidgetState();
}

class _UnitSelectorWidgetState extends ConsumerState<UnitSelectorWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.selectedUnit;
  }

  @override
  void didUpdateWidget(UnitSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUnit != widget.selectedUnit) {
      _controller.text = widget.selectedUnit;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createNewUnit(String name) async {
    // 카테고리 선택 다이얼로그 표시
    final selectedCategory = await UnitCategoryDialogs.show(
      context,
      unitName: name,
    );

    if (selectedCategory == null) return; // 사용자가 취소한 경우

    try {
      final createUseCase = ref.read(createSeasoningUseCaseProvider);
      await createUseCase(
        name: name,
        categoryId: PredefinedCategories.unit.id,
        subCategory: selectedCategory,
        description: '사용자 추가 단위',
      );

      // 단위 목록 새로고침 - Provider를 통해
      ref.read(availableUnitsProvider.notifier).refresh();

      // 새로 생성된 단위 선택
      widget.onUnitChanged(name);
      _controller.text = name;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('새 단위 "$name"이(가) $selectedCategory 카테고리에 추가되었습니다')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _selectUnit(String unit) {
    widget.onUnitChanged(unit);
    _controller.text = unit;
  }

  Future<void> _showUnitBottomSheet() async {
    // 키보드 숨기기
    FocusScope.of(context).unfocus();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final availableUnitsAsync = ref.watch(availableUnitsProvider);
          
          return availableUnitsAsync.when(
            data: (availableUnits) => _UnitBottomSheet(
              availableUnits: availableUnits,
              selectedUnit: widget.selectedUnit,
              onCreateNewUnit: _createNewUnit,
            ),
            loading: () => Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '단위를 불러오는 중 오류가 발생했습니다',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(availableUnitsProvider.notifier).refresh();
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (result != null) {
      _selectUnit(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showUnitBottomSheet,
      child: AbsorbPointer(
        child: TextField(
          controller: _controller,
          decoration:
              widget.decoration ??
              InputDecoration(
                labelText: '단위',
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: const OutlineInputBorder(),
              ),
        ),
      ),
    );
  }
}

class _UnitBottomSheet extends StatefulWidget {
  final List<SeasoningEntity> availableUnits;
  final String selectedUnit;
  final Future<void> Function(String) onCreateNewUnit;

  const _UnitBottomSheet({
    required this.availableUnits,
    required this.selectedUnit,
    required this.onCreateNewUnit,
  });

  @override
  State<_UnitBottomSheet> createState() => _UnitBottomSheetState();
}

class _UnitBottomSheetState extends State<_UnitBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<SeasoningEntity> _filteredUnits = [];

  @override
  void initState() {
    super.initState();
    _filteredUnits = widget.availableUnits;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUnits(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUnits = widget.availableUnits;
      } else {
        _filteredUnits =
            widget.availableUnits
                .where(
                  (unit) =>
                      unit.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  Widget _buildUnitGroup(
    String title,
    List<SeasoningEntity> units, {
    IconData? icon,
  }) {
    if (units.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...units.map(
          (unit) => ListTile(
            leading: Icon(
              Icons.straighten,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(unit.name),
            trailing:
                unit.usageCount > 0
                    ? Text(
                      '${unit.usageCount}회',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                    : null,
            selected: unit.name == widget.selectedUnit,
            onTap: () => Navigator.of(context).pop(unit.name),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 단위들을 세부 카테고리별로 그룹화
    final frequentUnits =
        _filteredUnits.where((u) => u.usageCount > 0).toList()
          ..sort((a, b) => b.usageCount.compareTo(a.usageCount));

    final weightUnits =
        _filteredUnits.where((u) => u.subCategory == '무게').toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final volumeUnits =
        _filteredUnits.where((u) => u.subCategory == '부피').toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final countUnits =
        _filteredUnits.where((u) => u.subCategory == '개수').toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final otherUnits =
        _filteredUnits.where((u) => u.subCategory == '기타' || u.subCategory == null).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              children: [
                // 드래그 핸들
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '단위 선택',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 검색 필드
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '단위 검색...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: _filterUnits,
                ),
              ],
            ),
          ),

          // 단위 목록
          Expanded(
            child: ListView(
              children: [
                if (frequentUnits.isNotEmpty)
                  _buildUnitGroup(
                    '자주 사용하는 단위',
                    frequentUnits.take(5).toList(),
                    icon: Icons.star,
                  ),

                _buildUnitGroup('무게', weightUnits, icon: Icons.monitor_weight),
                _buildUnitGroup('부피', volumeUnits, icon: Icons.local_drink),
                _buildUnitGroup('개수', countUnits, icon: Icons.numbers),
                _buildUnitGroup('기타', otherUnits, icon: Icons.more_horiz),

                // 새 단위 추가 옵션
                if (_searchController.text.trim().isNotEmpty &&
                    !_filteredUnits.any(
                      (u) =>
                          u.name.toLowerCase() ==
                          _searchController.text.trim().toLowerCase(),
                    )) ...[
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.add_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text('새 단위 추가: "${_searchController.text.trim()}"'),
                    subtitle: const Text('새로운 단위를 추가합니다'),
                    onTap: () async {
                      await widget.onCreateNewUnit(
                        _searchController.text.trim(),
                      );
                      if (mounted && context.mounted) {
                        Navigator.of(
                          context,
                        ).pop(_searchController.text.trim());
                      }
                    },
                  ),
                ],

                const SizedBox(height: 100), // 하단 여백
              ],
            ),
          ),
        ],
      ),
    );
  }
}
