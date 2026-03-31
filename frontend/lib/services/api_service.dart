import 'package:dio/dio.dart';
import 'package:hk_stock_app/models/index.dart';

/// API Service - handles all HTTP requests to backend
class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  
  late Dio _dio;
  bool _useMockData = false;  // Toggle to use mock data for testing
  
  ApiService({bool useMockData = false}) : _useMockData = useMockData {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add request/response logging in debug mode
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[Dio] $obj'),
    ));
  }
  
  /// Toggle mock data mode for testing UI without backend
  void setMockMode(bool useMock) {
    _useMockData = useMock;
  }
  
  /// Generate mock market indices data for testing
  List<MarketIndex> _getMockIndices() {
    return [
      MarketIndex(
        name: 'HSI',
        symbol: '^HSI',
        price: 17532.45,
        change: 145.23,
        changePct: 0.83,
      ),
      MarketIndex(
        name: 'HSCEI',
        symbol: '^HSCEI',
        price: 5834.67,
        change: -23.45,
        changePct: -0.40,
      ),
      MarketIndex(
        name: 'HSTI',
        symbol: '^HSTI',
        price: 8123.56,
        change: 234.12,
        changePct: 2.97,
      ),
      MarketIndex(
        name: 'S&P 500',
        symbol: '^GSPC',
        price: 5234.89,
        change: 56.78,
        changePct: 1.09,
      ),
      MarketIndex(
        name: 'SSE',
        symbol: '000001',
        price: 3245.67,
        change: -45.23,
        changePct: -1.38,
      ),
    ];
  }

  /// Get all market indices (HSI, HSCEI, HSTI, S&P 500, SSE)
  /// Returns list of [MarketIndex]
  Future<List<MarketIndex>> getMarketIndices() async {
    if (_useMockData) {
      // Return mock data
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockIndices();
    }
    
    try {
      final response = await _dio.get('/market/indices');
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((json) => MarketIndex.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load market indices');
    } catch (e) {
      print('Error fetching market indices: $e');
      rethrow;
    }
  }
  
  /// Generate mock movers data for testing
  Movers _getMockMovers() {
    final gainers = [
      Mover(ticker: '0700', price: 245.80, pct: 5.34, volume: 15234000, name: 'Tencent'),
      Mover(ticker: '9988', price: 123.45, pct: 4.12, volume: 12345000, name: 'Alibaba'),
      Mover(ticker: '3690', price: 456.78, pct: 3.89, volume: 8234000, name: 'Meituan'),
      Mover(ticker: '2020', price: 12.34, pct: 3.45, volume: 45234000, name: 'Anta'),
      Mover(ticker: '1810', price: 89.23, pct: 2.78, volume: 5234000, name: 'Xiaomi'),
    ];
    
    final losers = [
      Mover(ticker: '0001', price: 78.45, pct: -4.23, volume: 8234000, name: 'CKH'),
      Mover(ticker: '0005', price: 234.56, pct: -3.45, volume: 5234000, name: 'HSBC'),
      Mover(ticker: '2382', price: 45.67, pct: -2.89, volume: 12345000, name: 'Ping An'),
      Mover(ticker: '0011', price: 123.45, pct: -2.34, volume: 3234000, name: 'HSI'),
      Mover(ticker: '1928', price: 23.45, pct: -1.78, volume: 6234000, name: 'Shenghuo'),
    ];
    
    final turnover = [
      Mover(ticker: '0700', price: 245.80, pct: 5.34, volume: 45234000, name: 'Tencent'),
      Mover(ticker: '9988', price: 123.45, pct: 4.12, volume: 42345000, name: 'Alibaba'),
      Mover(ticker: '0001', price: 78.45, pct: -4.23, volume: 38234000, name: 'CKH'),
      Mover(ticker: '2020', price: 12.34, pct: 3.45, volume: 35234000, name: 'Anta'),
      Mover(ticker: '0005', price: 234.56, pct: -3.45, volume: 32345000, name: 'HSBC'),
    ];
    
    return Movers(gainers: gainers, losers: losers, turnover: turnover);
  }
  
  /// Get movers (gainers, losers, turnover)
  /// Returns [Movers]
  Future<Movers> getMovers() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockMovers();
    }
    
    try {
      final response = await _dio.get('/market/movers');
      if (response.statusCode == 200) {
        return Movers.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to load movers');
    } catch (e) {
      print('Error fetching movers: $e');
      rethrow;
    }
  }
  
  /// Get stock quote by ticker code
  /// [ticker] - stock code (e.g., "0700", "9988")
  /// Returns [StockQuote]
  Future<StockQuote> getStockQuote(String ticker) async {
    try {
      final response = await _dio.get('/stock/$ticker/quote');
      if (response.statusCode == 200) {
        return StockQuote.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to load stock quote for $ticker');
    } catch (e) {
      print('Error fetching stock quote for $ticker: $e');
      rethrow;
    }
  }
  
  /// Get historical K-line data for a stock
  /// [ticker] - stock code (e.g., "0700")
  /// [period] - time period: "1d", "5d", "1mo", "3mo", "1y"
  /// Returns list of [KlineData]
  Future<List<KlineData>> getStockHistory(String ticker, String period) async {
    try {
      final response = await _dio.get(
        '/stock/$ticker/history',
        queryParameters: {'period': period},
      );
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((json) => KlineData.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load history for $ticker');
    } catch (e) {
      print('Error fetching history for $ticker: $e');
      rethrow;
    }
  }
  
  /// Search stocks by ticker or name
  /// [query] - search query
  /// Returns list of matching stocks
  Future<List<Map<String, dynamic>>> searchStocks(String query) async {
    try {
      final response = await _dio.get(
        '/stock/search',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to search stocks');
    } catch (e) {
      print('Error searching stocks: $e');
      rethrow;
    }
  }
  
  /// Get watchlist items
  /// Returns list of [WatchlistItem]
  Future<List<WatchlistItem>> getWatchlist() async {
    try {
      final response = await _dio.get('/watchlist');
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((json) => WatchlistItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load watchlist');
    } catch (e) {
      print('Error fetching watchlist: $e');
      rethrow;
    }
  }
  
  /// Add stock to watchlist
  /// [ticker] - stock code
  /// [alertPrice] - optional alert price
  /// [alertType] - 'above' or 'below'
  Future<WatchlistItem> addToWatchlist(
    String ticker, {
    double? alertPrice,
    String? alertType,
  }) async {
    try {
      final response = await _dio.post(
        '/watchlist',
        data: {
          'ticker': ticker,
          'alert_price': alertPrice,
          'alert_type': alertType,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return WatchlistItem.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to add to watchlist');
    } catch (e) {
      print('Error adding to watchlist: $e');
      rethrow;
    }
  }
  
  /// Remove stock from watchlist
  /// [ticker] - stock code
  Future<void> removeFromWatchlist(String ticker) async {
    try {
      final response = await _dio.delete('/watchlist/$ticker');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove from watchlist');
      }
    } catch (e) {
      print('Error removing from watchlist: $e');
      rethrow;
    }
  }
  
  /// Get portfolio summary
  /// Returns [PortfolioSummary]
  Future<PortfolioSummary> getPortfolioSummary() async {
    try {
      final response = await _dio.get('/portfolio/summary');
      if (response.statusCode == 200) {
        return PortfolioSummary.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to load portfolio summary');
    } catch (e) {
      print('Error fetching portfolio summary: $e');
      rethrow;
    }
  }
  
  /// Get current positions
  /// Returns list of [Position]
  Future<List<Position>> getPositions() async {
    try {
      final response = await _dio.get('/portfolio/positions');
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((json) => Position.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load positions');
    } catch (e) {
      print('Error fetching positions: $e');
      rethrow;
    }
  }
  
  /// Get trade history
  /// [limit] - max number of trades to return (default 100)
  /// [offset] - pagination offset (default 0)
  /// Returns list of [Trade]
  Future<List<Trade>> getTrades({int limit = 100, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/trades',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((json) => Trade.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load trades');
    } catch (e) {
      print('Error fetching trades: $e');
      rethrow;
    }
  }
  
  /// Add a new trade (BUY or SELL)
  /// [ticker] - stock code
  /// [type] - 'BUY' or 'SELL'
  /// [quantity] - number of shares
  /// [price] - price per share
  /// [commission] - trading commission
  /// [tradeDate] - date of trade
  /// [notes] - optional notes
  /// Returns created [Trade]
  Future<Trade> addTrade({
    required String ticker,
    required String type,
    required int quantity,
    required double price,
    required double commission,
    required DateTime tradeDate,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/trades',
        data: {
          'ticker': ticker,
          'type': type,
          'quantity': quantity,
          'price': price,
          'commission': commission,
          'trade_date': tradeDate.toIso8601String(),
          'notes': notes,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Trade.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to add trade');
    } catch (e) {
      print('Error adding trade: $e');
      rethrow;
    }
  }
  
  /// Delete a trade
  /// [tradeId] - ID of trade to delete
  Future<void> deleteTrade(String tradeId) async {
    try {
      final response = await _dio.delete('/trades/$tradeId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete trade');
      }
    } catch (e) {
      print('Error deleting trade: $e');
      rethrow;
    }
  }

  /// Set custom base URL (useful for switching between localhost and production)
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }
}

/// Singleton instance of API service
final apiService = ApiService();
