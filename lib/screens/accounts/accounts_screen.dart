import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/account.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../widgets/shared_widgets.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          if (accounts.length >= 2)
            TextButton.icon(
              onPressed: () => _showTransferSheet(context, ref, accounts),
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('Transfer'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
        ],
      ),
      body: accounts.isEmpty
          ? EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No accounts yet',
              subtitle: 'Add your cash, bank, or wallet accounts',
              action: ElevatedButton.icon(
                onPressed: () => _showAccountSheet(context, ref, null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Account'),
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Net worth card
                _NetWorthCard(accounts: accounts),
                const SizedBox(height: 20),
                const Text('YOUR ACCOUNTS',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceMuted,
                        letterSpacing: 0.8)),
                const SizedBox(height: 10),
                ...accounts.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AccountCard(
                        account: a,
                        onEdit: () => _showAccountSheet(context, ref, a),
                        onDelete: a.isDefault
                            ? null
                            : () => _deleteAccount(context, ref, a),
                        onAdjust: () => _showAdjustSheet(context, ref, a),
                      ),
                    )),
                // Recent transfers
                _buildTransferHistory(context, ref, accounts),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'acct_fab',
        onPressed: () => _showAccountSheet(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTransferHistory(
      BuildContext context, WidgetRef ref, List<Account> accounts) {
    final transfers = ref.watch(transfersProvider);
    if (transfers.isEmpty) return const SizedBox.shrink();

    final recent = transfers.reversed.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('RECENT TRANSFERS',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceMuted,
                letterSpacing: 0.8)),
        const SizedBox(height: 10),
        ...recent.map((t) {
          final from =
              accounts.where((a) => a.id == t.fromAccountId).firstOrNull;
          final to = accounts.where((a) => a.id == t.toAccountId).firstOrNull;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, size: 16, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${from?.name ?? "?"} → ${to?.name ?? "?"}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  AppUtils.formatAmount(t.amount, compact: true),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showAccountSheet(
      BuildContext context, WidgetRef ref, Account? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountFormSheet(existing: existing),
    );
  }

  Future<void> _showAdjustSheet(
      BuildContext context, WidgetRef ref, Account account) async {
    final ctrl =
        TextEditingController(text: account.balance.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adjust ${account.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set current balance:',
                style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$'))
              ],
              autofocus: true,
              decoration: const InputDecoration(prefixText: '₹ '),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              Navigator.pop(ctx, v);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (result != null) {
      final updated = account.copyWith(balance: result);
      await ref.read(accountsProvider.notifier).updateAccount(updated);
    }
  }

  Future<void> _deleteAccount(
      BuildContext context, WidgetRef ref, Account account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Delete "${account.name}"?'),
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
      await ref.read(accountsProvider.notifier).deleteAccount(account.id);
    }
  }

  Future<void> _showTransferSheet(
      BuildContext context, WidgetRef ref, List<Account> accounts) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransferSheet(accounts: accounts),
    );
  }
}

// ── Net Worth Card ────────────────────────────────────────────────
class _NetWorthCard extends StatelessWidget {
  final List<Account> accounts;
  const _NetWorthCard({required this.accounts});

