import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hk_stock_app/constants/index.dart';
import 'package:hk_stock_app/models/index.dart';
import 'package:hk_stock_app/providers/portfolio_providers.dart';
import 'package:hk_stock_app/providers/trades_providers.dart';
import 'package:hk_stock_app/services/api_service.dart';

/// Portfolio Screen - Display positions, performance, and trading journal
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: 'Performance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PositionsTab(),
          _JournalTab(),
          _PerformanceTab(),
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
        color: Colors.red.withValues(alpha: 0.8),
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
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Trade deleted'),
                  backgroundColor: AppColors.cardBg),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to delete: $e'),
                  backgroundColor: Colors.red),
            );
          }
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
                color: typeColor.withValues(alpha: 0.12),
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
                    color: Colors.red.withValues(alpha: 0.1),
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
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.darkBg,
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
            Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
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
        color: Colors.red.withValues(alpha: 0.1),
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

// ─────────────────────────────────────────────
// Performance Review Tab  (7 Submodules)
// ─────────────────────────────────────────────
class _PerformanceTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfAsync = ref.watch(performanceProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(performanceProvider),
      child: perfAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorCard(message: 'Failed to load performance: $err'),
        data: (data) {
          final overview = data['overview'] as Map<String, dynamic>? ?? {};
          final monthlyReturns = (data['monthlyReturns'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final cumulative = (data['cumulative'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final drawdown = data['drawdown'] as Map<String, dynamic>? ?? {};
          final sectorPL = (data['sectorPL'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final holdingPeriods = data['holdingPeriods'] as Map<String, dynamic>? ?? {};
          final benchmark = data['benchmark'] as Map<String, dynamic>? ?? {};

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // ── Module 1: Overview KPIs ──────────────────────────────
              _SectionTitle('Performance Overview'),
              _OverviewGrid(overview: overview),
              const SizedBox(height: 16),

              // ── Module 2: Monthly Returns Bar Chart ──────────────────
              _SectionTitle('Monthly Returns'),
              _MonthlyReturnsChart(data: monthlyReturns),
              const SizedBox(height: 16),

              // ── Module 3: Cumulative P&L Line Chart ──────────────────
              _SectionTitle('Cumulative P&L'),
              _CumulativePLChart(data: cumulative),
              const SizedBox(height: 16),

              // ── Module 4: Drawdown ───────────────────────────────────
              _SectionTitle('Drawdown Analysis'),
              _DrawdownCard(drawdown: drawdown),
              const SizedBox(height: 16),

              // ── Module 5: P&L by Ticker ──────────────────────────────
              _SectionTitle('P&L by Stock'),
              _SectorPLList(items: sectorPL),
              const SizedBox(height: 16),

              // ── Module 6: Holding Periods ────────────────────────────
              _SectionTitle('Holding Periods'),
              _HoldingPeriodCard(data: holdingPeriods),
              const SizedBox(height: 16),

              // ── Module 7: Benchmark vs HSI ───────────────────────────
              _SectionTitle('vs HSI Benchmark'),
              _BenchmarkCard(benchmark: benchmark),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

/// Styled section title
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.accentBlue,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Module 1 — Overview KPI grid
class _OverviewGrid extends StatelessWidget {
  final Map<String, dynamic> overview;
  const _OverviewGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    final pl = (overview['totalRealizedPL'] as num?)?.toDouble() ?? 0;
    final retPct = (overview['returnPct'] as num?)?.toDouble() ?? 0;
    final winRate = (overview['winRate'] as num?)?.toDouble() ?? 0;
    final profitFactor = (overview['profitFactor'] as num?)?.toDouble() ?? 0;
    final avgWin = (overview['avgWin'] as num?)?.toDouble() ?? 0;
    final avgLoss = (overview['avgLoss'] as num?)?.toDouble() ?? 0;
    final completed = overview['completedTrades'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          // Big P&L display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${pl >= 0 ? "+" : ""}HK\$${_fmt(pl.abs())}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: pl >= 0 ? AppColors.upColor : AppColors.downColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${retPct >= 0 ? "+" : ""}${retPct.toStringAsFixed(2)}%)',
                style: TextStyle(
                  fontSize: 14,
                  color: retPct >= 0 ? AppColors.upColor : AppColors.downColor,
                ),
              ),
            ],
          ),
          Text(
            'Realized P&L · $completed closed trades',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const Divider(height: 20),
          Row(
            children: [
              _KpiTile('Win Rate', '${winRate.toStringAsFixed(1)}%', AppColors.accentBlue),
              _KpiTile('Profit Factor', profitFactor.toStringAsFixed(2), Colors.amber),
              _KpiTile('Avg Win', '+HK\$${_fmt(avgWin)}', AppColors.upColor),
              _KpiTile('Avg Loss', '-HK\$${_fmt(avgLoss)}', AppColors.downColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

/// Module 2 — Monthly Returns horizontal bar chart
class _MonthlyReturnsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _MonthlyReturnsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _EmptyModuleCard('No completed trades yet');
    }
    final maxAbs = data.map((d) => ((d['pl'] as num?) ?? 0).toDouble().abs()).fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: data.map((item) {
          final pl = ((item['pl'] as num?) ?? 0).toDouble();
          final month = item['month']?.toString() ?? '';
          final barRatio = maxAbs > 0 ? (pl.abs() / maxAbs).clamp(0.02, 1.0) : 0.02;
          final color = pl >= 0 ? AppColors.upColor : AppColors.downColor;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(month.length >= 7 ? month.substring(2) : month,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(height: 16, color: AppColors.darkBg),
                      FractionallySizedBox(
                        widthFactor: barRatio,
                        child: Container(height: 16, color: color.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: Text(
                    '${pl >= 0 ? "+" : ""}HK\$${_fmt(pl.abs())}',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Module 3 — Cumulative P&L polyline chart (CustomPainter)
class _CumulativePLChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _CumulativePLChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return _EmptyModuleCard('Need at least 2 completed trades');
    }
    return Container(
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: CustomPaint(
        painter: _CumPLPainter(data),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CumPLPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _CumPLPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final values = data.map((d) => ((d['cumPL'] as num?) ?? 0).toDouble()).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV;
    if (range == 0) return;

    final isPositive = values.last >= 0;
    final lineColor = isPositive ? AppColors.upColor : AppColors.downColor;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height - (values[i] - minV) / range * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Zero line
    final zeroY = size.height - (0 - minV) / range * size.height;
    if (zeroY >= 0 && zeroY <= size.height) {
      canvas.drawLine(
        Offset(0, zeroY),
        Offset(size.width, zeroY),
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.3)
          ..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(_CumPLPainter old) => old.data != data;
}

/// Module 4 — Drawdown card
class _DrawdownCard extends StatelessWidget {
  final Map<String, dynamic> drawdown;
  const _DrawdownCard({required this.drawdown});

  @override
  Widget build(BuildContext context) {
    final maxDD = ((drawdown['maxDrawdown'] as num?) ?? 0).toDouble();
    final maxDDPct = ((drawdown['maxDrawdownPct'] as num?) ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_down, size: 32, color: Colors.orangeAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Max Drawdown', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  '-HK\$${_fmt(maxDD)} (${maxDDPct.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Module 5 — P&L by ticker list
class _SectorPLList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _SectorPLList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyModuleCard('No closed positions yet');
    }
    final maxAbs = items.map((d) => ((d['pl'] as num?) ?? 0).toDouble().abs()).fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: items.map((item) {
          final pl = ((item['pl'] as num?) ?? 0).toDouble();
          final ticker = item['ticker']?.toString() ?? '';
          final barRatio = maxAbs > 0 ? (pl.abs() / maxAbs).clamp(0.02, 1.0) : 0.02;
          final color = pl >= 0 ? AppColors.upColor : AppColors.downColor;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(ticker,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(height: 12, color: AppColors.darkBg),
                      FractionallySizedBox(
                        widthFactor: barRatio,
                        child: Container(height: 12, color: color.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 76,
                  child: Text(
                    '${pl >= 0 ? "+" : ""}HK\$${_fmt(pl.abs())}',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Module 6 — Holding period summary
class _HoldingPeriodCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HoldingPeriodCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final avgDays = ((data['avgDays'] as num?) ?? 0).toDouble();
    final details = (data['details'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
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
            children: [
              const Icon(Icons.timer_outlined, size: 20, color: AppColors.accentBlue),
              const SizedBox(width: 8),
              Text(
                'Avg Holding: ${avgDays.toStringAsFixed(1)} days',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const Divider(height: 16),
            ...details.take(5).map((h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.darkBg,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(h['ticker']?.toString() ?? '',
                        style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${h['buyDate']} → ${h['sellDate']}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                  Text(
                    '${h['holdingDays']}d',
                    style: const TextStyle(fontSize: 11, color: AppColors.accentBlue),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

/// Module 7 — Benchmark comparison (Portfolio vs HSI)
class _BenchmarkCard extends StatelessWidget {
  final Map<String, dynamic> benchmark;
  const _BenchmarkCard({required this.benchmark});

  @override
  Widget build(BuildContext context) {
    final portRet = ((benchmark['portfolioReturn'] as num?) ?? 0).toDouble();
    final hsiRet = ((benchmark['hsiYTD'] as num?) ?? 0).toDouble();
    final alpha = ((benchmark['alpha'] as num?) ?? 0).toDouble();

    final portColor = portRet >= 0 ? AppColors.upColor : AppColors.downColor;
    final hsiColor = hsiRet >= 0 ? AppColors.upColor : AppColors.downColor;
    final alphaColor = alpha >= 0 ? AppColors.upColor : AppColors.downColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _BenchmarkItem('My Portfolio', '${portRet >= 0 ? "+" : ""}${portRet.toStringAsFixed(2)}%', portColor),
              Container(width: 1, height: 40, color: AppColors.borderColor),
              _BenchmarkItem('HSI YTD', '${hsiRet >= 0 ? "+" : ""}${hsiRet.toStringAsFixed(2)}%', hsiColor),
              Container(width: 1, height: 40, color: AppColors.borderColor),
              _BenchmarkItem('Alpha', '${alpha >= 0 ? "+" : ""}${alpha.toStringAsFixed(2)}%', alphaColor,
                  subtitle: alpha >= 0 ? 'Outperforming' : 'Underperforming'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenchmarkItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? subtitle;
  const _BenchmarkItem(this.label, this.value, this.color, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          if (subtitle != null)
            Text(subtitle!, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

/// Empty state for modules with no data
class _EmptyModuleCard extends StatelessWidget {
  final String msg;
  const _EmptyModuleCard(this.msg);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}

/// Number formatter helper
String _fmt(double v) {
  if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
  if (v.abs() >= 1000) {
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
  return v.toStringAsFixed(2);
}
