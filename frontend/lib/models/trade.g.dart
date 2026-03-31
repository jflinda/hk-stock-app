// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trade _$TradeFromJson(Map<String, dynamic> json) => Trade(
      id: json['id'] as String,
      ticker: json['ticker'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      commission: (json['commission'] as num).toDouble(),
      tradeDate: DateTime.parse(json['tradeDate'] as String),
      pl: (json['pl'] as num).toDouble(),
      plPct: (json['plPct'] as num).toDouble(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$TradeToJson(Trade instance) => <String, dynamic>{
      'id': instance.id,
      'ticker': instance.ticker,
      'name': instance.name,
      'type': instance.type,
      'quantity': instance.quantity,
      'price': instance.price,
      'commission': instance.commission,
      'tradeDate': instance.tradeDate.toIso8601String(),
      'pl': instance.pl,
      'plPct': instance.plPct,
      'notes': instance.notes,
    };
