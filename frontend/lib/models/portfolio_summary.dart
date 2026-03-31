import 'package:json_annotation/json_annotation.dart';

part 'portfolio_summary.g.dart';

@JsonSerializable()
class PortfolioSummary {
  final double totalValue;
  final double totalCost;
  final double totalPL;
  final double totalPLPct;
  final int totalHoldings;
  final int totalTrades;
  final double winRate;
  final double avgWin;
  final double avgLoss;

  PortfolioSummary({
    required this.totalValue,
    required this.totalCost,
    required this.totalPL,
    required this.totalPLPct,
    required this.totalHoldings,
    required this.totalTrades,
    required this.winRate,
    required this.avgWin,
    required this.avgLoss,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) =>
      _$PortfolioSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$PortfolioSummaryToJson(this);
}
