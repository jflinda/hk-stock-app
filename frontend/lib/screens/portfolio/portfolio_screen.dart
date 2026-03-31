import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hk_stock_app/constants/index.dart';
import 'package:hk_stock_app/models/index.dart';
import 'package:hk_stock_app/providers/portfolio_providers.dart';
import 'package:hk_stock_app/providers/trades_providers.dart';
import 'package:hk_stock_app/services/api_service.dart';

/// Portfolio Screen - Display positions, performance, and trading journal
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        elevation: 0,
        backgroundColor: AppColors.darkBg,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Positions'),
            Tab(text: 'Journal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PositionsTab(),
          _JournalTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTradeModal(context),
        backgroundColor: AppColors.accentBlue,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTradeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _AddTradeModal(),
    );
  }
}

// ─────────────────────────────────────────────
// Positions Tab
// ─────────────────────────────────────────────
class _PositionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(portfolioSummaryProvider);
    final positionsAsync = ref.watch(sortedPositionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(portfolioSummaryProvider);
        ref.invalidate(positionsProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Summary Card
          SliverToBoxAdapter(
            child: summaryAsync.when(
              data: (summary) => _SummaryCard(summary: summary),
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => _ErrorCard(message: 'Failed to load summary'),
            ),
          ),
          // Positions List
          positionsAsync.when(
            data: (positions) => positions.isEmpty
                ? SliverToBoxAdapter(
                    child: _EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      message: 'No positions yet.\nTap + to add a trade.',
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _PositionCard(position: positions[index]),
                      childCount: positions.length,
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: _ErrorCard(message: 'Failed to load positions: $err'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PortfolioSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isProfit = summary.totalPL >= 0;
    final plColor = isProfit ? AppColors.upColor : AppColors.downColor;

    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Portfolio Value',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            'HK\$${summary.totalValue.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'P&L: HK\$${summary.totalPL.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: plColor,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '(${isProfit ? '+' : ''}${summary.totalPLPct.toStringAsFixed(2)}%)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: plColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${summary.totalHoldings} positions',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Text(
                '${summary.totalTrades} trades',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Text(
                'Win Rate: ${(summary.winRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.accentBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PositionCard extends StatelessWidget {
  final Position position;
  const _PositionCard({required this.position});

  @override
  Widget build(BuildContext context) {
    final isProfit = position.pl >= 0;
    final plColor = isProfit ? AppColors.upColor : AppColors.downColor;
    final weight = position.costValue > 0
        ? (position.currentValue /
            (position.currentValue + position.costValue) *
            0.8)
        : 0.5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    position.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${position.quantity} shares @ HK\$${position.avgCost.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'HK\$${position.currentValue.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${isProfit ? '+' : ''}HK\$${position.pl.toStringAsFixed(2)} '
                    '(${isProfit ? '+' : ''}${position.plPct.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: plColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current: HK\$${position.currentPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                'Cost: HK\$${position.costValue.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: weight.clamp(0.0, 1.0),
            backgroundColor: AppColors.borderColor,
            valueColor:
                AlwaysStoppedAnimation<Color>(plColor),
            minHeight: 3,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Journal Tab
// ─────────────────────────────────────────────
class _JournalTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(sortedTradesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tradesProvider);
      },
      child: tradesAsync.when(
        data: (trades) => trades.isEmpty
            ? _EmptyState(
                icon: Icons.receipt_long_outlined,
                message: 'No trades yet.\nTap + to record your first trade.',
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: trades.length,
                itemBuilder: (context, index) =>
                    _TradeCard(trade: trades[index], ref: ref),
              ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorCard(message: 'Failed to load trades: $err'),
      ),
    );
  }
}

class _TradeCard extends StatelessWidget {
  final Trade trade;
  final WidgetRef ref;
  const _TradeCard({required this.trade, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.type == 'BUY';
    final typeColor = isBuy ? AppColors.upColor : AppColors.downColor;
    final hasPL = !isBuy && trade.pl != 0;

    return Dismissible(
      key: Key(trade.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.withOpacity(0.8),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Trade'),
            content: Text(
                'Remove ${trade.type} ${trade.ticker} on ${trade.tradeDate.toString().substring(0, 10)}?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        try {
          await ref.read(deleteTradeProvider(trade.id).future);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Trade deleted'),
                backgroundColor: AppColors.cardBg),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to delete: $e'),
                backgroundColor: Colors.red),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                color: typeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trade.type} ${trade.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${trade.quantity} shares @ HK\$${trade.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    trade.tradeDate.toString().substring(0, 10),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'HK\$${(trade.quantity * trade.price).toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (hasPL)
                  Text(
                    '${trade.pl >= 0 ? '+' : ''}HK\$${trade.pl.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: trade.pl >= 0
                          ? AppColors.upColor
                          : AppColors.downColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    trade.type,
                    style: TextStyle(
                      fontSize: 11,
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add Trade Modal (Bottom Sheet)
// ─────────────────────────────────────────────
class _AddTradeModal extends ConsumerStatefulWidget {
  const _AddTradeModal();

  @override
  ConsumerState<_AddTradeModal> createState() => _AddTradeModalState();
}

class _AddTradeModalState extends ConsumerState<_AddTradeModal> {
  final _formKey = GlobalKey<FormState>();
  final _tickerController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _commissionController = TextEditingController(text: '30.0');
  final _notesController = TextEditingController();

  String _tradeType = 'BUY';
  DateTime _tradeDate = DateTime.now();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tickerController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _commissionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tradeDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accentBlue,
            onPrimary: Colors.white,
            surface: AppColors.cardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _tradeDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await apiService.addTrade(
        ticker: _tickerController.text.trim(),
        type: _tradeType,
        quantity: int.parse(_quantityController.text),
        price: double.parse(_priceController.text),
        commission: double.tryParse(_commissionController.text) ?? 0.0,
        tradeDate: _tradeDate,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      );

      // Invalidate providers to refresh data
      ref.invalidate(tradesProvider);
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(positionsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trade added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to add trade: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + padding),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Add Trade',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // BUY / SELL toggle
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'BUY',
                      isSelected: _tradeType == 'BUY',
                      color: AppColors.upColor,
                      onTap: () => setState(() => _tradeType = 'BUY'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeButton(
                      label: 'SELL',
                      isSelected: _tradeType == 'SELL',
                      color: AppColors.downColor,
                      onTap: () => setState(() => _tradeType = 'SELL'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stock code
              _FormField(
                controller: _tickerController,
                label: 'Stock Code',
                hint: 'e.g. 0700',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Price
                  Expanded(
                    child: _FormField(
                      controller: _priceController,
                      label: 'Price (HK\$)',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Quantity
                  Expanded(
                    child: _FormField(
                      controller: _quantityController,
                      label: 'Shares',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Commission
                  Expanded(
                    child: _FormField(
                      controller: _commissionController,
                      label: 'Commission (HK\$)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Date
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.darkBg,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: AppColors.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              _tradeDate
                                  .toString()
                                  .substring(0, 10),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  filled: true,
                  fillColor: AppColors.darkBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.borderColor),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style:
                        const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tradeType == 'BUY'
                        ? AppColors.upColor
                        : AppColors.downColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _tradeType == 'BUY' ? 'Add BUY Order' : 'Add SELL Order',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _TypeButton(
      {required this.label,
      required this.isSelected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.darkBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? color : AppColors.borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.darkBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
