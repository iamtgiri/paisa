import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/transaction.dart';
import '../../models/isar_service.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../widgets/shared_widgets.dart';
import 'add_transaction_sheet.dart';

class TransactionDetailSheet extends ConsumerWidget {
  final Transaction transaction;

  const TransactionDetailSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = transaction;
    final accounts = ref.watch(accountsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CategoryBadge(
                        icon: t.categoryIcon,
                        colorValue: t.categoryColor,
                        size: 52,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.description.isEmpty
                                  ? t.categoryName
                                  : t.description,
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              t.categoryName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      AmountText(
                        amount: t.amount,
                        type: t.type,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _detailRow(context, Icons.calendar_today_outlined, 'Date',
                      AppUtils.formatDateTime(t.date)),
                  _detailRow(
                    context,
                    AppUtils.transactionPaymentIcon(t, accounts),
                    'Payment',
                    AppUtils.transactionPaymentLabel(t, accounts),
                  ),
                  _detailRow(
                      context,
                      t.type == TransactionType.expense
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      'Type',
                      t.type == TransactionType.expense ? 'Expense' : 'Income'),
                  if (t.tags.isNotEmpty)
                    _detailRow(context, Icons.label_outline, 'Tags',
                        t.tags.map((t) => '#$t').join(', ')),
                  if (t.isFavorite)
                    _detailRow(context, Icons.star_rounded, 'Favorite',
                        'Saved as favorite',
                        valueColor: const Color(0xFFFFB74D)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editTransaction(context, ref),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteTransaction(context, ref),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.expense,
                            side: const BorderSide(color: AppTheme.expense),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _duplicateTransaction(context, ref),
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      label: const Text('Duplicate Transaction'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.onSurfaceMuted,
                        side: const BorderSide(color: AppTheme.divider),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
      BuildContext context, IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.onSurfaceMuted),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.onSurfaceMuted, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppTheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editTransaction(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(existing: transaction),
    );
    if (result == true) {
      ref.read(transactionsRefreshProvider.notifier).refresh();
    }
  }

  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('This action cannot be undone.'),
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
      await ref.read(accountsProvider.notifier).reverseTransaction(transaction);
      await IsarService.instance.deleteTransaction(transaction.id);
      ref.read(transactionsRefreshProvider.notifier).refresh();
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _duplicateTransaction(
      BuildContext context, WidgetRef ref) async {
    final t = transaction;
    final dup = Transaction.create(
      amount: t.amount,
      categoryId: t.categoryId,
      categoryName: t.categoryName,
      categoryColor: t.categoryColor,
      categoryIcon: t.categoryIcon,
      date: DateTime.now(),
      description: t.description,
      paymentAccountId: t.paymentAccountId,
      paymentMethod: t.paymentMethod,
      type: t.type,
      tags: List.from(t.tags),
      isFavorite: t.isFavorite,
    );
    await IsarService.instance.saveTransaction(dup);
    await ref.read(accountsProvider.notifier).applyTransaction(dup);
    ref.read(transactionsRefreshProvider.notifier).refresh();
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction duplicated')),
      );
    }
  }
}
