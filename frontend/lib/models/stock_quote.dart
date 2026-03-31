import 'package:json_annotation/json_annotation.dart';

part 'stock_quote.g.dart';

/// Stock Quote Model - detailed information about a single stock
@JsonSerializable()
class StockQuote {
  /// Stock ticker code (e.g., "0700")
  final String ticker;

  /// Stock symbol with market (e.g., "0700.HK")
  final String symbol;

  /// Short company name
  final String? name;

  /// Full company name
  @JsonKey(name: 'long_name')
  final String? longName;

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

  /// Day high (alias for high)
  @JsonKey(name: 'day_high')
  final double? dayHigh;

  /// Day low (alias for low)
  @JsonKey(name: 'day_low')
  final double? dayLow;

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

  /// Market capitalization (formatted string e.g. "1.85T")
  @JsonKey(name: 'market_cap')
  final String? marketCap;

  /// Sector (e.g. "Technology")
  final String? sector;

  /// Industry
  final String? industry;

  /// Country
  final String? country;

  /// Currency
  final String? currency;

  StockQuote({
    required this.ticker,
    required this.symbol,
    this.name,
    this.longName,
    required this.price,
    required this.change,
    required this.changePct,
    this.open,
    this.high,
    this.low,
    this.dayHigh,
    this.dayLow,
    this.high52w,
    this.low52w,
    this.pe,
    this.dividendYield,
    this.volume,
    this.marketCap,
    this.sector,
    this.industry,
    this.country,
    this.currency,
  });

  factory StockQuote.fromJson(Map<String, dynamic> json) =>
      _$StockQuoteFromJson(json);

  Map<String, dynamic> toJson() => _$StockQuoteToJson(this);

  /// Check if price is up
  bool get isUp => changePct > 0;
}
