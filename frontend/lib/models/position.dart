import 'package:json_annotation/json_annotation.dart';

part 'position.g.dart';

@JsonSerializable()
class Position {
  final String ticker;
  final String name;
  final int quantity;
  final double avgCost;
  final double currentPrice;
  final double costValue;
  final double currentValue;
  final double pl;
  final double plPct;

  Position({
    required this.ticker,
    required this.name,
    required this.quantity,
    required this.avgCost,
    required this.currentPrice,
    required this.costValue,
    required this.currentValue,
    required this.pl,
    required this.plPct,
  });

  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);

  Map<String, dynamic> toJson() => _$PositionToJson(this);
}
