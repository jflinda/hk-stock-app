import 'package:flutter/material.dart';
import 'package:hk_stock_app/constants/index.dart';

/// Tools Screen - Provides calculation and analysis tools
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({Key? key}) : super(key: key);

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

class _PositionSizer extends StatefulWidget {
  @override
  State<_PositionSizer> createState() => _PositionSizerState();
}

class _PositionSizerState extends State<_PositionSizer> {
  final portfolioValueCtrl = TextEditingController(text: '100000');
  final riskPctCtrl = TextEditingController(text: '2');
  final entryPriceCtrl = TextEditingController(text: '250');
  final stopLossCtrl = TextEditingController(text: '240');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InputField('Portfolio Value (HK\$)', portfolioValueCtrl),
          _InputField('Risk %', riskPctCtrl),
          _InputField('Entry Price (HK\$)', entryPriceCtrl),
          _InputField('Stop Loss (HK\$)', stopLossCtrl),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculatePosition,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Calculate Position Size'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Divider(),
                _ResultRow('Suggested Shares', '816 shares'),
                _ResultRow('Position Value', 'HK\$204,000'),
                _ResultRow('Risk Amount', 'HK\$2,000'),
                _ResultRow('Risk per Share', 'HK\$2.45'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _calculatePosition() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Position size calculated')),
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

class _PnLCalculator extends StatefulWidget {
  @override
  State<_PnLCalculator> createState() => _PnLCalculatorState();
}

class _PnLCalculatorState extends State<_PnLCalculator> {
  final buyPriceCtrl = TextEditingController(text: '250');
  final sellPriceCtrl = TextEditingController(text: '265');
  final sharesCtrl = TextEditingController(text: '1000');
  final feeCtrl = TextEditingController(text: '100');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _InputField('Buy Price (HK\$)', buyPriceCtrl),
          _InputField('Sell Price (HK\$)', sellPriceCtrl),
          _InputField('Shares', sharesCtrl),
          _InputField('Commission (HK\$)', feeCtrl),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculatePnL,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Calculate P&L'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('P&L Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Divider(),
                _ResultRow('Gross Profit', 'HK\$15,000', textColor: AppColors.upColor),
                _ResultRow('Net Profit', 'HK\$14,900', textColor: AppColors.upColor),
                _ResultRow('Return %', '+5.96%', textColor: AppColors.upColor),
                _ResultRow('Avg Cost', 'HK\$250.10'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _calculatePnL() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('P&L calculated')),
    );
  }

  @override
  void dispose() {
    buyPriceCtrl.dispose();
    sellPriceCtrl.dispose();
    sharesCtrl.dispose();
    feeCtrl.dispose();
    super.dispose();
  }
}

class _CurrencyConverter extends StatefulWidget {
  @override
  State<_CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<_CurrencyConverter> {
  final amountCtrl = TextEditingController(text: '1000');
  String fromCurrency = 'HKD';
  String toCurrency = 'USD';

  final rates = {
    'HKD': 1.0,
    'USD': 0.128,
    'CNY': 0.93,
    'EUR': 0.117,
    'GBP': 0.102,
    'JPY': 19.2,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: amountCtrl,
            decoration: InputDecoration(
              labelText: 'Amount',
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField(
                  value: fromCurrency,
                  items: rates.keys
                      .map((curr) => DropdownMenuItem(value: curr, child: Text(curr)))
                      .toList(),
                  onChanged: (value) => setState(() => fromCurrency = value!),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () => setState(() {
                  final temp = fromCurrency;
                  fromCurrency = toCurrency;
                  toCurrency = temp;
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField(
                  value: toCurrency,
                  items: rates.keys
                      .map((curr) => DropdownMenuItem(value: curr, child: Text(curr)))
                      .toList(),
                  onChanged: (value) => setState(() => toCurrency = value!),
                  decoration: InputDecoration(
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Converted Amount', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  _convertCurrency(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${amountCtrl.text} $fromCurrency = ${_convertCurrency()} $toCurrency',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _convertCurrency() {
    try {
      final amount = double.parse(amountCtrl.text);
      final rate = (rates[toCurrency] ?? 1) / (rates[fromCurrency] ?? 1);
      return (amount * rate).toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _InputField(this.label, this.controller);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? textColor;

  const _ResultRow(this.label, this.value, {this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}
