import 'package:json_annotation/json_annotation.dart';

part 'watchlist_item.g.dart';

@JsonSerializable()
class WatchlistItem {
  final String ticker;
  final String name;
  final double price;
  final double change;
  final double changePct;
  final double? alertPrice;
  final String? alertType; // 'above' or 'below'

  WatchlistItem({
    required this.ticker,
    required this.name,
    required this.price,
    required this.change,
    required this.changePct,
    this.alertPrice,
    this.alertType,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) =>
      _$WatchlistItemFromJson(json);

  Map<String, dynamic> toJson() => _$WatchlistItemToJson(this);
}
