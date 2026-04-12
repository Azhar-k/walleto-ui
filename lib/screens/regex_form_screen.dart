import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../providers/core_providers.dart';
import '../providers/additional_providers.dart';

const _llmPromptTemplate = '''Act as an expert in Regular Expressions (Java flavor). I will provide you with a financial transaction SMS message. Your task is to write a Java-compatible regex that matches the structure of this SMS. 

You must use **capturing groups** `(...)` to extract specific pieces of information. Our application iterates through all the capturing groups to extract transaction details. Therefore, you must use capturing groups ONLY for the specific data points below. Use non-capturing groups `(?:...)` for any other grouping logic.

Please capture the following data points (if they exist in the SMS):
1. **Amount**: The exact transaction amount (e.g., "150.00", "1,234.50", "500"). Do NOT capture the currency symbol (e.g., "\$", "INR", "Rs").
2. **Account Information**: The account mask or suffix (e.g., "XX123", "Acct 4567", "*9876", or just "1234").
3. **Merchant / Counterparty**: The pure name of the merchant, person, or entity. (e.g., "Starbucks", "John Doe"). Do not include words like "at", "to", or "from" inside the capture group.
4. **Date/Time** (Optional): The date or time of the transaction.

Important Rules for the Regex:
- ONLY create capturing groups `(...)` for the items listed above. If you need to group other parts of the text (like optional words), you MUST use non-capturing groups `(?:...)`.
- Make the regex flexible enough to handle variations in whitespace, changing reference numbers, and varying string lengths. Do not hardcode specific transaction IDs or unique reference numbers.
- Provide the final regex pattern, ready to be saved into a database.

**SMS Message:**
"{{sms}}"''';

class RegexFormScreen extends ConsumerStatefulWidget {
  final RegexPattern? existingRegex;

  const RegexFormScreen({super.key, this.existingRegex});

  @override
  ConsumerState<RegexFormScreen> createState() => _RegexFormScreenState();
}

class _RegexFormScreenState extends ConsumerState<RegexFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _smsController = TextEditingController();
  late String _name;
  late String _pattern;
  late TransactionType _transactionType;
  late bool _isActive;
  bool _isLoading = false;
  bool _promptExpanded = false;

  @override
  void initState() {
    super.initState();
    _name = widget.existingRegex?.name ?? '';
    _pattern = widget.existingRegex?.pattern ?? '';
    _transactionType =
        widget.existingRegex?.transactionType ?? TransactionType.debit;
    _isActive = widget.existingRegex?.isActive ?? true;
  }

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }

  void _copyPrompt() {
    final sms = _smsController.text.trim();
    final prompt = _llmPromptTemplate.replaceAll('{{sms}}', sms.isEmpty ? 'Paste your SMS message here' : sms);
    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Prompt copied to clipboard'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Regex Pattern'),
        content: const Text(
            'Are you sure you want to delete this pattern? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(regexServiceProvider)
            .deleteRegexPattern(widget.existingRegex!.id!);
        ref.invalidate(regexesProvider);
        messenger.showSnackBar(
          const SnackBar(content: Text('Regex Pattern deleted')),
        );
        router.pop();
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final regexService = ref.read(regexServiceProvider);
      final isUpdating = widget.existingRegex != null;

      final payload = RegexPattern(
        id: widget.existingRegex?.id,
        name: _name,
        pattern: _pattern,
        transactionType: _transactionType,
        isActive: _isActive,
        version: widget.existingRegex?.version,
      );

      if (isUpdating) {
        await regexService.updateRegexPattern(
            widget.existingRegex!.id!, payload);
      } else {
        await regexService.createRegexPattern(payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpdating
                ? 'Regex Pattern updated successfully'
                : 'Regex Pattern created successfully',
          ),
        ),
      );

      ref.invalidate(regexesProvider);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save Regex Pattern: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRegex != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Regex Pattern' : 'New Regex Pattern'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Pattern',
              onPressed: _isLoading ? null : () => _delete(context),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Generate with AI card ──────────────────────────────
                    Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.outline.withAlpha(77),
                        ),
                      ),
                      child: ExpansionTile(
                        leading: Icon(
                          Icons.auto_awesome,
                          color: colorScheme.primary,
                        ),
                        title: const Text(
                          'Generate with AI',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Copy a prompt to generate regex using an LLM',
                          style: TextStyle(fontSize: 12),
                        ),
                        initiallyExpanded: _promptExpanded,
                        onExpansionChanged: (v) =>
                            setState(() => _promptExpanded = v),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          TextField(
                            controller: _smsController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'SMS Message (optional)',
                              hintText:
                                  'Paste an example SMS to include in the prompt…',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: _copyPrompt,
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('Copy Prompt'),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Paste the prompt into ChatGPT, Gemini, Claude, or any LLM. '
                            'Then paste the generated regex into the Pattern field below.',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Form fields ────────────────────────────────────────
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a name'
                          : null,
                      onSaved: (value) => _name = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _pattern,
                      decoration: const InputDecoration(
                        labelText: 'Pattern',
                        hintText:
                            r'e.g. ^(?<amount>\d+(?:\.\d{1,2})?)\s+debited.*$',
                      ),
                      maxLines: 3,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a regex pattern'
                          : null,
                      onSaved: (value) => _pattern = value!,
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Transaction Type',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: DropdownButton<TransactionType>(
                        value: _transactionType,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: TransactionType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _transactionType = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle:
                          const Text('Enable this pattern for SMS parsing'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      child:
                          Text(isEditing ? 'Update Pattern' : 'Create Pattern'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
