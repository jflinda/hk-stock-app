// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PortfolioSummary _$PortfolioSummaryFromJson(Map<String, dynamic> json) =>
    PortfolioSummary(
      totalValue: (json['totalValue'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      totalPL: (json['totalPL'] as num).toDouble(),
      totalPLPct: (json['totalPLPct'] as num).toDouble(),
      totalHoldings: (json['totalHoldings'] as num).toInt(),
      totalTrades: (json['totalTrades'] as num).toInt(),
      winRate: (json['winRate'] as num).toDouble(),
      avgWin: (json['avgWin'] as num).toDouble(),
      avgLoss: (json['avgLoss'] as num).toDouble(),
    );

Map<String, dynamic> _$PortfolioSummaryToJson(PortfolioSummary instance) =>
    <String, dynamic>{
      'totalValue': instance.totalValue,
      'totalCost': instance.totalCost,
      'totalPL': instance.totalPL,
      'totalPLPct': instance.totalPLPct,
      'totalHoldings': instance.totalHoldings,
      'totalTrades': instance.totalTrades,
      'winRate': instance.winRate,
      'avgWin': instance.avgWin,
      'avgLoss': instance.avgLoss,
    };
