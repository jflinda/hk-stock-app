// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kline_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KlineData _$KlineDataFromJson(Map<String, dynamic> json) => KlineData(
  date: json['date'] as String,
  open: (json['open'] as num).toDouble(),
  high: (json['high'] as num).toDouble(),
  low: (json['low'] as num).toDouble(),
  close: (json['close'] as num).toDouble(),
  volume: (json['volume'] as num).toInt(),
  ma5: (json['ma5'] as num?)?.toDouble(),
  ma20: (json['ma20'] as num?)?.toDouble(),
);

Map<String, dynamic> _$KlineDataToJson(KlineData instance) => <String, dynamic>{
  'date': instance.date,
  'open': instance.open,
  'high': instance.high,
  'low': instance.low,
  'close': instance.close,
  'volume': instance.volume,
  'ma5': instance.ma5,
  'ma20': instance.ma20,
};
