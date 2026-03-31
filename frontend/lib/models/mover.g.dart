// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mover.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mover _$MoverFromJson(Map<String, dynamic> json) => Mover(
  ticker: json['ticker'] as String,
  price: (json['price'] as num).toDouble(),
  pct: (json['pct'] as num).toDouble(),
  volume: (json['volume'] as num).toInt(),
  name: json['name'] as String?,
  sector: json['sector'] as String?,
);

Map<String, dynamic> _$MoverToJson(Mover instance) => <String, dynamic>{
  'ticker': instance.ticker,
  'price': instance.price,
  'pct': instance.pct,
  'volume': instance.volume,
  'name': instance.name,
  'sector': instance.sector,
};

Movers _$MoversFromJson(Map<String, dynamic> json) => Movers(
  gainers: (json['gainers'] as List<dynamic>)
      .map((e) => Mover.fromJson(e as Map<String, dynamic>))
      .toList(),
  losers: (json['losers'] as List<dynamic>)
      .map((e) => Mover.fromJson(e as Map<String, dynamic>))
      .toList(),
  turnover: (json['turnover'] as List<dynamic>)
      .map((e) => Mover.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MoversToJson(Movers instance) => <String, dynamic>{
  'gainers': instance.gainers,
  'losers': instance.losers,
  'turnover': instance.turnover,
};
