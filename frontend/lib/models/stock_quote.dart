import 'package:json_annotation/json_annotation.dart';

part 'stock_quote.g.dart';

/// Stock Quote Model - detailed information about a single stock
@JsonSerializable()
class StockQuote {
  /// Stock ticker code (e.g., "0700")
  final String ticker;
  
  /// Stock symbol with market (e.g., "0700.HK")
  final String symbol;
  
  /// Company name or stock name
  final String? name;
  
  /// Current price
  final double price;
  
  /// Price change (absolute)
  final double change;
  
  /// Price change percentage
  @JsonKey(name: 'change_pct')
  final double changePct;
  
  /// Opening price
  final double? open;
  
  /// Highest price today
  final double? high;
  
  /// Lowest price today
  final double? low;
  
  /// 52-week high
  @JsonKey(name: 'high_52w')
  final double? high52w;
  
  /// 52-week low
  @JsonKey(name: 'low_52w')
  final double? low52w;
  
  /// Price-to-Earnings ratio
  final double? pe;
  
  /// Dividend yield (%)
  @JsonKey(name: 'dividend_yield')
  final double? dividendYield;
  
  /// Trading volume
  final int? volume;
  
  /// Market capitalization
  @JsonKey(name: 'market_cap')
  final String? marketCap;
  
  /// Sector
  final String? sector;

  StockQuote({
    required this.ticker,
    required this.symbol,
    this.name,
    required this.price,
    required this.change,
    required this.changePct,
    this.open,
    this.high,
    this.low,
    this.high52w,
    this.low52w,
    this.pe,
    this.dividendYield,
    this.volume,
    this.marketCap,
    this.sector,
  });

  factory StockQuote.fromJson(Map<String, dynamic> json) => _$StockQuoteFromJson(json);
  Map<String, dynamic> toJson() => _$StockQuoteToJson(this);
  
  /// Check if price is up
  bool get isUp => changePct > 0;
  
  /// Get color based on price direction (red = up, green = down in Chinese convention)
  String get priceDirection => isUp ? 'up' : 'down';
}
