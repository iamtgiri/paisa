import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/isar_service.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../widgets/shared_widgets.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final Transaction? existing; // null = new transaction

  const AddTransactionSheet({super.key, this.existing});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  TransactionType _type = TransactionType.expense;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String? _paymentAccountId;
  bool _isFavorite = false;
  bool _isSaving = false;

  List<Category> _expenseCats = [];
  List<Category> _incomeCats = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _descCtrl.text = e.description;
      _tagsCtrl.text = e.tags.join(', ');
      _type = e.type;
      _selectedDate = e.date;
      _paymentAccountId = e.paymentAccountId;
      _isFavorite = e.isFavorite;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  Future<void> _loadCategories() async {
    final exp = await IsarService.instance.getExpenseCategories();
    final inc = await IsarService.instance.getIncomeCategories();
    final all = await IsarService.instance.getAllCategories();
    if (!mounted) return;
    setState(() {
      _expenseCats = exp;
      _incomeCats = inc;
      // Set selected category
      final e = widget.existing;
      if (e != null) {
        final cats = e.isExpense ? exp : inc;
        final historical = all.where((c) => c.id == e.categoryId).firstOrNull;
        if (historical != null && !cats.any((c) => c.id == historical.id)) {
          cats.add(historical);
        }
        _selectedCategory =
            cats.where((c) => c.id == e.categoryId).firstOrNull ??
                cats.firstOrNull;
      } else {
        _selectedCategory = exp.firstOrNull;
      }
    });
  }

  List<Category> get _currentCats =>
      _type == TransactionType.expense ? _expenseCats : _incomeCats;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')));
      return;
    }

    final accounts = ref.read(accountsProvider);
    final selectedAccountId = _resolveSelectedAccountId(accounts);
    if (selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an account first')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final cat = _selectedCategory!;
    Transaction txn;
    if (widget.existing != null) {
      txn = widget.existing!.copyWith(
        amount: amount,
        categoryId: cat.id,
        categoryName: cat.name,
        categoryColor: cat.colorValue,
        categoryIcon: cat.icon,
        date: _selectedDate,
        description: _descCtrl.text.trim(),
        paymentAccountId: selectedAccountId,
        paymentMethod: _paymentMethodForAccount(accounts, selectedAccountId),
        type: _type,
        tags: tags,
        isFavorite: _isFavorite,
      );
    } else {
      txn = Transaction.create(
        amount: amount,
        categoryId: cat.id,
        categoryName: cat.name,
        categoryColor: cat.colorValue,
        categoryIcon: cat.icon,
        date: _selectedDate,
        description: _descCtrl.text.trim(),
        paymentAccountId: selectedAccountId,
        paymentMethod: _paymentMethodForAccount(accounts, selectedAccountId),
        type: _type,
        tags: tags,
        isFavorite: _isFavorite,
      );
    }

    await IsarService.instance.saveTransaction(txn);
    await ref.read(accountsProvider.notifier).replaceTransaction(
          previous: widget.existing,
          next: txn,
        );
    HapticFeedback.lightImpact();
    ref.read(transactionsRefreshProvider.notifier).refresh();

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _selectedDate.hour,
            _selectedDate.minute,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final accounts = ref.watch(accountsProvider);
    final selectedAccountId = _resolveSelectedAccountId(accounts);

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Transaction' : 'Add Transaction',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Scrollable form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + kb),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type toggle
                    _buildTypeToggle(),
                    const SizedBox(height: 16),
                    // Amount
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: _type == TransactionType.income
                                ? AppTheme.income
                                : AppTheme.expense,
                          ),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _type == TransactionType.income
                              ? AppTheme.income
                              : AppTheme.expense,
                        ),
                        hintText: '0.00',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter an amount';
                        final d = double.tryParse(v);
                        if (d == null || d <= 0) return 'Enter a valid amount';
                        return null;
                      },
                      autofocus: !isEdit,
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    // Category
                    _buildLabel('Category'),
                    const SizedBox(height: 8),
                    _buildCategoryPicker(),
                    const SizedBox(height: 16),
                    // Description
                    _buildLabel('Description (optional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Lunch at canteen',
                        prefixIcon: Icon(Icons.notes_outlined, size: 18),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 16),
                    // Date and Payment
                    Row(
                      children: [
                        Expanded(child: _buildDatePicker()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPaymentAccountPicker(
                            accounts,
                            selectedAccountId,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tags
                    _buildLabel('Tags (optional, comma separated)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tagsCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. college, trip, friends',
                        prefixIcon: Icon(Icons.label_outline, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Favorite toggle
                    _buildFavoriteToggle(),
                    const SizedBox(height: 24),
                    // Save button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : Text(isEdit
                              ? 'Update Transaction'
                              : 'Add Transaction'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _typeBtn(TransactionType.expense, 'Expense',
              Icons.arrow_upward_rounded, AppTheme.expense),
          _typeBtn(TransactionType.income, 'Income',
              Icons.arrow_downward_rounded, AppTheme.income),
        ],
      ),
    );
  }

  Widget _typeBtn(TransactionType t, String label, IconData icon, Color color) {
    final selected = _type == t;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = t;
            _selectedCategory = _currentCats.firstOrNull;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected ? Border.all(color: color.withOpacity(0.3)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? color : context.appColors.onSurfaceMuted),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : context.appColors.onSurfaceMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    if (_currentCats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _currentCats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = _currentCats[i];
          final selected = _selectedCategory?.id == cat.id;
          return CategoryChip(
            category: cat,
            selected: selected,
            onTap: () => setState(() => _selectedCategory = cat),
          );
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: context.appColors.onSurfaceMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat('d MMM y').format(_selectedDate),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _resolveSelectedAccountId(List<Account> accounts) {
    bool exists(String? id) =>
        id != null && accounts.any((account) => account.id == id);

    if (exists(_paymentAccountId)) return _paymentAccountId;
    if (exists(widget.existing?.paymentAccountId)) {
      return widget.existing!.paymentAccountId;
    }
    if (widget.existing == null && accounts.isNotEmpty) {
      return accounts.first.id;
    }
    if (widget.existing?.paymentMethod == PaymentMethod.cash) {
      for (final account in accounts) {
        if (account.isCash) return account.id;
      }
    }
    return null;
  }

  PaymentMethod _paymentMethodForAccount(
      List<Account> accounts, String accountId) {
    for (final account in accounts) {
      if (account.id == accountId) {
        return account.isCash ? PaymentMethod.cash : PaymentMethod.other;
      }
    }
    return PaymentMethod.other;
  }

  Widget _buildPaymentAccountPicker(
      List<Account> accounts, String? selectedAccountId) {
    if (accounts.isEmpty) {
      return Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appColors.divider),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          'Add an account first',
          style:
              TextStyle(fontSize: 13, color: context.appColors.onSurfaceMuted),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.divider),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedAccountId,
        isExpanded: true,
        dropdownColor: context.appColors.surfaceCard2,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          filled: false,
        ),
        items: accounts
            .map(
              (account) => DropdownMenuItem(
                value: account.id,
                child: Row(
                  children: [
                    Icon(
                      AppUtils.iconFromHex(account.icon),
                      size: 16,
                      color: AppUtils.colorFromValue(account.colorValue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        account.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _paymentAccountId = v),
      ),
    );
  }

  Widget _buildFavoriteToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isFavorite = !_isFavorite),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isFavorite
              ? Color(0xFFFFB74D).withOpacity(0.1)
              : context.appColors.surfaceCard2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFavorite
                ? Color(0xFFFFB74D).withOpacity(0.3)
                : context.appColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              size: 18,
              color: _isFavorite
                  ? Color(0xFFFFB74D)
                  : context.appColors.onSurfaceMuted,
            ),
            const SizedBox(width: 10),
            Text(
              'Save as Favorite',
              style: TextStyle(
                color: _isFavorite
                    ? Color(0xFFFFB74D)
                    : context.appColors.onSurfaceMuted,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              'Quick re-add later',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
    );
  }
}
