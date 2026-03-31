import 'package:json_annotation/json_annotation.dart';

part 'mover.g.dart';

/// Mover Model - represents a stock in gainers/losers/turnover rankings
@JsonSerializable()
class Mover {
  /// Stock ticker code (without .HK)
  final String ticker;
  
  /// Current price
  final double price;
  
  /// Price change percentage
  final double pct;
  
  /// Trading volume
  final int volume;
  
  /// Optional: company name
  final String? name;
  
  /// Optional: sector
  final String? sector;

  Mover({
    required this.ticker,
    required this.price,
    required this.pct,
    required this.volume,
    this.name,
    this.sector,
  });

  factory Mover.fromJson(Map<String, dynamic> json) => _$MoverFromJson(json);
  Map<String, dynamic> toJson() => _$MoverToJson(this);
  
  /// Check if price is up
  bool get isUp => pct > 0;
  
  /// Format percentage for display
  String get displayPct => '${isUp ? '+' : ''}${pct.toStringAsFixed(2)}%';
  
  /// Format price for display (HKD)
  String get displayPrice => '\$${price.toStringAsFixed(2)}';
  
  /// Format volume for display (K = thousands, M = millions)
  String get displayVolume {
    if (volume > 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume > 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    } else {
      return volume.toString();
    }
  }
}

/// Container for movers data (gainers, losers, turnover)
@JsonSerializable()
class Movers {
  /// Top 5 gainers
  final List<Mover> gainers;
  
  /// Top 5 losers
  final List<Mover> losers;
  
  /// Top 5 by turnover (trading volume)
  final List<Mover> turnover;

  Movers({
    required this.gainers,
    required this.losers,
    required this.turnover,
  });

  factory Movers.fromJson(Map<String, dynamic> json) => _$MoversFromJson(json);
  Map<String, dynamic> toJson() => _$MoversToJson(this);
}
