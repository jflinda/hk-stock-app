import 'package:json_annotation/json_annotation.dart';

part 'trade.g.dart';

@JsonSerializable()
class Trade {
  final String id;
  final String ticker;
  final String name;
  final String type; // 'BUY' or 'SELL'
  final int quantity;
  final double price;
  final double commission;
  final DateTime tradeDate;
  final double pl; // 仅对 SELL 订单有效
  final double plPct; // 仅对 SELL 订单有效
  final String? notes;

  Trade({
    required this.id,
    required this.ticker,
    required this.name,
    required this.type,
    required this.quantity,
    required this.price,
    required this.commission,
    required this.tradeDate,
    required this.pl,
    required this.plPct,
    this.notes,
  });

  factory Trade.fromJson(Map<String, dynamic> json) =>
      _$TradeFromJson(json);

  Map<String, dynamic> toJson() => _$TradeToJson(this);
}
