import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../../models/isar_service.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../widgets/shared_widgets.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(categoriesRefreshProvider);
    final allAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter categories',
            initialValue: _statusFilter,
            onSelected: (value) => setState(() => _statusFilter = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('All categories')),
              PopupMenuItem(value: 'enabled', child: Text('Enabled only')),
              PopupMenuItem(value: 'disabled', child: Text('Disabled only')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceMuted,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: allAsync.when(
        data: (cats) {
          final expense = cats.where((c) => c.isExpense).toList();
          final income = cats.where((c) => !c.isExpense).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search categories',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildList(expense, isExpense: true),
                    _buildList(income, isExpense: false),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const ShimmerList(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'cat_fab',
        onPressed: () =>
            _showCategorySheet(context, null, isExpense: _tabCtrl.index == 0),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(List<Category> cats, {required bool isExpense}) {
    final visible = cats.where((cat) {
      final matchesQuery = _query.isEmpty ||
          cat.name.toLowerCase().contains(_query.toLowerCase());
      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'enabled' && cat.enabled) ||
          (_statusFilter == 'disabled' && !cat.enabled);
      return matchesQuery && matchesStatus;
    }).toList();
    if (visible.isEmpty) {
      return EmptyState(
        icon: Icons.category_outlined,
        title: cats.isEmpty ? 'No categories' : 'No matching categories',
        subtitle: cats.isEmpty
            ? 'Tap + to create a category'
            : 'Try another search or filter',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final cat = visible[i];
        return _CategoryTile(
          category: cat,
          onEdit: () => _showCategorySheet(context, cat, isExpense: isExpense),
          onToggle: () => _toggleCategory(cat),
          onDelete: cat.isDefault ? null : () => _deleteCategory(context, cat),
        );
      },
    );
  }

  Future<void> _toggleCategory(Category cat) async {
    await IsarService.instance.setCategoryEnabled(cat.id, !cat.enabled);
    _refreshCategories();
  }

  void _refreshCategories() {
    ref.read(categoriesRefreshProvider.notifier).refresh();
    ref.invalidate(categoriesProvider);
    ref.invalidate(expenseCategoriesProvider);
    ref.invalidate(incomeCategoriesProvider);
  }

  Future<void> _showCategorySheet(BuildContext context, Category? existing,
      {required bool isExpense}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(
        existing: existing,
        defaultIsExpense: isExpense,
      ),
    );
    _refreshCategories();
  }

  Future<void> _deleteCategory(BuildContext context, Category cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            'Delete "${cat.name}"? Existing transactions will keep their category name.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await IsarService.instance.deleteCategory(cat.id);
      _refreshCategories();
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggle;

  const _CategoryTile(
      {required this.category, this.onEdit, this.onDelete, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cat = category;
    return Opacity(
      opacity: cat.enabled ? 1 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CategoryBadge(
              icon: cat.icon, colorValue: cat.colorValue, size: 42),
          title: Text(cat.name,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Row(
            children: [
              if (cat.isDefault)
                const Text('Default',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.onSurfaceMuted)),
              if (cat.isDefault && !cat.enabled)
                const Text(' · ',
                    style: TextStyle(color: AppTheme.onSurfaceMuted)),
              if (!cat.enabled)
                const Text('Disabled',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.onSurfaceMuted)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  color: AppTheme.onSurfaceMuted,
                ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                  color: AppTheme.expense.withOpacity(0.7),
                ),
              Switch(
                value: cat.enabled,
                onChanged: (_) => onToggle?.call(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  final Category? existing;
  final bool defaultIsExpense;

  const _CategoryFormSheet({this.existing, required this.defaultIsExpense});

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _nameCtrl = TextEditingController();
  bool _isExpense = true;
  int _selectedColor = 0xFFE53935;
  String _selectedIcon = 'e25a';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _isExpense = e.isExpense;
      _selectedColor = e.colorValue;
      _selectedIcon = e.icon;
    } else {
      _isExpense = widget.defaultIsExpense;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final kb = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + kb),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEdit ? 'Edit Category' : 'New Category',
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            // Preview
            Center(
              child: CategoryBadge(
                  icon: _selectedIcon, colorValue: _selectedColor, size: 64),
            ),
            const SizedBox(height: 20),
            // Name
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Food & Dining',
                prefixIcon: Icon(Icons.label_outline, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            // Type toggle (only for new)
            if (!isEdit) ...[
              Row(
                children: [
                  Expanded(
                    child: _typeBtn(true, 'Expense', Icons.arrow_upward_rounded,
                        AppTheme.expense),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeBtn(false, 'Income',
                        Icons.arrow_downward_rounded, AppTheme.income),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Color picker
            _buildSectionLabel('COLOR'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppUtils.categoryColors.map((c) {
                final selected = _selectedColor == c.$2;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c.$2),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(c.$2),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: AppTheme.onSurface, width: 2.5)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Icon picker
            _buildSectionLabel('ICON'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppUtils.categoryIcons.map((ic) {
                final selected = _selectedIcon == ic.$2;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = ic.$2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? Color(_selectedColor).withOpacity(0.15)
                          : AppTheme.surfaceCard2,
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(color: Color(_selectedColor), width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      AppUtils.iconFromHex(ic.$2),
                      size: 20,
                      color: selected
                          ? Color(_selectedColor)
                          : AppTheme.onSurfaceMuted,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : Text(isEdit ? 'Update Category' : 'Create Category'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(bool isExpense, String label, IconData icon, Color color) {
    final sel = _isExpense == isExpense;
    return GestureDetector(
      onTap: () => setState(() => _isExpense = isExpense),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.12) : AppTheme.surfaceCard2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: sel ? color : AppTheme.onSurfaceMuted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: sel ? color : AppTheme.onSurfaceMuted,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceMuted,
            letterSpacing: 0.8));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a category name')));
      return;
    }
    setState(() => _saving = true);

    Category cat;
    if (widget.existing != null) {
      cat = widget.existing!.copyWith(
        name: name,
        colorValue: _selectedColor,
        icon: _selectedIcon,
      );
    } else {
      cat = Category.create(
        name: name,
        colorValue: _selectedColor,
        icon: _selectedIcon,
        isExpense: _isExpense,
      );
    }

    await IsarService.instance.saveCategory(cat);
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }
}
