import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hk_stock_app/models/index.dart';
import 'package:hk_stock_app/services/api_service.dart';

/// Provider for market indices
/// Fetches and caches: HSI, HSCEI, HSTI, S&P 500, SSE
final marketIndicesProvider = FutureProvider<List<MarketIndex>>((ref) async {
  return apiService.getMarketIndices();
});

/// Provider for market movers (gainers, losers, turnover)
final marketMoversProvider = FutureProvider<Movers>((ref) async {
  return apiService.getMovers();
});

/// Parameterized provider for single stock quote
final stockQuoteProvider = FutureProvider.family<StockQuote, String>((ref, ticker) async {
  return apiService.getStockQuote(ticker);
});

/// Parameterized provider for stock history with period parameter
final stockHistoryProvider = 
    FutureProvider.family<List<KlineData>, (String ticker, String period)>((ref, params) async {
  final (ticker, period) = params;
  return apiService.getStockHistory(ticker, period);
});

/// State provider for current selected stock ticker
final selectedStockProvider = StateProvider<String>((ref) => '0700');

/// State provider for current K-line period selector
final klinePeriodProvider = StateProvider<String>((ref) => '1mo');

/// State provider for current tab index
final currentTabProvider = StateProvider<int>((ref) => 0);

/// State provider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for stock search results
final stockSearchProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  return apiService.searchStocks(query);
});
