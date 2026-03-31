import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hk_stock_app/models/index.dart';
import 'package:hk_stock_app/services/api_service.dart';

/// Provider for watchlist items
final watchlistProvider = FutureProvider<List<WatchlistItem>>((ref) async {
  return apiService.getWatchlist();
});

/// State provider for watchlist filter
final watchlistFilterProvider = StateProvider<String>((ref) => 'all');

/// Computed provider for filtered watchlist
final filteredWatchlistProvider = 
    FutureProvider<List<WatchlistItem>>((ref) async {
  final watchlist = await ref.watch(watchlistProvider.future);
  final filter = ref.watch(watchlistFilterProvider);
  
  return watchlist.where((item) {
    switch (filter) {
      case 'gainers':
        return item.changePct > 0;
      case 'losers':
        return item.changePct < 0;
      case 'alerts':
        return item.alertPrice != null;
      default:
        return true;
    }
  }).toList();
});

/// Provider for watchlist statistics
final watchlistStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final watchlist = await ref.watch(watchlistProvider.future);
  
  final gainersCount = watchlist.where((item) => item.changePct > 0).length;
  final losersCount = watchlist.where((item) => item.changePct < 0).length;
  final avgChangePct = watchlist.isEmpty
      ? 0.0
      : watchlist.map((item) => item.changePct).reduce((a, b) => a + b) /
          watchlist.length;
  
  return {
    'total': watchlist.length,
    'gainers': gainersCount,
    'losers': losersCount,
    'avgChangePct': avgChangePct,
  };
});

/// Family provider for adding to watchlist
final addToWatchlistProvider = FutureProvider.family<WatchlistItem, String>(
  (ref, ticker) async {
    return apiService.addToWatchlist(ticker);
  },
);

/// Family provider for removing from watchlist
final removeFromWatchlistProvider = FutureProvider.family<void, String>(
  (ref, ticker) async {
    await apiService.removeFromWatchlist(ticker);
    // Invalidate watchlist cache to refresh
    ref.invalidate(watchlistProvider);
  },
);
