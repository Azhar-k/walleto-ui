import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/core_providers.dart';
import '../providers/additional_providers.dart';
import '../models/models.dart';
import '../core/theme/app_theme.dart';

// ─── Main Screen ─────────────────────────────────────────────────────────────

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  Map<String, dynamic> _filters = {};
  Account? _selectedAccount; // null = All accounts

  @override
  void initState() {
    super.initState();
    _applyDefaultFilters();
  }

  void _applyDefaultFilters() {
    _filters = {
      'fromDate': DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().subtract(const Duration(days: 30))),
      'toDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      if (_selectedAccount?.id != null) 'accountId': _selectedAccount!.id,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionSearchProvider.notifier).search(_filters);
    });
  }

  void _onAccountChanged(Account? account) {
    setState(() => _selectedAccount = account);
    final updated = Map<String, dynamic>.from(_filters);
    if (account == null) {
      updated.remove('accountId');
    } else {
      updated['accountId'] = account.id;
    }
    _filters = updated;
    ref.read(transactionSearchProvider.notifier).search(_filters);
  }

  void _applyFilters(Map<String, dynamic> newFilters) {
    setState(() => _filters = newFilters);
    ref.read(transactionSearchProvider.notifier).search(newFilters);
  }

  void _openFilters() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final recurringPayments =
        ref.read(recurringPaymentsProvider).valueOrNull ?? [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        currentFilters: _filters,
        accounts: accounts,
        categories: categories,
        recurringPayments: recurringPayments,
        onApply: (f) {
          Navigator.pop(ctx);
          _applyFilters(f);
        },
        onClear: () {
          Navigator.pop(ctx);
          _applyDefaultFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionSearchProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: _openFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Account filter bar ───────────────────────────────────────────
          accountsAsync.when(
            data: (accounts) => _AccountFilterBar(
              accounts: accounts,
              selected: _selectedAccount,
              onChanged: _onAccountChanged,
            ),
            loading: () => const SizedBox.shrink(),
            error: (err, st) => const SizedBox.shrink(),
          ),
          const Divider(height: 1),
          // ── Transaction list ─────────────────────────────────────────────
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 56, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No transactions found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Try changing the filters or date range.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref
                      .read(transactionSearchProvider.notifier)
                      .search(_filters),
                  child: ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return _TransactionTile(
                        tx: tx,
                        onTap: () =>
                            context.push('/transactions/edit', extra: tx),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: $e'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(transactionSearchProvider.notifier)
                          .search(_filters),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Account filter bar ───────────────────────────────────────────────────────

class _AccountFilterBar extends StatelessWidget {
  final List<Account> accounts;
  final Account? selected;
  final ValueChanged<Account?> onChanged;

  const _AccountFilterBar({
    required this.accounts,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip(context, null, 'All'),
          ...accounts.map((a) => _chip(context, a, a.name)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, Account? account, String label) {
    final isSelected = account == null
        ? selected == null
        : selected?.id == account.id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onChanged(account),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// ─── Filter Bottom Sheet ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final List<Account> accounts;
  final List<Category> categories;
  final List<RecurringPayment> recurringPayments;
  final ValueChanged<Map<String, dynamic>> onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.currentFilters,
    required this.accounts,
    required this.categories,
    required this.recurringPayments,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DateTime _fromDate;
  late DateTime _toDate;
  String? _transactionType; // null = All
  String? _searchText;
  Category? _category;
  RecurringPayment? _recurringPayment;
  double? _amountMin;
  double? _amountMax;
  bool? _excludeFromSummary;

  late TextEditingController _searchCtrl;
  late TextEditingController _minAmtCtrl;
  late TextEditingController _maxAmtCtrl;

  @override
  void initState() {
    super.initState();
    final f = widget.currentFilters;
    _fromDate = f['fromDate'] != null
        ? DateTime.tryParse(f['fromDate']) ??
              DateTime.now().subtract(const Duration(days: 30))
        : DateTime.now().subtract(const Duration(days: 30));
    _toDate = f['toDate'] != null
        ? DateTime.tryParse(f['toDate']) ?? DateTime.now()
        : DateTime.now();
    _transactionType = f['transactionType'] as String?;
    _searchText = f['search'] as String?;
    _amountMin = f['minAmount'] as double?;
    _amountMax = f['maxAmount'] as double?;
    _excludeFromSummary = f['excludeFromSummary'] as bool?;

    final catId = f['categoryId'] as int?;
    _category = catId != null
        ? widget.categories.where((c) => c.id == catId).firstOrNull
        : null;
    final rpId = f['recurringPaymentId'] as int?;
    _recurringPayment = rpId != null
        ? widget.recurringPayments.where((r) => r.id == rpId).firstOrNull
        : null;

    _searchCtrl = TextEditingController(text: _searchText ?? '');
    _minAmtCtrl = TextEditingController(text: _amountMin?.toString() ?? '');
    _maxAmtCtrl = TextEditingController(text: _amountMax?.toString() ?? '');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _minAmtCtrl.dispose();
    _maxAmtCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildFilters() {
    return {
      'fromDate': DateFormat('yyyy-MM-dd').format(_fromDate),
      'toDate': DateFormat('yyyy-MM-dd').format(_toDate),
      if (_transactionType != null) 'transactionType': _transactionType,
      if (_searchCtrl.text.isNotEmpty) 'search': _searchCtrl.text.trim(),
      if (_category != null) 'categoryId': _category!.id,
      if (_recurringPayment != null)
        'recurringPaymentId': _recurringPayment!.id,
      if (_minAmtCtrl.text.isNotEmpty)
        'minAmount': double.tryParse(_minAmtCtrl.text),
      if (_maxAmtCtrl.text.isNotEmpty)
        'maxAmount': double.tryParse(_maxAmtCtrl.text),
      if (_excludeFromSummary != null)
        'excludeFromSummary': _excludeFromSummary,
      // retain accountId if set from the account bar
      if (widget.currentFilters['accountId'] != null)
        'accountId': widget.currentFilters['accountId'],
    };
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onClear,
                  child: const Text('Clear All'),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // ── Date range ────────────────────────────────────────────
                const _SectionLabel('Date Range'),
                Row(
                  children: [
                    Expanded(
                      child: _DateTile(
                        label: 'From',
                        value: fmt.format(_fromDate),
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateTile(
                        label: 'To',
                        value: fmt.format(_toDate),
                        onTap: () => _pickDate(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Transaction type ──────────────────────────────────────
                const _SectionLabel('Transaction Type'),
                SegmentedButton<String?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(value: 'DEBIT', label: Text('Debit')),
                    ButtonSegment(value: 'CREDIT', label: Text('Credit')),
                  ],
                  selected: {_transactionType},
                  onSelectionChanged: (s) =>
                      setState(() => _transactionType = s.first),
                ),
                const SizedBox(height: 16),
                // ── Free text search ──────────────────────────────────────
                const _SectionLabel('Search'),
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search description or counterparty…',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                // ── Category ──────────────────────────────────────────────
                const _SectionLabel('Category'),
                DropdownButtonFormField<Category?>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All categories'),
                    ),
                    ...widget.categories.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 16),
                // ── Recurring Payment ─────────────────────────────────────
                const _SectionLabel('Recurring Payment'),
                DropdownButtonFormField<RecurringPayment?>(
                  initialValue: _recurringPayment,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Any / none'),
                    ),
                    ...widget.recurringPayments.map(
                      (r) => DropdownMenuItem(value: r, child: Text(r.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _recurringPayment = v),
                ),
                const SizedBox(height: 16),
                // ── Amount range ──────────────────────────────────────────
                const _SectionLabel('Amount Range'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAmtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min',
                          prefixIcon: Icon(Icons.currency_rupee, size: 16),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxAmtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max',
                          prefixIcon: Icon(Icons.currency_rupee, size: 16),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Exclude from summary ──────────────────────────────────
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Excluded from Summary only'),
                  value: _excludeFromSummary ?? false,
                  onChanged: (v) =>
                      setState(() => _excludeFromSummary = v ? true : null),
                ),
                const SizedBox(height: 80), // space for button
              ],
            ),
          ),
          // ── Apply button (pinned) ─────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_buildFilters()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    ),
  );
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}

// ─── Transaction list tile ────────────────────────────────────────────────────

class _TransactionTile extends StatefulWidget {
  final Transaction tx;
  final VoidCallback onTap;
  const _TransactionTile({required this.tx, required this.onTap});

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<_TransactionTile> {
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final isCredit = tx.transactionType == TransactionType.CREDIT;
    final color = isCredit ? AppTheme.creditColor : AppTheme.debitColor;
    final prefix = isCredit ? '+' : '−';
    final hasDesc = (tx.description ?? '').trim().isNotEmpty;
    final hasCounterparty = (tx.counterpartyName ?? '').trim().isNotEmpty;
    final hasLinkedRP = tx.recurringPaymentId != null;

    // Short preview: first 3 words
    final words = (tx.description ?? '').trim().split(RegExp(r'\s+'));
    final shortDesc = words.take(3).join(' ');
    final descIsTruncated = words.length > 3;

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: category chip | DEBIT/CREDIT badge | amount ───────────
            Row(
              children: [
                if ((tx.categoryName ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tx.categoryName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    isCredit ? 'CR' : 'DR',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$prefix ${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // ── Row 2: account • counterparty • date ─────────────────────────
            Row(
              children: [
                if ((tx.accountName ?? '').isNotEmpty) ...[
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    tx.accountName!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (hasCounterparty) ...[
                  const Text(
                    '  ·  ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Icon(
                    Icons.person_outline,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      tx.counterpartyName!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  DateFormat.MMMd().add_jm().format(tx.dateTime),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            // ── Row 3: linked recurring payment ──────────────────────────────
            if (hasLinkedRP) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.repeat, size: 12, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text(
                    'Recurring #${tx.recurringPaymentId}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ],
            // ── Row 4: collapsible description ───────────────────────────────
            if (hasDesc) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _descExpanded ? (tx.description ?? '') : shortDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  if (descIsTruncated)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _descExpanded = !_descExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          _descExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
