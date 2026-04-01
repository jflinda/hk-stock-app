import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// NotificationService — wraps flutter_local_notifications for:
///   • Price alerts (when a watched stock crosses a threshold)
///   • Daily market summary (morning briefing)
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Channel definitions ────────────────────────────────────────────────────
  static const _priceAlertChannel = AndroidNotificationChannel(
    'price_alerts',
    'Price Alerts',
    description: 'Notifications when a stock price crosses your alert threshold',
    importance: Importance.high,
    playSound: true,
  );

  static const _dailySummaryChannel = AndroidNotificationChannel(
    'daily_summary',
    'Daily Market Summary',
    description: 'Daily morning briefing with market overview',
    importance: Importance.defaultImportance,
  );

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create channels on Android
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_priceAlertChannel);
      await androidPlugin.createNotificationChannel(_dailySummaryChannel);
      await androidPlugin.requestNotificationsPermission();
    }

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Future: navigate to relevant screen based on payload
    // e.g. payload = '0700.HK' → open Stock Detail
  }

  // ── Price Alert ───────────────────────────────────────────────────────────

  /// Show a price alert notification.
  ///
  /// [id]     – unique notification id (use ticker hash)
  /// [ticker] – e.g. "0700.HK"
  /// [name]   – e.g. "Tencent Holdings"
  /// [price]  – current price
  /// [target] – the alert threshold
  /// [above]  – true = price crossed above, false = crossed below
  Future<void> showPriceAlert({
    required int id,
    required String ticker,
    required String name,
    required double price,
    required double target,
    required bool above,
  }) async {
    await _ensureInit();

    final direction = above ? '▲ above' : '▼ below';
    await _plugin.show(
      id,
      '🔔 $ticker Price Alert',
      '$name is now HK\$${price.toStringAsFixed(2)} — $direction your target HK\$${target.toStringAsFixed(2)}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _priceAlertChannel.id,
          _priceAlertChannel.name,
          channelDescription: _priceAlertChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          color: above ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
        ),
      ),
      payload: ticker,
    );
  }

  // ── Daily Market Summary ──────────────────────────────────────────────────

  /// Show the daily morning market summary notification.
  ///
  /// [hsiChange]   – HSI change%  e.g. +0.83
  /// [gainers]     – top gainers text, e.g. "0700 +3.2%"
  /// [portfolioPL] – today's unrealized P&L change text
  Future<void> showDailySummary({
    required double hsiChange,
    required String gainers,
    required String portfolioPL,
  }) async {
    await _ensureInit();

    final hsiSign = hsiChange >= 0 ? '+' : '';
    final hsiStr = '$hsiSign${hsiChange.toStringAsFixed(2)}%';

    await _plugin.show(
      9999, // fixed id — always replaces yesterday's summary
      '📊 HK Market Morning Brief',
      'HSI $hsiStr · Top: $gainers · Portfolio: $portfolioPL',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          'Daily Market Summary',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }
}
