import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../auth/services/auth_service.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../widgets/transaction_card.dart';
import 'transaction_detail_page.dart';

/// Dedicated Transactions page with summary metrics, filter tabs,
/// transaction cards, and an empty state.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'All'; // 'All', 'Debit', 'Credit'

  @override
  void initState() {
    super.initState();
    TransactionService.instance.init();
    TransactionService.instance.addListener(_onServiceUpdate);
    final userId = AuthService.instance.currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      TransactionService.instance.fetchTransactionsFromBackend(userId);
    }
  }

  @override
  void dispose() {
    TransactionService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _openAddTransactionModal(String userId) {
    showModalBottomSheet<TransactionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditTransactionModal(userId: userId),
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = AuthService.instance.currentUser?.id ?? '';
    final allTransactions =
        TransactionService.instance.getTransactionsForUser(userId);

    final totalCount = allTransactions.length;
    final totalDebit = TransactionService.instance.getTotalDebit(userId);
    final totalCredit = TransactionService.instance.getTotalCredit(userId);

    final filteredTransactions = allTransactions.where((t) {
      if (_selectedFilter == 'Debit') return t.isDebit;
      if (_selectedFilter == 'Credit') return t.isCredit;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Activity & Money',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Add Transaction',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5A58EE), Color(0xFF835CF6)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            ),
            onPressed: () => _openAddTransactionModal(userId),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTransactionModal(userId),
        backgroundColor: AppColors.royalBlue,
        foregroundColor: Colors.white,
        tooltip: 'Add Transaction',
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Money',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
            vertical: AppDimensions.space16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Overview Summary Hero Banner
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF071A52),
                          Color(0xFF0B1F5E),
                          Color(0xFF1E1B4B),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF071A52).withAlpha(100),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'CASHFLOW SUMMARY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.electricCyan,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$totalCount Transactions',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(180),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _summaryBox(
                                label: 'Total Inflow',
                                value: _fmt(totalCredit),
                                color: AppColors.mint,
                                icon: Icons.arrow_downward_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryBox(
                                label: 'Total Outflow',
                                value: _fmt(totalDebit),
                                color: AppColors.pink,
                                icon: Icons.arrow_upward_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Filter Row
                  if (allTransactions.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          'FILTER BY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const Spacer(),
                        _filterChip('All', isDark),
                        const SizedBox(width: 6),
                        _filterChip('Debit', isDark),
                        const SizedBox(width: 6),
                        _filterChip('Credit', isDark),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space16),
                  ],

                  // Content: Empty State OR Transaction List
                  if (allTransactions.isEmpty)
                    _buildEmptyState(context, isDark, userId)
                  else if (filteredTransactions.isEmpty)
                    _buildNoFilterResults(isDark)
                  else ...[
                    ...filteredTransactions.map(
                      (t) => TransactionCard(
                        transaction: t,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TransactionDetailPage(transaction: t),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String filter, bool isDark) {
    final isSelected = _selectedFilter == filter;
    final label = filter == 'Debit'
        ? 'Outflow'
        : filter == 'Credit'
            ? 'Inflow'
            : 'All';

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.royalBlue
              : (isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.royalBlue
                : (isDark
                    ? AppColors.navyBorder.withAlpha(80)
                    : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, String userId) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space24,
        vertical: AppDimensions.space40,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? AppColors.navyBorder.withAlpha(100)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withAlpha(80),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          Text(
            'No Transactions Recorded',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Start by adding your income or expenses to track real-time money movements.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppDimensions.space24),
          ElevatedButton.icon(
            onPressed: () => _openAddTransactionModal(userId),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Your First Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResults(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.navyBorder.withAlpha(80)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Text(
          'No $_selectedFilter transactions found.',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Add / Edit Transaction Modal with Reference Aesthetic
// ─────────────────────────────────────────────────────────────
class AddEditTransactionModal extends StatefulWidget {
  final String userId;
  final TransactionModel? initialTransaction;

  const AddEditTransactionModal({
    super.key,
    required this.userId,
    this.initialTransaction,
  });

  @override
  State<AddEditTransactionModal> createState() =>
      _AddEditTransactionModalState();
}

class _AddEditTransactionModalState extends State<AddEditTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late TextEditingController _notesController;

  late TransactionType _type;
  late PaymentMethod _paymentMethod;
  late String _category;
  late DateTime _selectedDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final init = widget.initialTransaction;
    _amountController = TextEditingController(
      text: init != null
          ? (init.amount.truncateToDouble() == init.amount
              ? init.amount.toStringAsFixed(0)
              : init.amount.toStringAsFixed(2))
          : '',
    );
    _merchantController =
        TextEditingController(text: init?.merchantName ?? '');
    _notesController = TextEditingController(text: init?.notes ?? '');
    _type = init?.type ?? TransactionType.debit;
    _paymentMethod = init?.paymentMethod ?? PaymentMethod.upi;
    _category = init?.category ?? TransactionCategories.foodAndDining;
    _selectedDate = init?.dateTime ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final isEdit = widget.initialTransaction != null;
    final TransactionResult result;

    if (isEdit) {
      result = await TransactionService.instance.updateTransaction(
        userId: widget.userId,
        id: widget.initialTransaction!.id,
        amountRaw: _amountController.text,
        type: _type,
        merchantName: _merchantController.text,
        category: _category,
        paymentMethod: _paymentMethod,
        dateTime: _selectedDate,
        notes: _notesController.text,
      );
    } else {
      result = await TransactionService.instance.createTransaction(
        userId: widget.userId,
        amountRaw: _amountController.text,
        type: _type,
        merchantName: _merchantController.text,
        category: _category,
        paymentMethod: _paymentMethod,
        dateTime: _selectedDate,
        notes: _notesController.text,
      );
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      Navigator.of(context).pop(result.transaction);
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? 'An error occurred.';
      });
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.initialTransaction != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit ? 'Edit Transaction' : 'Record Transaction',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.error.withAlpha(80)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),
                    ],

                    // Segmented Type Selector: Outflow / Inflow
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _typeSegment(
                              title: 'Outflow (Expense)',
                              type: TransactionType.debit,
                              activeColor: AppColors.pink,
                              icon: Icons.arrow_upward_rounded,
                              isDark: isDark,
                            ),
                          ),
                          Expanded(
                            child: _typeSegment(
                              title: 'Inflow (Income)',
                              type: TransactionType.credit,
                              activeColor: AppColors.mint,
                              icon: Icons.arrow_downward_rounded,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    // Amount Input
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: const Icon(Icons.currency_rupee_rounded,
                            size: 22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (val) {
                        final parsed = double.tryParse(val?.trim() ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount greater than 0.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.space14),

                    // Merchant Field
                    TextFormField(
                      controller: _merchantController,
                      decoration: InputDecoration(
                        labelText: 'Merchant or Source',
                        prefixIcon: const Icon(Icons.storefront_outlined,
                            size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Merchant or source name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.space14),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: const Icon(Icons.category_outlined,
                            size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: TransactionCategories.all.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                    const SizedBox(height: AppDimensions.space14),

                    // Payment Method & Date in a Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<PaymentMethod>(
                            initialValue: _paymentMethod,
                            decoration: InputDecoration(
                              labelText: 'Method',
                              prefixIcon: const Icon(Icons.payment_outlined,
                                  size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            items: PaymentMethod.values.map((method) {
                              return DropdownMenuItem(
                                value: method,
                                child: Text(method.displayName),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _paymentMethod = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.navyBorder
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 18, color: AppColors.royalBlue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatDate(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space14),

                    // Notes Field
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space24),

                    // CTA Submit Button
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5A58EE),
                            Color(0xFF835CF6),
                            Color(0xFFA855F7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withAlpha(100),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                isEdit ? 'Save Changes' : 'Record Transaction',
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
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

  Widget _typeSegment({
    required String title,
    required TransactionType type,
    required Color activeColor,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
