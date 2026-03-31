import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hk_stock_app/constants/index.dart';
import 'package:hk_stock_app/providers/market_providers.dart';
import 'package:hk_stock_app/screens/portfolio/portfolio_screen.dart';
import 'package:hk_stock_app/screens/market/market_screen.dart';
import 'package:hk_stock_app/screens/watchlist/watchlist_screen.dart';
import 'package:hk_stock_app/screens/tools/tools_screen.dart';
import 'package:hk_stock_app/screens/settings/settings_screen.dart';
import 'package:hk_stock_app/services/api_service.dart';

void main() {
  // Enable mock mode for UI testing when backend is not available
  apiService.setMockMode(true);
  
  runApp(const ProviderScope(child: HKStockApp()));
}

class HKStockApp extends StatelessWidget {
  const HKStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HK Stock Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    
    // Build list of screens for each tab
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab,
        onTap: (index) {
          ref.read(currentTabProvider.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        items: BottomNavTabs.tabs
            .map((tab) => BottomNavigationBarItem(
                  icon: Icon(tab.icon),
                  label: tab.label,
                ))
            .toList(),
      ),
    );
  }
}

