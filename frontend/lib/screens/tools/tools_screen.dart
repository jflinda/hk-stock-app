import 'package:flutter/material.dart';
import 'package:hk_stock_app/constants/index.dart';

/// Tools Screen - Provides calculation and analysis tools
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> with SingleTickerProviderStateMixin {
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
        title: const Text('Tools'),
        elevation: 0,
        backgroundColor: AppColors.darkBg,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Position'),
            Tab(text: 'P&L'),
            Tab(text: 'Currency'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PositionSizer(),
          _PnLCalculator(),
          _CurrencyConverter(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Position Sizer
// ─────────────────────────────────────────
class _PositionSizer extends StatefulWidget {
  @override
  State<_PositionSizer> createState() => _PositionSizerState();
}

class _PositionSizerState extends State<_PositionSizer> {
  final _formKey = GlobalKey<FormState>();
  final portfolioValueCtrl = TextEditingController(text: '500000');
  final riskPctCtrl = TextEditingController(text: '2');
  final entryPriceCtrl = TextEditingController(text: '250');
  final stopLossCtrl = TextEditingController(text: '240');

  // Result state
  int? _suggestedShares;
  double? _positionValue;
  double? _riskAmount;
  double? _riskPerShare;
  double? _portfolioWeight;
  String? _errorMsg;

  void _calculatePosition() {
    if (!_formKey.currentState!.validate()) return;

    final portfolioValue = double.tryParse(portfolioValueCtrl.text) ?? 0;
    final riskPct = double.tryParse(riskPctCtrl.text) ?? 0;
    final entryPrice = double.tryParse(entryPriceCtrl.text) ?? 0;
    final stopLoss = double.tryParse(stopLossCtrl.text) ?? 0;

    if (entryPrice <= stopLoss) {
      setState(() {
        _errorMsg = 'Entry price must be greater than stop loss';
        _suggestedShares = null;
      });
      return;
    }

    final riskAmount = portfolioValue * (riskPct / 100);
    final riskPerShare = entryPrice - stopLoss;
    // Round down to nearest lot (100 shares for HK stocks)
    final rawShares = (riskAmount / riskPerShare).floor();
    final suggestedShares = (rawShares ~/ 100) * 100;
    final positionValue = suggestedShares * entryPrice;
    final portfolioWeight = (positionValue / portfolioValue) * 100;

    setState(() {
      _errorMsg = null;
      _suggestedShares = suggestedShares;
      _riskAmount = riskAmount;
      _riskPerShare = riskPerShare;
      _positionValue = positionValue;
      _portfolioWeight = portfolioWeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ValidatedField(
              label: 'Portfolio Value (HK\$)',
              controller: portfolioValueCtrl,
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter a valid amount' : null,
            ),
            _ValidatedField(
              label: 'Risk % per Trade',
              controller: riskPctCtrl,
              validator: (v) {
                final d = double.tryParse(v ?? '');
                if (d == null || d <= 0 || d > 100) return 'Enter 0.1 – 100';
                return null;
              },
            ),
            _ValidatedField(
              label: 'Entry Price (HK\$)',
              controller: entryPriceCtrl,
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter a valid price' : null,
            ),
            _ValidatedField(
              label: 'Stop Loss Price (HK\$)',
              controller: stopLossCtrl,
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter a valid price' : null,
            ),
            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _calculatePosition,
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Calculate Position Size'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 16),
            _ResultCard(
              title: 'Position Sizing Results',
              children: _suggestedShares == null
                  ? [const _EmptyResult()]
                  : [
                      _ResultRow('Suggested Shares', '${_formatInt(_suggestedShares!)} shares',
                          textColor: AppColors.upColor),
                      _ResultRow('Position Value', 'HK\$${_formatMoney(_positionValue!)}'),
                      _ResultRow('Portfolio Weight', '${_portfolioWeight!.toStringAsFixed(1)}%'),
                      _ResultRow('Risk Amount', 'HK\$${_formatMoney(_riskAmount!)}',
                          textColor: Colors.orangeAccent),
                      _ResultRow('Risk per Share', 'HK\$${_positionValue! > 0 ? _formatMoney(_riskPerShare!) : "—"}'),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    portfolioValueCtrl.dispose();
    riskPctCtrl.dispose();
    entryPriceCtrl.dispose();
    stopLossCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────
// P&L Calculator
// ─────────────────────────────────────────
class _PnLCalculator extends StatefulWidget {
  @override
  State<_PnLCalculator> createState() => _PnLCalculatorState();
}

class _PnLCalculatorState extends State<_PnLCalculator> {
  final _formKey = GlobalKey<FormState>();
  final buyPriceCtrl = TextEditingController(text: '250');
  final sellPriceCtrl = TextEditingController(text: '265');
  final sharesCtrl = TextEditingController(text: '1000');
  final buyFeeCtrl = TextEditingController(text: '100');
  final sellFeeCtrl = TextEditingController(text: '100');

  // Result state
  double? _grossProfit;
  double? _netProfit;
  double? _returnPct;
  double? _totalCost;
  double? _totalRevenue;
  bool? _isProfit;

  void _calculatePnL() {
    if (!_formKey.currentState!.validate()) return;

    final buyPrice = double.parse(buyPriceCtrl.text);
    final sellPrice = double.parse(sellPriceCtrl.text);
    final shares = double.parse(sharesCtrl.text);
    final buyFee = double.tryParse(buyFeeCtrl.text) ?? 0;
    final sellFee = double.tryParse(sellFeeCtrl.text) ?? 0;

    final totalCost = buyPrice * shares + buyFee;
    final totalRevenue = sellPrice * shares - sellFee;
    final grossProfit = (sellPrice - buyPrice) * shares;
    final netProfit = totalRevenue - (buyPrice * shares + buyFee);
    final returnPct = (netProfit / totalCost) * 100;

    setState(() {
      _grossProfit = grossProfit;
      _netProfit = netProfit;
      _returnPct = returnPct;
      _totalCost = totalCost;
      _totalRevenue = totalRevenue;
      _isProfit = netProfit >= 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profitColor = (_isProfit ?? true) ? AppColors.upColor : AppColors.downColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _ValidatedField(
              label: 'Buy Price (HK\$)',
              controller: buyPriceCtrl,
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter a valid price' : null,
            ),
            _ValidatedField(
              label: 'Sell Price (HK\$)',
              controller: sellPriceCtrl,
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter a valid price' : null,
            ),
            _ValidatedField(
              label: 'Number of Shares',
              controller: sharesCtrl,
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter valid quantity' : null,
            ),
            _ValidatedField(
              label: 'Buy Commission (HK\$)',
              controller: buyFeeCtrl,
              validator: (v) => (double.tryParse(v ?? '')) == null ? 'Enter a number' : null,
            ),
            _ValidatedField(
              label: 'Sell Commission (HK\$)',
              controller: sellFeeCtrl,
              validator: (v) => (double.tryParse(v ?? '')) == null ? 'Enter a number' : null,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _calculatePnL,
              icon: const Icon(Icons.show_chart, size: 18),
              label: const Text('Calculate P&L'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 16),
            _ResultCard(
              title: 'P&L Results',
              children: _netProfit == null
                  ? [const _EmptyResult()]
                  : [
                      _ResultRow(
                        'Gross Profit',
                        '${_grossProfit! >= 0 ? "+" : ""}HK\$${_formatMoney(_grossProfit!.abs())}',
                        textColor: _grossProfit! >= 0 ? AppColors.upColor : AppColors.downColor,
                      ),
                      _ResultRow(
                        'Net Profit',
                        '${_netProfit! >= 0 ? "+" : "-"}HK\$${_formatMoney(_netProfit!.abs())}',
                        textColor: profitColor,
                      ),
                      _ResultRow(
                        'Return %',
                        '${_returnPct! >= 0 ? "+" : ""}${_returnPct!.toStringAsFixed(2)}%',
                        textColor: profitColor,
                      ),
                      const Divider(height: 16),
                      _ResultRow('Total Cost', 'HK\$${_formatMoney(_totalCost!)}'),
                      _ResultRow('Total Revenue', 'HK\$${_formatMoney(_totalRevenue!)}'),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    buyPriceCtrl.dispose();
    sellPriceCtrl.dispose();
    sharesCtrl.dispose();
    buyFeeCtrl.dispose();
    sellFeeCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────
// Currency Converter
// ─────────────────────────────────────────
class _CurrencyConverter extends StatefulWidget {
  @override
  State<_CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<_CurrencyConverter> {
  final amountCtrl = TextEditingController(text: '1000');
  String fromCurrency = 'HKD';
  String toCurrency = 'USD';

  // Rates relative to HKD base
  final Map<String, double> rates = {
    'HKD': 1.0,
    'USD': 0.1282,
    'CNY': 0.9302,
    'EUR': 0.1169,
    'GBP': 0.1013,
    'JPY': 19.24,
    'SGD': 0.1721,
    'AUD': 0.1962,
  };

  String get _convertedAmount {
    try {
      final amount = double.parse(amountCtrl.text);
      final rate = (rates[toCurrency] ?? 1) / (rates[fromCurrency] ?? 1);
      return (amount * rate).toStringAsFixed(2);
    } catch (e) {
      return '—';
    }
  }

  String get _rateDisplay {
    final rate = (rates[toCurrency] ?? 1) / (rates[fromCurrency] ?? 1);
    return '1 $fromCurrency = ${rate.toStringAsFixed(4)} $toCurrency';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: amountCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Amount',
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: fromCurrency,
                  items: rates.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => fromCurrency = v!),
                  decoration: InputDecoration(
                    labelText: 'From',
                    filled: true,
                    fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.cardBg,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.swap_horiz, color: AppColors.accentBlue),
                  onPressed: () => setState(() {
                    final tmp = fromCurrency;
                    fromCurrency = toCurrency;
                    toCurrency = tmp;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: toCurrency,
                  items: rates.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => toCurrency = v!),
                  decoration: InputDecoration(
                    labelText: 'To',
                    filled: true,
                    fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(
                  _convertedAmount,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  toCurrency,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const Divider(height: 24),
                Text(
                  _rateDisplay,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '${amountCtrl.text.isEmpty ? "0" : amountCtrl.text} $fromCurrency = $_convertedAmount $toCurrency',
                  style: TextStyle(fontSize: 11, color: Colors.grey.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Rates are indicative only. Updated periodically.',
            style: TextStyle(fontSize: 10, color: Colors.grey.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────

/// Text field with built-in form validation
class _ValidatedField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const _ValidatedField({required this.label, required this.controller, this.validator});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          errorStyle: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}

/// Results container card
class _ResultCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ResultCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Divider(),
          ...children,
        ],
      ),
    );
  }
}

/// Single result row with label and value
class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? textColor;

  const _ResultRow(this.label, this.value, {this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: textColor,
              )),
        ],
      ),
    );
  }
}

/// Placeholder when no calculation has been run yet
class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          'Fill in the fields above and press Calculate',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Formatting helpers
// ─────────────────────────────────────────
String _formatMoney(double value) {
  if (value.abs() >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(2)}M';
  } else if (value.abs() >= 1000) {
    final parts = value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return parts;
  }
  return value.toStringAsFixed(2);
}

String _formatInt(int value) {
  return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
