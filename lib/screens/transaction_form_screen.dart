// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/core_providers.dart';
import '../providers/summary_providers.dart';
import '../providers/additional_providers.dart';
import '../models/models.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final Transaction? existingTransaction;
  const TransactionFormScreen({super.key, this.existingTransaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Account? _account;
  Category? _category;
  TransactionType _type = TransactionType.debit; // Default Expense mapping

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _counterpartyController;

  DateTime _transactionDate = DateTime.now();
  TimeOfDay _transactionTime = TimeOfDay.now();

  bool _excludeFromSummary = false;
  bool _isLoading = false;
  RecurringPayment? _linkedRecurringPayment;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.existingTransaction?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingTransaction?.description ?? '',
    );
    _counterpartyController = TextEditingController(
      text: widget.existingTransaction?.counterpartyName ?? '',
    );

    if (widget.existingTransaction != null) {
      _type = widget.existingTransaction!.transactionType;
      _transactionDate = widget.existingTransaction!.dateTime;
      _transactionTime = TimeOfDay.fromDateTime(
        widget.existingTransaction!.dateTime,
      );
      _excludeFromSummary =
          widget.existingTransaction!.excludeFromSummary ?? false;
    }
  }

  String _currencySymbol(String currency) {
    const symbols = {'INR': '₹', 'USD': '\$', 'EUR': '€', 'GBP': '£'};
    return symbols[currency] ?? currency;
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(transactionServiceProvider)
            .deleteTransaction(widget.existingTransaction!.id!);
        ref.invalidate(transactionSearchProvider);
        ref.invalidate(netBalanceProvider);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _submit(List<Account> accounts, List<Category> categories) async {
    if (_formKey.currentState!.validate() &&
        _account != null &&
        _category != null) {
      setState(() => _isLoading = true);
      final service = ref.read(transactionServiceProvider);

      final dateTime = DateTime(
        _transactionDate.year,
        _transactionDate.month,
        _transactionDate.day,
        _transactionTime.hour,
        _transactionTime.minute,
      );

      // Build a flat Transaction for the API
      final transaction = Transaction(
        id: widget.existingTransaction?.id,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dateTime: dateTime,
        transactionType: _type,
        categoryId: _category!.id,
        categoryName: _category!.name,
        accountId: _account!.id,
        accountName: _account!.name,
        counterpartyName: _counterpartyController.text.trim(),
        excludeFromSummary: _excludeFromSummary,
        recurringPaymentId: _linkedRecurringPayment?.id,
      );

      try {
        if (widget.existingTransaction == null) {
          await service.createTransaction(transaction);
        } else {
          await service.updateTransaction(transaction.id!, transaction);
        }

        // Refresh search list and balance
        ref.invalidate(transactionSearchProvider);
        ref.invalidate(netBalanceProvider);

        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save transaction: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_account == null || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account and Category are required.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final recurringPaymentsAsync = ref.watch(recurringPaymentsProvider);
    final isEditing = widget.existingTransaction != null;

    // Currency symbol from the currently selected account
    final currency = _account?.currency ?? 'INR';
    final currencySymbol = _currencySymbol(currency);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              color: Colors.red.shade300,
              onPressed: _isLoading ? null : _confirmDelete,
            ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          return categoriesAsync.when(
            data: (categories) {
              final recurringPayments =
                  recurringPaymentsAsync.valueOrNull ?? [];

              // Preselect for editing
              if (widget.existingTransaction != null &&
                  _account == null &&
                  _category == null) {
                _account = accounts.firstWhere(
                  (a) => a.id == widget.existingTransaction!.accountId,
                  orElse: () => accounts.first,
                );
                _category = categories.firstWhere(
                  (c) => c.id == widget.existingTransaction!.categoryId,
                  orElse: () => categories.first,
                );
                // Preselect linked recurring payment
                final rpId = widget.existingTransaction!.recurringPaymentId;
                if (rpId != null && _linkedRecurringPayment == null) {
                  _linkedRecurringPayment = recurringPayments
                      .where((r) => r.id == rpId)
                      .firstOrNull;
                }
              } else if (_account == null && accounts.isNotEmpty) {
                _account = accounts.firstWhere(
                  (a) => a.isDefault == true,
                  orElse: () => accounts.first,
                );
              }

              final filteredCategories = categories
                  .where(
                    (c) =>
                        c.type ==
                        (_type == TransactionType.credit
                            ? CategoryType.income
                            : CategoryType.expense),
                  )
                  .toList();

              // if type changed and category invalid, clear it
              if (_category != null &&
                  !filteredCategories.any((c) => c.id == _category!.id)) {
                _category = null;
              }

              if (_category == null && filteredCategories.isNotEmpty) {
                // Pre-select the first available category as a default
                _category = filteredCategories.first;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<TransactionType>(
                        segments: const [
                          ButtonSegment(
                            value: TransactionType.debit,
                            label: Text('Debit/Expense'),
                          ),
                          ButtonSegment(
                            value: TransactionType.credit,
                            label: Text('Credit/Income'),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged:
                            (Set<TransactionType> newSelection) {
                              setState(() {
                                _type = newSelection.first;
                              });
                            },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount *',
                          prefixIcon: const Icon(Icons.attach_money),
                          prefixText: '$currencySymbol ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) {
                            return 'Must be a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Date'),
                              subtitle: Text(
                                DateFormat.yMMMd().format(_transactionDate),
                              ),
                              leading: const Icon(Icons.calendar_today),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _transactionDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => _transactionDate = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ListTile(
                              title: const Text('Time'),
                              subtitle: Text(_transactionTime.format(context)),
                              leading: const Icon(Icons.access_time),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _transactionTime,
                                );
                                if (picked != null) {
                                  setState(() => _transactionTime = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Account>(
                        initialValue: _account,
                        decoration: const InputDecoration(
                          labelText: 'Account *',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        items: accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _account = val),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Category>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: filteredCategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _category = val),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _counterpartyController,
                        decoration: const InputDecoration(
                          labelText: 'Counterparty (optional)',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── Recurring Payment linkage ─────────────────────────
                      DropdownButtonFormField<RecurringPayment?>(
                        initialValue: _linkedRecurringPayment,
                        decoration: const InputDecoration(
                          labelText: 'Linked Recurring Payment (optional)',
                          prefixIcon: Icon(Icons.repeat),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None'),
                          ),
                          ...recurringPayments.map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                '${r.name}  •  ₹${r.amount.toStringAsFixed(0)}',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _linkedRecurringPayment = val),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Exclude from Summary'),
                        value: _excludeFromSummary,
                        onChanged: (val) =>
                            setState(() => _excludeFromSummary = val),
                      ),
                      if (isEditing) ...[
                        const Divider(height: 32),
                        _AttachmentsSection(
                          transactionId: widget.existingTransaction!.id!,
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _submit(accounts, categories),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'SAVE TRANSACTION',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) =>
                Center(child: Text('Error loading categories: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading accounts: $e')),
      ),
    );
  }
}

class _AttachmentsSection extends ConsumerStatefulWidget {
  final int transactionId;
  const _AttachmentsSection({required this.transactionId});

  @override
  ConsumerState<_AttachmentsSection> createState() =>
      _AttachmentsSectionState();
}

class _AttachmentsSectionState extends ConsumerState<_AttachmentsSection> {
  List<TransactionAttachment>? _attachments;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    debugPrint(
      '[Attachments] Loading attachments for txn ${widget.transactionId}',
    );
    setState(() => _isLoading = true);
    try {
      final attachments = await ref
          .read(transactionServiceProvider)
          .getAttachments(widget.transactionId);
      debugPrint('[Attachments] Loaded ${attachments.length} attachments');
      if (mounted) {
        setState(() {
          _attachments = attachments;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('[Attachments] ❌ Failed to load attachments: $e\n$st');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadAttachment() async {
    debugPrint('[Attachments] Opening file picker...');
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null) {
      debugPrint('[Attachments] File picker cancelled');
      return;
    }
    final picked = result.files.single;
    final bytes = picked.bytes;
    final fileName = picked.name;
    debugPrint(
      '[Attachments] Picked file: $fileName, size: ${bytes?.length} bytes',
    );
    if (bytes == null) {
      debugPrint('[Attachments] ❌ No bytes available for file: $fileName');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file bytes.')),
        );
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      debugPrint(
        '[Attachments] Uploading $fileName to txn ${widget.transactionId}...',
      );
      await ref
          .read(transactionServiceProvider)
          .uploadAttachment(widget.transactionId, multipartFile);
      debugPrint('[Attachments] ✅ Upload successful');
      await _loadAttachments();
    } catch (e, st) {
      debugPrint('[Attachments] ❌ Upload failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAttachment(int attachmentId) async {
    debugPrint(
      '[Attachments] Deleting attachment $attachmentId from txn ${widget.transactionId}',
    );
    setState(() => _isLoading = true);
    try {
      await ref
          .read(transactionServiceProvider)
          .deleteAttachment(widget.transactionId, attachmentId);
      debugPrint('[Attachments] ✅ Deleted attachment $attachmentId');
      await _loadAttachments();
    } catch (e, st) {
      debugPrint('[Attachments] ❌ Delete failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isImage(String? fileName) {
    if (fileName == null) return false;
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  bool _isPdf(String? fileName) {
    if (fileName == null) return false;
    return fileName.toLowerCase().endsWith('.pdf');
  }

  Future<void> _handleAttachmentClick(
    TransactionAttachment attachment, {
    Uint8List? prefetchedBytes,
  }) async {
    debugPrint(
      '[Attachments] Handling click for attachment ${attachment.id} (${attachment.fileName})',
    );
    if (prefetchedBytes == null) {
      setState(() => _isLoading = true);
    }
    try {
      List<int> bytes;
      if (prefetchedBytes != null) {
        bytes = prefetchedBytes;
      } else {
        bytes = await ref
            .read(transactionServiceProvider)
            .downloadAttachment(widget.transactionId, attachment.id!);
      }
      debugPrint(
        '[Attachments] Downloaded ${bytes.length} bytes for ${attachment.fileName}',
      );

      if (_isImage(attachment.fileName)) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: Text(attachment.fileName ?? 'Preview'),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.download),
                        tooltip: 'Download',
                        onPressed: () {
                          Navigator.pop(ctx);
                          _triggerBrowserDownload(
                            bytes,
                            attachment.fileName ?? 'attachment',
                          );
                        },
                      ),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.memory(
                          Uint8List.fromList(bytes),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else if (_isPdf(attachment.fileName)) {
        // On web: embed the PDF bytes in an iframe inside a dialog (blob URL
        // works same-origin when embedded; fails in new tabs due to security).
        // On mobile: open via url_launcher.
        if (kIsWeb) {
          final data = Uint8List.fromList(bytes);
          final blob = html.Blob([data], 'application/pdf');
          final blobUrl = html.Url.createObjectUrlFromBlob(blob);

          // Register a unique platform view for this iframe
          final viewId =
              'pdf-view-${attachment.id}-${DateTime.now().millisecondsSinceEpoch}';
          ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) {
            return html.IFrameElement()
              ..src = blobUrl
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%';
          });

          if (mounted) {
            await showDialog(
              context: context,
              builder: (ctx) => Dialog(
                insetPadding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(ctx).size.height * 0.85,
                  child: Column(
                    children: [
                      AppBar(
                        title: Text(attachment.fileName ?? 'PDF Preview'),
                        automaticallyImplyLeading: false,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.download),
                            tooltip: 'Download',
                            onPressed: () {
                              _triggerBrowserDownload(
                                bytes,
                                attachment.fileName ?? 'attachment',
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      Expanded(child: HtmlElementView(viewType: viewId)),
                    ],
                  ),
                ),
              ),
            );
            html.Url.revokeObjectUrl(blobUrl);
          }
        } else {
          final urlStr = attachment.downloadUrl;
          if (urlStr != null) {
            final uri = Uri.parse(urlStr);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        }
      } else {
        _triggerBrowserDownload(bytes, attachment.fileName ?? 'attachment');
      }
    } catch (e, st) {
      debugPrint('[Attachments] ❌ Failed to fetch attachment: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _triggerBrowserDownload(List<int> bytes, String fileName) {
    debugPrint(
      '[Attachments] Web platform: triggering browser download for $fileName',
    );
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    if (_attachments == null && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final attachments = _attachments ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attachments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo),
              onPressed: _isLoading ? null : _uploadAttachment,
              tooltip: 'Add Attachment',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (attachments.isEmpty)
          const Text(
            'No attachments linked yet.',
            style: TextStyle(color: Colors.grey),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: attachments.map((a) {
              return _AttachmentItem(
                attachment: a,
                transactionId: widget.transactionId,
                isLoading: _isLoading,
                isImage: _isImage(a.fileName),
                isPdf: _isPdf(a.fileName),
                onDelete: () => _deleteAttachment(a.id!),
                onPreview: (bytes) =>
                    _handleAttachmentClick(a, prefetchedBytes: bytes),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _AttachmentItem extends ConsumerStatefulWidget {
  final TransactionAttachment attachment;
  final int transactionId;
  final bool isLoading;
  final VoidCallback onDelete;
  final void Function(Uint8List? bytes) onPreview;
  final bool isImage;
  final bool isPdf;

  const _AttachmentItem({
    required this.attachment,
    required this.transactionId,
    required this.isLoading,
    required this.onDelete,
    required this.onPreview,
    required this.isImage,
    required this.isPdf,
  });

  @override
  ConsumerState<_AttachmentItem> createState() => _AttachmentItemState();
}

class _AttachmentItemState extends ConsumerState<_AttachmentItem> {
  Uint8List? _imageBytes;
  bool _loadingBytes = false;

  @override
  void initState() {
    super.initState();
    // Only prefetch bytes for image thumbnails; PDFs just show an icon
    if (widget.isImage) {
      _fetchBytes();
    }
  }

  Future<void> _fetchBytes() async {
    setState(() => _loadingBytes = true);
    try {
      final bytes = await ref
          .read(transactionServiceProvider)
          .downloadAttachment(widget.transactionId, widget.attachment.id!);

      if (mounted) {
        setState(() {
          _imageBytes = Uint8List.fromList(bytes);
          _loadingBytes = false;
        });
      }
    } catch (e) {
      debugPrint('[Attachments] Failed to prefetch thumbnail: $e');
      if (mounted) setState(() => _loadingBytes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isImage || widget.isPdf) {
      return SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: InkWell(
                onTap: widget.isLoading
                    ? null
                    : () => widget.onPreview(_imageBytes),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : _loadingBytes
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Icon(
                            widget.isPdf ? Icons.picture_as_pdf : Icons.image,
                            color: Colors.grey,
                          ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: widget.isLoading ? null : widget.onDelete,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Chip(
      label: InkWell(
        onTap: widget.isLoading ? null : () => widget.onPreview(null),
        child: Text(
          widget.attachment.fileName ?? 'Unknown File',
          style: const TextStyle(
            decoration: TextDecoration.underline,
            color: Colors.blue,
          ),
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: widget.isLoading ? null : widget.onDelete,
    );
  }
}
