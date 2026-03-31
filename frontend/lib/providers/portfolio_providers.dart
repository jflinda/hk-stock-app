import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hk_stock_app/models/index.dart';
import 'package:hk_stock_app/services/api_service.dart';

/// Provider for portfolio summary
final portfolioSummaryProvider = FutureProvider<PortfolioSummary>((ref) async {
  return apiService.getPortfolioSummary();
});

/// Provider for current positions
final positionsProvider = FutureProvider<List<Position>>((ref) async {
  return apiService.getPositions();
});

/// Computed provider for positions sorted by value
final sortedPositionsProvider = FutureProvider<List<Position>>((ref) async {
  final positions = await ref.watch(positionsProvider.future);
  final sorted = List<Position>.from(positions);
  sorted.sort((a, b) => b.currentValue.compareTo(a.currentValue));
  return sorted;
});

/// State provider for portfolio tab selection
final portfolioTabProvider = StateProvider<int>((ref) => 0);

/// Family provider for individual position details
final positionDetailsProvider =
    FutureProvider.family<Position, String>((ref, ticker) async {
  final positions = await ref.watch(positionsProvider.future);
  return positions.firstWhere(
    (p) => p.ticker == ticker,
    orElse: () => throw Exception('Position not found'),
  );
});

/// State provider for new trade form data
final newTradeFormProvider = StateNotifierProvider<NewTradeFormNotifier, NewTradeFormState>((ref) {
  return NewTradeFormNotifier();
});

class NewTradeFormState {
  final String ticker;
  final String type; // 'BUY' or 'SELL'
  final int quantity;
  final double price;
  final double commission;
  final DateTime tradeDate;
  final String? notes;

  NewTradeFormState({
    this.ticker = '',
    this.type = 'BUY',
    this.quantity = 0,
    this.price = 0.0,
    this.commission = 0.0,
    DateTime? date,
    this.notes,
  }) : tradeDate = date ?? DateTime.now();

  NewTradeFormState copyWith({
    String? ticker,
    String? type,
    int? quantity,
    double? price,
    double? commission,
    DateTime? tradeDate,
    String? notes,
  }) {
    return NewTradeFormState(
      ticker: ticker ?? this.ticker,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      commission: commission ?? this.commission,
      notes: notes ?? this.notes,
    );
  }
}

class NewTradeFormNotifier extends StateNotifier<NewTradeFormState> {
  NewTradeFormNotifier() : super(NewTradeFormState());

  void setTicker(String ticker) {
    state = state.copyWith(ticker: ticker);
  }

  void setType(String type) {
    state = state.copyWith(type: type);
  }

  void setQuantity(int quantity) {
    state = state.copyWith(quantity: quantity);
  }

  void setPrice(double price) {
    state = state.copyWith(price: price);
  }

  void setCommission(double commission) {
    state = state.copyWith(commission: commission);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void reset() {
    state = NewTradeFormState();
  }
}
