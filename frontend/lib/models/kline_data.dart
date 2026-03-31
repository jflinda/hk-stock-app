import 'package:json_annotation/json_annotation.dart';

part 'kline_data.g.dart';

/// K-line candle data - OHLCV (Open, High, Low, Close, Volume) with moving averages
@JsonSerializable()
class KlineData {
  /// Date of the candle (YYYY-MM-DD format)
  final String date;
  
  /// Opening price
  final double open;
  
  /// Highest price
  final double high;
  
  /// Lowest price
  final double low;
  
  /// Closing price
  final double close;
  
  /// Trading volume
  final int volume;
  
  /// 5-day moving average
  final double? ma5;
  
  /// 20-day moving average
  final double? ma20;

  KlineData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    this.ma5,
    this.ma20,
  });

  factory KlineData.fromJson(Map<String, dynamic> json) => _$KlineDataFromJson(json);
  Map<String, dynamic> toJson() => _$KlineDataToJson(this);
  
  /// Check if candle is up (close > open)
  bool get isUp => close >= open;
  
  /// Get candle body height (absolute difference)
  double get bodyHeight => (close - open).abs();
  
  /// Get candle range (high - low)
  double get range => high - low;
}
