// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_index.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarketIndex _$MarketIndexFromJson(Map<String, dynamic> json) => MarketIndex(
  name: json['name'] as String,
  symbol: json['symbol'] as String,
  price: (json['price'] as num).toDouble(),
  change: (json['change'] as num).toDouble(),
  changePct: (json['change_pct'] as num).toDouble(),
  timestamp: json['timestamp'] as String?,
);

Map<String, dynamic> _$MarketIndexToJson(MarketIndex instance) =>
    <String, dynamic>{
      'name': instance.name,
      'symbol': instance.symbol,
      'price': instance.price,
      'change': instance.change,
      'change_pct': instance.changePct,
      'timestamp': instance.timestamp,
    };
