import 'package:flutter/material.dart';

/// App colors - following Chinese stock market convention (red = up, green = down)
class AppColors {
  /// Up/Gain color (red) - Hong Kong convention
  static const Color upColor = Color(0xFFF03E3E);

  /// Down/Loss color (green) - Hong Kong convention
  static const Color downColor = Color(0xFF3FB950);

  /// Neutral color (gray)
  static const Color neutralColor = Color(0xFF757575);

  /// Primary color
  static const Color primary = Color(0xFF58A6FF);

  /// Primary dark
  static const Color primaryDark = Color(0xFF1565C0);

  /// Accent blue (used for highlights and interactive elements)
  static const Color accentBlue = Color(0xFF58A6FF);

  /// Dark background (main app background)
  static const Color darkBg = Color(0xFF0D1117);

  /// Card background (slightly lighter than darkBg)
  static const Color cardBg = Color(0xFF161B22);

  /// Border color for cards and dividers
  static const Color borderColor = Color(0xFF30363D);

  /// Background light
  static const Color backgroundLight = Color(0xFFFAFAFA);

  /// Background dark (alias)
  static const Color backgroundDark = Color(0xFF0D1117);

  /// Card background alias
  static const Color cardBackground = Color(0xFF161B22);

  /// Text primary
  static const Color textPrimary = Color(0xFFE6EDF3);

  /// Text secondary
  static const Color textSecondary = Color(0xFF8B949E);

  /// Divider color
  static const Color divider = Color(0xFF30363D);
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
