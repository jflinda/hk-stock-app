import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hk_stock_app/constants/index.dart';
import 'package:hk_stock_app/models/index.dart';
import 'package:hk_stock_app/providers/market_providers.dart';
import 'package:hk_stock_app/providers/portfolio_providers.dart';
import 'package:hk_stock_app/providers/trades_providers.dart';
import 'package:hk_stock_app/services/api_service.dart';

/// Stock Detail Screen - Real API data with quote + history
class StockDetailScreen extends ConsumerStatefulWidget {
  final String ticker;
  final String name;

  const StockDetailScreen({
    required this.ticker,
    required this.name,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Period map: display label -> API period value
  static const _periods = [
    ('1D', '1d'),
    ('5D', '5d'),
    ('1M', '1mo'),
    ('3M', '3mo'),
    ('1Y', '1y'),
  ];

  String _selectedPeriodLabel = '1M';

  String get _selectedPeriodValue =>
      _periods.firstWhere((p) => p.$1 == _selectedPeriodLabel).$2;

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
    final quoteAsync =
        ref.watch(stockQuoteProvider(widget.ticker));
    final historyAsync = ref.watch(
        stockHistoryProvider((widget.ticker, _selectedPeriodValue)));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.name} (${widget.ticker})'),
        elevation: 0,
        backgroundColor: AppColors.darkBg,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(stockQuoteProvider(widget.ticker));
              ref.invalidate(stockHistoryProvider(
                  (widget.ticker, _selectedPeriodValue)));
            },
          ),
        ],
      ),
      body: quoteAsync.when(
        data: (quote) => _buildBody(quote, historyAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: 'Failed to load ${ widget.ticker}: $err',
          onRetry: () => ref.invalidate(stockQuoteProvider(widget.ticker)),
        ),
      ),
      floatingActionButton: quoteAsync.valueOrNull != null
          ? _QuickTradeButtons(
              ticker: widget.ticker,
              name: widget.name,
              currentPrice: quoteAsync.valueOrNull?.price ?? 0.0,
            )
          : null,
    );
  }

  Widget _buildBody(
      StockQuote quote, AsyncValue<List<KlineData>> historyAsync) {
    final isGainer = quote.changePct >= 0;
    final plColor = isGainer ? AppColors.upColor : AppColors.downColor;
    final sign = isGainer ? '+' : '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Price Hero ──────────────────────────────
          Container(
            color: AppColors.cardBg,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HK\$${quote.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$sign${quote.change.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 16,
                          color: plColor,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: plColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$sign${quote.changePct.toStringAsFixed(2)}%',
                        style: TextStyle(
                            fontSize: 14,
                            color: plColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    const Text('Delayed quote',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _PriceBadge(
                        label: 'Day High',
                        value:
                            'HK\$${(quote.dayHigh ?? quote.price).toStringAsFixed(2)}',
                        color: AppColors.upColor),
                    const SizedBox(width: 8),
                    _PriceBadge(
                        label: 'Day Low',
                        value:
                            'HK\$${(quote.dayLow ?? quote.price).toStringAsFixed(2)}',
                        color: AppColors.downColor),
                  ],
                ),
              ],
            ),
          ),

          // ── Key Statistics ────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Key Statistics',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                _StatsGrid([
                  _StatItem('52W High',
                      'HK\$${(quote.high52w ?? 0).toStringAsFixed(2)}'),
                  _StatItem('52W Low',
                      'HK\$${(quote.low52w ?? 0).toStringAsFixed(2)}'),
                  _StatItem(
                      'P/E Ratio',
                      quote.pe != null
                          ? '${quote.pe!.toStringAsFixed(1)}x'
                          : 'N/A'),
                  _StatItem(
                      'Dividend Yield',
                      quote.dividendYield != null
                          ? '${quote.dividendYield!.toStringAsFixed(2)}%'
                          : 'N/A'),
                  _StatItem('Market Cap', quote.marketCap ?? 'N/A'),
                  _StatItem('Volume',
                      _formatVolume(quote.volume ?? 0)),
                ]),
              ],
            ),
          ),

          // ── Chart with Period Selector ────────────────
          Container(
            color: AppColors.cardBg,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _periods
                      .map((p) => GestureDetector(
                            onTap: () {
                              setState(
                                  () => _selectedPeriodLabel = p.$1);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _selectedPeriodLabel == p.$1
                                    ? AppColors.accentBlue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.$1,
                                style: TextStyle(
                                  color:
                                      _selectedPeriodLabel == p.$1
                                          ? Colors.white
                                          : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Chart area
                historyAsync.when(
                  data: (klines) => _SimpleLineChart(
                    klines: klines,
                    isGainer: isGainer,
                  ),
                  loading: () => const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => SizedBox(
                    height: 180,
                    child: Center(
                      child: Text('Chart unavailable: $err',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab Section ───────────────────────────────
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'News'),
              Tab(text: 'Analysis'),
            ],
          ),

          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(quote: quote),
                _NewsTab(ticker: widget.ticker),
                _AnalysisTab(quote: quote),
              ],
            ),
          ),

          // Bottom padding for FAB
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _formatVolume(int vol) {
    if (vol >= 1e6) return '${(vol / 1e6).toStringAsFixed(1)}M';
    if (vol >= 1e3) return '${(vol / 1e3).toStringAsFixed(0)}K';
    return vol.toString();
  }
}

// ─────────────────────────────────────────────
// Simple Line / Area Chart (custom paint)
// ─────────────────────────────────────────────
class _SimpleLineChart extends StatelessWidget {
  final List<KlineData> klines;
  final bool isGainer;

  const _SimpleLineChart(
      {required this.klines, required this.isGainer});

  @override
  Widget build(BuildContext context) {
    if (klines.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
            child: Text('No data', style: TextStyle(color: Colors.grey))),
      );
    }

    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _LineChartPainter(
          klines: klines,
          lineColor: isGainer ? AppColors.upColor : AppColors.downColor,
        ),
        size: const Size(double.infinity, 180),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<KlineData> klines;
  final Color lineColor;

  _LineChartPainter({required this.klines, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (klines.length < 2) return;

    final prices = klines.map((k) => k.close).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    if (priceRange == 0) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = lineColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final xStep = size.width / (klines.length - 1);
    final padding = 20.0;
    final chartHeight = size.height - padding * 2;

    for (int i = 0; i < klines.length; i++) {
      final x = i * xStep;
      final y = padding +
          chartHeight * (1 - (klines[i].close - minPrice) / priceRange);

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
    canvas.drawPath(path, linePaint);

    // Draw current price label
    final lastPrice = klines.last.close;
    final lastX = (klines.length - 1) * xStep;
    final lastY = padding +
        chartHeight * (1 - (lastPrice - minPrice) / priceRange);

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(lastX, lastY), 4, dotPaint);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.klines != klines || old.lineColor != lineColor;
}

// ─────────────────────────────────────────────
// Overview Tab
// ─────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final StockQuote quote;
  const _OverviewTab({required this.quote});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            quote.longName ?? quote.name ?? quote.ticker,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13),
          ),
          if (quote.sector != null) ...[
            const SizedBox(height: 12),
            _InfoRow('Sector', quote.sector!),
          ],
          if (quote.industry != null) ...[
            const SizedBox(height: 6),
            _InfoRow('Industry', quote.industry!),
          ],
          if (quote.country != null) ...[
            const SizedBox(height: 6),
            _InfoRow('Country', quote.country!),
          ],
          if (quote.currency != null) ...[
            const SizedBox(height: 6),
            _InfoRow('Currency', quote.currency!),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// News Tab (placeholder - shows ticker-related tips)
// ─────────────────────────────────────────────
class _NewsTab extends StatelessWidget {
  final String ticker;
  const _NewsTab({required this.ticker});

  @override
  Widget build(BuildContext context) {
    // Placeholder news items - will be replaced by NewsAPI integration
    final items = [
      ('Market Update',
          'HK tech stocks rebound on positive macro signals',
          '2 hours ago'),
      ('Earnings Watch',
          '$ticker expected to report Q1 results next week',
          '1 day ago'),
      ('Analyst Note',
          'Multiple brokers maintain positive outlook on $ticker',
          '2 days ago'),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: items
          .map((item) => _NewsItem(
                category: item.$1,
                title: item.$2,
                time: item.$3,
              ))
          .toList(),
    );
  }
}

class _NewsItem extends StatelessWidget {
  final String category;
  final String title;
  final String time;

  const _NewsItem(
      {required this.category,
      required this.title,
      required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(time,
              style:
                  const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Analysis Tab (computed from quote data)
// ─────────────────────────────────────────────
class _AnalysisTab extends StatelessWidget {
  final StockQuote quote;
  const _AnalysisTab({required this.quote});

  @override
  Widget build(BuildContext context) {
    // Simple signals from price data
    final price = quote.price;
    final high52w = quote.high52w ?? price;
    final low52w = quote.low52w ?? price;
    final range = high52w - low52w;
    final positionInRange =
        range > 0 ? ((price - low52w) / range * 100) : 50.0;
    final pe = quote.pe;

    String peSignal = 'N/A';
    Color peColor = Colors.grey;
    if (pe != null) {
      if (pe < 15) {
        peSignal = 'Cheap';
        peColor = AppColors.upColor;
      } else if (pe < 25) {
        peSignal = 'Fair';
        peColor = AppColors.accentBlue;
      } else {
        peSignal = 'Expensive';
        peColor = AppColors.downColor;
      }
    }

    String rangeSignal;
    Color rangeColor;
    if (positionInRange >= 70) {
      rangeSignal = 'Near 52W High';
      rangeColor = AppColors.upColor;
    } else if (positionInRange <= 30) {
      rangeSignal = 'Near 52W Low';
      rangeColor = AppColors.downColor;
    } else {
      rangeSignal = 'Mid Range';
      rangeColor = AppColors.accentBlue;
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _AnalysisIndicator(
          name: '52W Range Position',
          value: '${positionInRange.toStringAsFixed(1)}%',
          signal: rangeSignal,
          color: rangeColor,
          barValue: positionInRange / 100,
        ),
        _AnalysisIndicator(
          name: 'P/E Valuation',
          value:
              pe != null ? '${pe.toStringAsFixed(1)}x' : 'N/A',
          signal: peSignal,
          color: peColor,
        ),
        _AnalysisIndicator(
          name: 'Day Change',
          value:
              '${quote.changePct >= 0 ? '+' : ''}${quote.changePct.toStringAsFixed(2)}%',
          signal: quote.changePct >= 0 ? 'Advancing' : 'Declining',
          color: quote.changePct >= 0
              ? AppColors.upColor
              : AppColors.downColor,
        ),
        if (quote.dividendYield != null)
          _AnalysisIndicator(
            name: 'Dividend Yield',
            value: '${quote.dividendYield!.toStringAsFixed(2)}%',
            signal: quote.dividendYield! > 3 ? 'High Yield' : 'Low Yield',
            color: quote.dividendYield! > 3
                ? AppColors.upColor
                : Colors.grey,
          ),
      ],
    );
  }
}

class _AnalysisIndicator extends StatelessWidget {
  final String name;
  final String value;
  final String signal;
  final Color color;
  final double? barValue;

  const _AnalysisIndicator({
    required this.name,
    required this.value,
    required this.signal,
    required this.color,
    this.barValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
                  Text(name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(signal,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          if (barValue != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: barValue!.clamp(0.0, 1.0),
              backgroundColor: AppColors.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Quick Trade Buttons (FAB)
// ─────────────────────────────────────────────
class _QuickTradeButtons extends ConsumerWidget {
  final String ticker;
  final String name;
  final double currentPrice;

  const _QuickTradeButtons({
    required this.ticker,
    required this.name,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'buy_fab',
            onPressed: () => _showTradeModal(context, ref, 'BUY'),
            backgroundColor: AppColors.upColor,
            label: const Text('BUY',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.arrow_downward, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'sell_fab',
            onPressed: () => _showTradeModal(context, ref, 'SELL'),
            backgroundColor: AppColors.downColor,
            label: const Text('SELL',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.arrow_upward, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showTradeModal(
      BuildContext context, WidgetRef ref, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _QuickTradeModal(
        ticker: ticker,
        name: name,
        currentPrice: currentPrice,
        initialType: type,
        ref: ref,
      ),
    );
  }
}

class _QuickTradeModal extends StatefulWidget {
  final String ticker;
  final String name;
  final double currentPrice;
  final String initialType;
  final WidgetRef ref;

  const _QuickTradeModal({
    required this.ticker,
    required this.name,
    required this.currentPrice,
    required this.initialType,
    required this.ref,
  });

  @override
  State<_QuickTradeModal> createState() => _QuickTradeModalState();
}

class _QuickTradeModalState extends State<_QuickTradeModal> {
  late String _type;
  late TextEditingController _priceController;
  final _quantityController = TextEditingController(text: '100');
  final _commissionController = TextEditingController(text: '30.0');
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _priceController = TextEditingController(
        text: widget.currentPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final price = double.tryParse(_priceController.text);
    final qty = int.tryParse(_quantityController.text);
    if (price == null || qty == null || qty <= 0 || price <= 0) {
      setState(() => _error = 'Please enter valid price and quantity');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await apiService.addTrade(
        ticker: widget.ticker,
        type: _type,
        quantity: qty,
        price: price,
        commission:
            double.tryParse(_commissionController.text) ?? 30.0,
        tradeDate: DateTime.now(),
      );

      // Refresh portfolio providers
      widget.ref.invalidate(tradesProvider);
      widget.ref.invalidate(portfolioSummaryProvider);
      widget.ref.invalidate(positionsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$_type ${widget.ticker} x$qty @ HK\$${price.toStringAsFixed(2)} added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets.bottom;
    final typeColor =
        _type == 'BUY' ? AppColors.upColor : AppColors.downColor;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          Text(
            '${widget.name} (${widget.ticker})',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // BUY / SELL toggle
          Row(
            children: ['BUY', 'SELL']
                .map((t) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: t == 'BUY' ? 6 : 0,
                            left: t == 'SELL' ? 6 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _type = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _type == t
                                  ? typeColor.withOpacity(0.2)
                                  : AppColors.darkBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _type == t
                                      ? typeColor
                                      : AppColors.borderColor,
                                  width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(t,
                                style: TextStyle(
                                    color: _type == t
                                        ? typeColor
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _Field(
                    controller: _priceController,
                    label: 'Price (HK\$)',
                    keyboard: TextInputType.number),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                    controller: _quantityController,
                    label: 'Shares',
                    keyboard: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _Field(
              controller: _commissionController,
              label: 'Commission (HK\$)',
              keyboard: TextInputType.number),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      '$_type ${widget.ticker}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;

  const _Field(
      {required this.controller,
      required this.label,
      this.keyboard});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
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
// Shared Widgets
// ─────────────────────────────────────────────
class _PriceBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PriceBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color.withOpacity(0.8))),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;
  const _StatsGrid(this.items);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.label,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(item.value,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  _StatItem(this.label, this.value);
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
