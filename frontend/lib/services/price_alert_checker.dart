import 'package:hk_stock_app/models/index.dart';
import 'package:hk_stock_app/services/notification_service.dart';

/// PriceAlertChecker — compares current watchlist prices against alert thresholds.
/// 
/// Called by the 30-second auto-refresh timer in main.dart.
/// Tracks which alerts have already fired to avoid spamming.
class PriceAlertChecker {
  PriceAlertChecker._();
  static final PriceAlertChecker instance = PriceAlertChecker._();

  // Keep track of previously fired alerts: ticker → last triggered price
  final Map<String, double> _lastAlertPrice = {};

  /// Check [items] for any price that has crossed its alert threshold.
  Future<void> check(List<WatchlistItem> items) async {
    for (final item in items) {
      if (item.alertPrice == null || item.alertPrice == 0) continue;
      final current = item.changePct != 0 ? item.price : null;
      if (current == null) continue;

      final target = item.alertPrice!;
      final lastFired = _lastAlertPrice[item.ticker];
      final id = item.ticker.hashCode.abs();

      bool shouldFire = false;
      bool above = false;

      if (current >= target && (lastFired == null || lastFired < target)) {
        shouldFire = true;
        above = true;
      } else if (current <= target && (lastFired == null || lastFired > target)) {
        shouldFire = true;
        above = false;
      }

      if (shouldFire) {
        _lastAlertPrice[item.ticker] = current;
        await NotificationService.instance.showPriceAlert(
          id: id,
          ticker: item.ticker,
          name: item.name,
          price: current,
          target: target,
          above: above,
        );
      }
    }
  }

  void reset(String ticker) {
    _lastAlertPrice.remove(ticker);
  }
}
