import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hk_stock_app/models/index.dart';
import 'package:hk_stock_app/services/api_service.dart';
import 'package:hk_stock_app/providers/portfolio_providers.dart';

/// Provider for trade history
final tradesProvider = FutureProvider<List<Trade>>((ref) async {
  return apiService.getTrades(limit: 100, offset: 0);
});

/// State provider for trades filter/sort
final tradesSortProvider = StateProvider<String>((ref) => 'date_desc');

/// Computed provider for sorted trades
final sortedTradesProvider = FutureProvider<List<Trade>>((ref) async {
  final trades = await ref.watch(tradesProvider.future);
  final sorted = List<Trade>.from(trades);
  final sortBy = ref.watch(tradesSortProvider);

  switch (sortBy) {
    case 'date_desc':
      sorted.sort((a, b) => b.tradeDate.compareTo(a.tradeDate));
      break;
    case 'date_asc':
      sorted.sort((a, b) => a.tradeDate.compareTo(b.tradeDate));
      break;
    case 'pl_desc':
      sorted.sort((a, b) => b.pl.compareTo(a.pl));
      break;
    case 'pl_asc':
      sorted.sort((a, b) => a.pl.compareTo(b.pl));
      break;
  }

  return sorted;
});

/// Computed provider for trades statistics
final tradesStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final trades = await ref.watch(tradesProvider.future);

  final buyTrades = trades.where((t) => t.type == 'BUY').toList();
  final sellTrades = trades.where((t) => t.type == 'SELL').toList();

  final totalCost = buyTrades.fold<double>(
    0.0,
    (sum, t) => sum + (t.quantity * t.price + t.commission),
  );

  final totalSaleValue = sellTrades.fold<double>(
    0.0,
    (sum, t) => sum + (t.quantity * t.price - t.commission),
  );

  final totalPL = sellTrades.fold<double>(
    0.0,
    (sum, t) => sum + t.pl,
  );

  final winningTrades = sellTrades.where((t) => t.pl > 0).length;
  final losingTrades = sellTrades.where((t) => t.pl < 0).length;
  final winRate = sellTrades.isEmpty ? 0.0 : winningTrades / sellTrades.length;

  final avgWin = winningTrades == 0
      ? 0.0
      : sellTrades
              .where((t) => t.pl > 0)
              .fold<double>(0.0, (sum, t) => sum + t.pl) /
          winningTrades;

  final avgLoss = losingTrades == 0
      ? 0.0
      : sellTrades
              .where((t) => t.pl < 0)
              .fold<double>(0.0, (sum, t) => sum + t.pl) /
          losingTrades;

  return {
    'totalBuys': buyTrades.length,
    'totalSells': sellTrades.length,
    'totalCost': totalCost,
    'totalSaleValue': totalSaleValue,
    'totalPL': totalPL,
    'winRate': winRate,
    'avgWin': avgWin,
    'avgLoss': avgLoss,
  };
});

/// Family provider for adding a trade
final addTradeProvider = FutureProvider.family<Trade, ({
  String ticker,
  String type,
  int quantity,
  double price,
  double commission,
  DateTime tradeDate,
  String? notes,
})>((ref, params) async {
  final trade = await apiService.addTrade(
    ticker: params.ticker,
    type: params.type,
    quantity: params.quantity,
    price: params.price,
    commission: params.commission,
    tradeDate: params.tradeDate,
    notes: params.notes,
  );
  // Invalidate caches after adding trade
  ref.invalidate(tradesProvider);
  ref.invalidate(portfolioSummaryProvider);
  ref.invalidate(positionsProvider);
  return trade;
});

/// Family provider for deleting a trade
final deleteTradeProvider = FutureProvider.family<void, String>((ref, tradeId) async {
  await apiService.deleteTrade(tradeId);
  // Invalidate caches after deleting trade
  ref.invalidate(tradesProvider);
  ref.invalidate(portfolioSummaryProvider);
  ref.invalidate(positionsProvider);
});
