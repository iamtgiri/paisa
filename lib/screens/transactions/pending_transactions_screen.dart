import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/isar_service.dart';
import '../../models/pending_transaction.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../widgets/shared_widgets.dart';

class PendingTransactionsScreen extends ConsumerStatefulWidget {
  const PendingTransactionsScreen({super.key});

  @override
  ConsumerState<PendingTransactionsScreen> createState() =>
      _PendingTransactionsScreenState();
}

class _PendingTransactionsScreenState
    extends ConsumerState<PendingTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingTransactionsProvider.notifier).syncFromAndroid();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingTransactionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Transactions')),
      body: pending.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No pending transactions',
              subtitle:
                  'Captured bank notifications will appear here for review',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _PendingCard(item: pending[index]),
            ),
    );
  }
}

class _PendingCard extends ConsumerWidget {
  final PendingTransaction item;

  const _PendingCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = item.type == TransactionType.income
        ? AppTheme.income
        : AppTheme.expense;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.type == TransactionType.income
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                AppUtils.formatAmount(item.amount),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${item.accountHint}  |  ${AppUtils.formatDateTime(item.date)}',
            style: TextStyle(
              color: context.appColors.onSurfaceMuted,
              fontSize: 12,
            ),
          ),
          if (item.reference != null) ...[
            const SizedBox(height: 4),
            Text(
              'Reference: ${item.reference}',
              style: TextStyle(
                color: context.appColors.onSurfaceMuted,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _discard(context, ref),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Ignore'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _review(context, ref),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Review'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ignore notification?'),
        content: const Text('This notification will not become a transaction.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ignore'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(pendingTransactionsProvider.notifier).remove(item.id);
    }
  }

  Future<void> _review(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PendingReviewSheet(item: item),
    );
  }
}

class _PendingReviewSheet extends ConsumerStatefulWidget {
  final PendingTransaction item;

  const _PendingReviewSheet({required this.item});

  @override
  ConsumerState<_PendingReviewSheet> createState() =>
      _PendingReviewSheetState();
}

class _PendingReviewSheetState extends ConsumerState<_PendingReviewSheet> {
  String? _accountId;
  int? _categoryId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final categoriesAsync = widget.item.type == TransactionType.expense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + keyboardInset),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Review Transaction',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${widget.item.description} - ${AppUtils.formatAmount(widget.item.amount)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appColors.onSurfaceMuted),
            ),
            const SizedBox(height: 20),
            if (accounts.isEmpty)
              const Text('Add an account before confirming this transaction.')
            else ...[
              DropdownButtonFormField<String>(
                value: _accountId ?? accounts.first.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Account',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: accounts
                    .map((account) => DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _accountId = value),
              ),
              const SizedBox(height: 14),
              categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Categories unavailable: $error'),
                data: (categories) => _categoryDropdown(categories),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving || accounts.isEmpty
                    ? null
                    : () => _confirm(context, accounts, categoriesAsync),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Confirm Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryDropdown(List<Category> categories) {
    if (categories.isEmpty) return const Text('Add a category first.');
    final selectedId = _categoryId ?? _suggestedCategoryId(categories);
    return DropdownButtonFormField<int>(
      value: selectedId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: categories
          .map((category) => DropdownMenuItem(
                value: category.id,
                child: Text(category.name, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (value) => setState(() => _categoryId = value),
    );
  }

  int? _suggestedCategoryId(List<Category> categories) {
    final suggested = widget.item.suggestedCategory?.toLowerCase();
    if (suggested == null) return categories.first.id;
    return categories
            .where((category) => category.name.toLowerCase() == suggested)
            .firstOrNull
            ?.id ??
        categories.first.id;
  }

  Future<void> _confirm(
    BuildContext context,
    List<Account> accounts,
    AsyncValue<List<Category>> categoriesAsync,
  ) async {
    final categories = categoriesAsync.valueOrNull;
    if (categories == null || categories.isEmpty) return;
    final accountId = _accountId ?? accounts.first.id;
    final categoryId = _categoryId ?? _suggestedCategoryId(categories)!;
    final category = categories.firstWhere((item) => item.id == categoryId);
    setState(() => _saving = true);

    final transaction = Transaction.create(
      amount: widget.item.amount,
      categoryId: category.id,
      categoryName: category.name,
      categoryColor: category.colorValue,
      categoryIcon: category.icon,
      date: widget.item.date,
      description: widget.item.description,
      paymentAccountId: accountId,
      paymentMethod: widget.item.paymentMethod,
      type: widget.item.type,
      tags: widget.item.reference == null ? [] : [widget.item.reference!],
    );
    await ref.read(transactionsRefreshProvider.notifier).saveWithBalance(
          next: transaction,
          accounts: ref.read(accountsProvider.notifier),
        );
    await ref.read(pendingTransactionsProvider.notifier).remove(widget.item.id);
    if (context.mounted) Navigator.pop(context, true);
  }
}
