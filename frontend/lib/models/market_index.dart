import 'package:json_annotation/json_annotation.dart';

part 'market_index.g.dart';

/// Market Index Model - represents indices like HSI, HSCEI, etc.
@JsonSerializable()
class MarketIndex {
  /// Index name (e.g., "HSI", "HSCEI")
  final String name;
  
  /// Full index code (e.g., "^HSI")
  final String symbol;
  
  /// Current price
  final double price;
  
  /// Price change (absolute)
  final double change;
  
  /// Price change percentage
  @JsonKey(name: 'change_pct')
  final double changePct;
  
  /// Timestamp of last update (ISO 8601 format)
  final String? timestamp;

  MarketIndex({
    required this.name,
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePct,
    this.timestamp,
  });

  factory MarketIndex.fromJson(Map<String, dynamic> json) => _$MarketIndexFromJson(json);
  Map<String, dynamic> toJson() => _$MarketIndexToJson(this);
  
  /// Get display color - red for up, green for down (Chinese convention)
  bool get isUp => changePct > 0;
}
