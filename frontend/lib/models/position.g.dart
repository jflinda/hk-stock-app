// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Position _$PositionFromJson(Map<String, dynamic> json) => Position(
      ticker: json['ticker'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      avgCost: (json['avgCost'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      costValue: (json['costValue'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      pl: (json['pl'] as num).toDouble(),
      plPct: (json['plPct'] as num).toDouble(),
    );

Map<String, dynamic> _$PositionToJson(Position instance) => <String, dynamic>{
      'ticker': instance.ticker,
      'name': instance.name,
      'quantity': instance.quantity,
      'avgCost': instance.avgCost,
      'currentPrice': instance.currentPrice,
      'costValue': instance.costValue,
      'currentValue': instance.currentValue,
      'pl': instance.pl,
      'plPct': instance.plPct,
    };
