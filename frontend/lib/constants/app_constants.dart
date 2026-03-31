import 'package:flutter/material.dart';

/// App colors - following Chinese stock market convention (red = up, green = down)
class AppColors {
  /// Up/Gain color (red)
  static const Color upColor = Color(0xFFD32F2F);
  
  /// Down/Loss color (green)
  static const Color downColor = Color(0xFF388E3C);
  
  /// Neutral color (gray)
  static const Color neutralColor = Color(0xFF757575);
  
  /// Primary color
  static const Color primary = Color(0xFF1976D2);
  
  /// Primary dark
  static const Color primaryDark = Color(0xFF1565C0);
  
  /// Background light
  static const Color backgroundLight = Color(0xFFFAFAFA);
  
  /// Background dark
  static const Color backgroundDark = Color(0xFF121212);
  
  /// Card background
  static const Color cardBackground = Colors.white;
  
  /// Text primary
  static const Color textPrimary = Color(0xFF212121);
  
  /// Text secondary
  static const Color textSecondary = Color(0xFF757575);
  
  /// Divider color
  static const Color divider = Color(0xFFE0E0E0);
}

/// App sizing constants
class AppSizes {
  static const double paddingXs = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXl = 32.0;
  
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
}

/// Bottom navigation tab information
class BottomNavTabs {
  static const List<BottomNavTab> tabs = [
    BottomNavTab(
      label: 'Portfolio',
      icon: Icons.wallet,
      index: 0,
    ),
    BottomNavTab(
      label: 'Market',
      icon: Icons.trending_up,
      index: 1,
    ),
    BottomNavTab(
      label: 'Watchlist',
      icon: Icons.star,
      index: 2,
    ),
    BottomNavTab(
      label: 'Tools',
      icon: Icons.build,
      index: 3,
    ),
    BottomNavTab(
      label: 'Settings',
      icon: Icons.settings,
      index: 4,
    ),
  ];
}

/// Single bottom navigation tab
class BottomNavTab {
  final String label;
  final IconData icon;
  final int index;
  
  const BottomNavTab({
    required this.label,
    required this.icon,
    required this.index,
  });
}

/// API endpoints
class ApiEndpoints {
  static const String baseUrl = 'http://localhost:8000/api';
  static const String marketIndices = '/market/indices';
  static const String marketMovers = '/market/movers';
  static const String stockQuote = '/stock/:ticker/quote';
  static const String stockHistory = '/stock/:ticker/history';
  static const String stockSearch = '/stock/search';
}

/// Period options for K-line charts
class PeriodOptions {
  static const List<String> periods = ['1d', '5d', '1mo', '3mo', '1y'];
  static const Map<String, String> periodLabels = {
    '1d': '1 Day',
    '5d': '5 Days',
    '1mo': '1 Month',
    '3mo': '3 Months',
    '1y': '1 Year',
  };
}
