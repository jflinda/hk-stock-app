// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_quote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockQuote _$StockQuoteFromJson(Map<String, dynamic> json) => StockQuote(
      ticker: json['ticker'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String?,
      longName: json['long_name'] as String?,
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePct: (json['change_pct'] as num).toDouble(),
      open: (json['open'] as num?)?.toDouble(),
      high: (json['high'] as num?)?.toDouble(),
      low: (json['low'] as num?)?.toDouble(),
      dayHigh: (json['day_high'] as num?)?.toDouble(),
      dayLow: (json['day_low'] as num?)?.toDouble(),
      high52w: (json['high_52w'] as num?)?.toDouble(),
      low52w: (json['low_52w'] as num?)?.toDouble(),
      pe: (json['pe'] as num?)?.toDouble(),
      dividendYield: (json['dividend_yield'] as num?)?.toDouble(),
      volume: (json['volume'] as num?)?.toInt(),
      marketCap: json['market_cap'] as String?,
      sector: json['sector'] as String?,
      industry: json['industry'] as String?,
      country: json['country'] as String?,
      currency: json['currency'] as String?,
    );

Map<String, dynamic> _$StockQuoteToJson(StockQuote instance) =>
    <String, dynamic>{
      'ticker': instance.ticker,
      'symbol': instance.symbol,
      'name': instance.name,
      'long_name': instance.longName,
      'price': instance.price,
      'change': instance.change,
      'change_pct': instance.changePct,
      'open': instance.open,
      'high': instance.high,
      'low': instance.low,
      'day_high': instance.dayHigh,
      'day_low': instance.dayLow,
      'high_52w': instance.high52w,
      'low_52w': instance.low52w,
      'pe': instance.pe,
      'dividend_yield': instance.dividendYield,
      'volume': instance.volume,
      'market_cap': instance.marketCap,
      'sector': instance.sector,
      'industry': instance.industry,
      'country': instance.country,
      'currency': instance.currency,
    };
