// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watchlist_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchlistItem _$WatchlistItemFromJson(Map<String, dynamic> json) =>
    WatchlistItem(
      ticker: json['ticker'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePct: (json['changePct'] as num).toDouble(),
      alertPrice: (json['alertPrice'] as num?)?.toDouble(),
      alertType: json['alertType'] as String?,
    );

Map<String, dynamic> _$WatchlistItemToJson(WatchlistItem instance) =>
    <String, dynamic>{
      'ticker': instance.ticker,
      'name': instance.name,
      'price': instance.price,
      'change': instance.change,
      'changePct': instance.changePct,
      'alertPrice': instance.alertPrice,
      'alertType': instance.alertType,
    };