  @override
  Widget build(BuildContext context) {
    final total = accounts.fold(0.0, (sum, a) => sum + a.balance);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.18),
            AppTheme.primaryDark.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance',
              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted)),
          const SizedBox(height: 6),
          Text(
            AppUtils.formatAmount(total),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: total >= 0 ? AppTheme.onSurface : AppTheme.expense,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: accounts.map((a) {
              final color = AppUtils.colorFromValue(a.colorValue);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppUtils.iconFromHex(a.icon), size: 12, color: color),
                    const SizedBox(width: 5),
                    Text(a.name,
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 5),
                    Text(
                      AppUtils.formatAmount(a.balance, compact: true),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.onSurfaceMuted),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Account Card ──────────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onAdjust;

  const _AccountCard({
    required this.account,
    required this.onEdit,
    this.onDelete,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final a = account;
    final color = AppUtils.colorFromValue(a.colorValue);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(AppUtils.iconFromHex(a.icon), size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(a.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (a.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Default',
                            style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  AppUtils.formatAmount(a.balance),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: a.balance >= 0 ? AppTheme.income : AppTheme.expense,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_outlined, size: 16),
                onPressed: onAdjust,
                color: AppTheme.onSurfaceMuted,
                tooltip: 'Adjust balance',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                onPressed: onEdit,
                color: AppTheme.onSurfaceMuted,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: onDelete,
                  color: AppTheme.expense.withOpacity(0.7),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Account Form Sheet ────────────────────────────────────────────
class _AccountFormSheet extends ConsumerStatefulWidget {
  final Account? existing;
  const _AccountFormSheet({this.existing});

  @override
  ConsumerState<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<_AccountFormSheet> {
  final _nameCtrl = TextEditingController();
  final _balCtrl = TextEditingController();
  int _selectedColor = 0xFF1E88E5;
  String _selectedIcon = 'e227';
  bool _saving = false;

  static const _presets = [
    ('Cash', 0xFF43A047, 'e0d6', false),
    ('Bank', 0xFF1E88E5, 'e2d6', false),
    ('UPI Wallet', 0xFF8E24AA, 'e0cd', false),
    ('Credit Card', 0xFFE53935, 'e870', false),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _balCtrl.text = e.balance.toStringAsFixed(0);
      _selectedColor = e.colorValue;
      _selectedIcon = e.icon;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

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
                Text(isEdit ? 'Edit Account' : 'New Account',
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            if (!isEdit) ...[
              const SizedBox(height: 12),
              // Quick presets
              const Text('QUICK ADD',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceMuted,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((p) {
                  return GestureDetector(
                    onTap: () => setState(() {
                      _nameCtrl.text = p.$1;
                      _selectedColor = p.$2;
                      _selectedIcon = p.$3;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(p.$2).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Color(p.$2).withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppUtils.iconFromHex(p.$3),
                              size: 14, color: Color(p.$2)),
                          const SizedBox(width: 6),
                          Text(p.$1,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(p.$2),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            // Preview
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(_selectedColor).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(AppUtils.iconFromHex(_selectedIcon),
                    size: 28, color: Color(_selectedColor)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g. SBI Savings, Cash',
                prefixIcon: Icon(Icons.label_outline, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$'))
              ],
              decoration: InputDecoration(
                labelText: isEdit ? 'Current Balance' : 'Opening Balance',
                prefixText: '₹ ',
                hintText: '0 (use - for credit owed)',
              ),
            ),
            const SizedBox(height: 16),
            // Color
            const Text('COLOR',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceMuted,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: AppUtils.categoryColors.map((c) {
                final sel = _selectedColor == c.$2;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c.$2),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(c.$2),
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: AppTheme.onSurface, width: 2.5)
                          : null,
                    ),
                    child: sel
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Icon
            const Text('ICON',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceMuted,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppUtils.categoryIcons.take(16).map((ic) {
                final sel = _selectedIcon == ic.$2;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = ic.$2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: sel
                          ? Color(_selectedColor).withOpacity(0.15)
                          : AppTheme.surfaceCard2,
                      borderRadius: BorderRadius.circular(10),
                      border: sel
                          ? Border.all(color: Color(_selectedColor), width: 1.5)
                          : null,
                    ),
                    child: Icon(AppUtils.iconFromHex(ic.$2),
                        size: 18,
                        color: sel
                            ? Color(_selectedColor)
                            : AppTheme.onSurfaceMuted),
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
                  : Text(isEdit ? 'Update Account' : 'Add Account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final balance = double.tryParse(_balCtrl.text.replaceAll(',', '')) ?? 0;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter an account name')));
      return;
    }
    setState(() => _saving = true);

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        name: name,
        balance: balance,
        colorValue: _selectedColor,
        icon: _selectedIcon,
      );
      await ref.read(accountsProvider.notifier).updateAccount(updated);
    } else {
      final account = Account(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        balance: balance,
        colorValue: _selectedColor,
        icon: _selectedIcon,
      );
      await ref.read(accountsProvider.notifier).addAccount(account);
    }

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }
}

// ── Transfer Sheet ────────────────────────────────────────────────
class _TransferSheet extends ConsumerStatefulWidget {
  final List<Account> accounts;
  const _TransferSheet({required this.accounts});

  @override
  ConsumerState<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<_TransferSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late String _fromId;
  late String _toId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fromId = widget.accounts.first.id;
    _toId = widget.accounts.length > 1
        ? widget.accounts[1].id
        : widget.accounts.first.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + kb),
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
          Text('Transfer Between Accounts',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          // From / To row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FROM',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceMuted,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _fromId,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceCard2,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero),
                        items: widget.accounts
                            .map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _fromId = v!),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: AppTheme.primary),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TO',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceMuted,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _toId,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceCard2,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero),
                        items: widget.accounts
                            .map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _toId = v!),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.notes_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _doTransfer,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  Future<void> _doTransfer() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('From and To accounts must differ')));
      return;
    }
    setState(() => _saving = true);

    final accounts = ref.read(accountsProvider);
    final updated = accounts.map((a) {
      if (a.id == _fromId) return a.copyWith(balance: a.balance - amount);
      if (a.id == _toId) return a.copyWith(balance: a.balance + amount);
      return a;
    }).toList();
    await ref.read(accountsProvider.notifier).save(updated);

    final transfer = AccountTransfer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromAccountId: _fromId,
      toAccountId: _toId,
      amount: amount,
      date: DateTime.now(),
      note: _noteCtrl.text.trim(),
    );
    await ref.read(transfersProvider.notifier).addTransfer(transfer);

    setState(() => _saving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Transfer complete')));
    }
  }
}
