import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hk_stock_app/constants/index.dart';
import 'package:hk_stock_app/providers/market_providers.dart';
import 'package:hk_stock_app/providers/portfolio_providers.dart';
import 'package:hk_stock_app/providers/watchlist_providers.dart';
import 'package:hk_stock_app/screens/portfolio/portfolio_screen.dart';
import 'package:hk_stock_app/screens/market/market_screen.dart';
import 'package:hk_stock_app/screens/watchlist/watchlist_screen.dart';
import 'package:hk_stock_app/screens/tools/tools_screen.dart';
import 'package:hk_stock_app/screens/settings/settings_screen.dart';
import 'package:hk_stock_app/services/api_service.dart';
import 'package:hk_stock_app/services/notification_service.dart';
import 'package:hk_stock_app/services/price_alert_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Use real backend API (backend must be running on localhost:8000)
  apiService.setMockMode(false);
  // Initialise local notifications (price alerts, daily summary)
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: HKStockApp()));
}

class HKStockApp extends StatelessWidget {
  const HKStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HK Stock Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentBlue,
          secondary: AppColors.accentBlue,
          surface: AppColors.cardBg,
          background: AppColors.darkBg,
        ),
        scaffoldBackgroundColor: AppColors.darkBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBg,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.cardBg,
          selectedItemColor: AppColors.accentBlue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.accentBlue,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkBg,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accentBlue),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.cardBg,
          titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
          contentTextStyle:
              TextStyle(color: Colors.white70, fontSize: 14),
        ),
        useMaterial3: true,
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  Timer? _refreshTimer;
  static const _refreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    // Auto-refresh market data every 30 seconds
    _refreshTimer =
        Timer.periodic(_refreshInterval, (_) => _autoRefresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _autoRefresh() {
    // Refresh market data silently in background
    ref.invalidate(marketIndicesProvider);
    ref.invalidate(marketMoversProvider);
    // Refresh watchlist prices
    ref.invalidate(watchlistProvider);
    // Refresh portfolio positions
    ref.invalidate(portfolioSummaryProvider);
    ref.invalidate(positionsProvider);

    // Check price alerts against updated watchlist data
    final watchlistAsync = ref.read(watchlistProvider);
    watchlistAsync.whenData((items) async {
      await PriceAlertChecker.instance.check(items);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);

    final screens = [
      const PortfolioScreen(),
      const MarketScreen(),
      const WatchlistScreen(),
      const ToolsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderColor, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentTab,
          onTap: (index) {
            ref.read(currentTabProvider.notifier).state = index;
          },
          items: BottomNavTabs.tabs
              .map((tab) => BottomNavigationBarItem(
                    icon: Icon(tab.icon),
                    label: tab.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
