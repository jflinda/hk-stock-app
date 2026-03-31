# HK Stock App — API 端点文档

**基础 URL：** `http://localhost:8000`

**交互式 API 文档：** http://localhost:8000/docs（Swagger UI）

---

## 市场数据接口（Market）

### 1. 获取主要指数

**端点：** `GET /api/market/indices`

**描述：** 获取港股及全球主要指数的实时行情

**请求示例：**
```
GET http://localhost:8000/api/market/indices
```

**响应示例：**
```json
[
  {
    "name": "HSI",
    "symbol": "^HSI",
    "price": 24788.14,
    "change": 37.35,
    "change_pct": 0.15,
    "timestamp": "2026-03-31 00:00:00+08:00"
  },
  {
    "name": "HSCEI",
    "symbol": "^HSCE",
    "price": 8374.3,
    "change": -24.82,
    "change_pct": -0.3,
    "timestamp": "2026-03-31 00:00:00+08:00"
  },
  {
    "name": "HSTI",
    "symbol": "^HSTI",
    "price": 0,
    "change": 0,
    "change_pct": 0,
    "timestamp": null,
    "error": "No data available"
  },
  {
    "name": "SP500",
    "symbol": "^GSPC",
    "price": 6343.72,
    "change": -25.13,
    "change_pct": -0.39,
    "timestamp": "2026-03-30 00:00:00-04:00"
  },
  {
    "name": "SSE",
    "symbol": "000001.SS",
    "price": 3891.86,
    "change": -31.43,
    "change_pct": -0.8,
    "timestamp": "2026-03-31 00:00:00+08:00"
  }
]
```

**返回字段：**
- `name`: 指数名称（HSI/HSCEI/HSTI/SP500/SSE）
- `symbol`: Yahoo Finance 股票代码
- `price`: 当前价格
- `change`: 变化绝对值
- `change_pct`: 变化百分比（%）
- `timestamp`: 最后更新时间
- `error`: 如果有错误，返回错误信息

**缓存：** 5 分钟

---

### 2. 获取涨跌幅排名

**端点：** `GET /api/market/movers`

**描述：** 获取港股市场的涨幅榜、跌幅榜、成交额榜（各 5 支）

**请求示例：**
```
GET http://localhost:8000/api/market/movers
```

**响应示例：**
```json
{
  "gainers": [
    {
      "ticker": "0939",
      "symbol": "0939.HK",
      "price": 8.39,
      "change_pct": 1.82,
      "volume": 356132108
    }
  ],
  "losers": [
    {
      "ticker": "0857",
      "symbol": "0857.HK",
      "price": 10.75,
      "change_pct": -3.5,
      "volume": 231914570
    }
  ],
  "turnover": [
    {
      "ticker": "0939",
      "symbol": "0939.HK",
      "price": 8.39,
      "change_pct": 1.82,
      "volume": 356132108
    }
  ]
}
```

**返回字段：**
- `gainers`: 涨幅前 5 的股票
- `losers`: 跌幅前 5 的股票
- `turnover`: 成交量前 5 的股票
- 每支股票包含：`ticker`, `symbol`, `price`, `change_pct`, `volume`

**缓存：** 5 分钟

---

## 个股数据接口（Stocks）

### 3. 获取股票报价

**端点：** `GET /api/stock/{ticker}/quote`

**描述：** 获取单个港股的详细报价和信息

**参数：**
- `ticker` (path): 股票代码，可以是 4 位数字（如 0700）或完整代码（如 0700.HK）

**请求示例：**
```
GET http://localhost:8000/api/stock/0700/quote
```

**响应示例：**
```json
{
  "ticker": "0700",
  "symbol": "0700.HK",
  "name": "Tencent Holdings Limited",
  "price": 484.0,
  "change": 2.4,
  "change_pct": 0.5,
  "open": 484.4,
  "high": 492.0,
  "low": 480.0,
  "volume": 25801497,
  "high_52w": 521.5,
  "low_52w": 476.0,
  "pe": 17.7,
  "dividend_yield": 110.0,
  "market_cap": 4374086287360
}
```

**返回字段：**
- `ticker`: 用户输入的股票代码
- `symbol`: 标准化的 Yahoo Finance 代码
- `name`: 公司名称
- `price`: 当前价格
- `change`: 变化绝对值
- `change_pct`: 变化百分比
- `open`: 开盘价
- `high`: 今日最高价
- `low`: 今日最低价
- `volume`: 成交量
- `high_52w`: 52 周最高价
- `low_52w`: 52 周最低价
- `pe`: 市盈率
- `dividend_yield`: 股息率（%）
- `market_cap`: 市值

**缓存：** 5 分钟

**错误处理：** 如果股票不存在，返回 404 错误

---

### 4. 获取历史 K 线数据

**端点：** `GET /api/stock/{ticker}/history`

**描述：** 获取港股的历史 OHLCV 数据和移动平均线

**参数：**
- `ticker` (path): 股票代码（如 0700）
- `period` (query, 可选): 时间周期，默认 1mo
  - `1d`: 最近 5 天（日线）
  - `5d`: 最近 1 个月（日线）
  - `1m` 或 `1mo`: 最近 3 个月（日线）
  - `3m` 或 `3mo`: 最近 1 年（日线）
  - `1y`: 最近 1 年（日线）

**请求示例：**
```
GET http://localhost:8000/api/stock/0700/history?period=1mo
```

**响应示例：**
```json
[
  {
    "date": "2026-03-25",
    "timestamp": 1774368000000,
    "open": 519.0,
    "high": 521.5,
    "low": 502.0,
    "close": 505.5,
    "volume": 37353909,
    "ma5": 507.78,
    "ma20": 524.74
  },
  {
    "date": "2026-03-26",
    "timestamp": 1774454400000,
    "open": 501.0,
    "high": 507.5,
    "low": 495.0,
    "close": 495.6,
    "volume": 22623215,
    "ma5": 504.3,
    "ma20": 523.92
  }
]
```

**返回字段（数组）：**
- `date`: 日期（YYYY-MM-DD）
- `timestamp`: Unix 时间戳（毫秒）
- `open`: 开盘价
- `high`: 最高价
- `low`: 最低价
- `close`: 收盘价
- `volume`: 成交量
- `ma5`: 5 日移动平均（如果可用，否则为 null）
- `ma20`: 20 日移动平均（如果可用，否则为 null）

**缓存：** 5 分钟

**错误处理：** 如果股票或历史数据不存在，返回 404 错误

---

### 5. 搜索股票

**端点：** `GET /api/stock/search`

**描述：** 按股票代码或公司名称搜索港股

**参数：**
- `q` (query, 必需): 搜索关键词，最少 1 个字符

**请求示例：**
```
GET http://localhost:8000/api/stock/search?q=tencent
GET http://localhost:8000/api/stock/search?q=0700
```

**响应示例：**
```json
[
  {
    "ticker": "0700",
    "name": "Tencent",
    "sector": "Consumer"
  },
  {
    "ticker": "9988",
    "name": "Alibaba",
    "sector": "Consumer"
  }
]
```

**返回字段（数组）：**
- `ticker`: 股票代码
- `name`: 公司名称
- `sector`: 行业分类

**缓存：** 无（内存中的静态列表）

---

## 使用示例（前端集成）

### Flutter/Dart 中使用

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class StockApiClient {
  static const String baseUrl = 'http://localhost:8000/api';

  // 获取指数
  static Future<List<dynamic>> getIndices() async {
    final response = await http.get(Uri.parse('$baseUrl/market/indices'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load indices');
  }

  // 获取股票报价
  static Future<Map<String, dynamic>> getQuote(String ticker) async {
    final response = await http.get(Uri.parse('$baseUrl/stock/$ticker/quote'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load quote for $ticker');
  }

  // 获取 K 线数据
  static Future<List<dynamic>> getHistory(String ticker, String period) async {
    final response = await http
        .get(Uri.parse('$baseUrl/stock/$ticker/history?period=$period'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load history for $ticker');
  }

  // 获取涨跌幅排名
  static Future<Map<String, dynamic>> getMovers() async {
    final response = await http.get(Uri.parse('$baseUrl/market/movers'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load movers');
  }

  // 搜索股票
  static Future<List<dynamic>> search(String q) async {
    final response = await http
        .get(Uri.parse('$baseUrl/stock/search?q=$q'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to search');
  }
}
```

---

## 缓存策略

- **TTL（生存时间）：** 5 分钟
- **缓存键：** 基于端点 URL 生成
- **缓存失效：** 自动在 5 分钟后过期，下次请求时重新获取数据

### 手动清除缓存

由于缓存存储在内存中，重启服务器会自动清除所有缓存。

---

## 错误处理

所有端点在发生错误时返回 HTTP 错误状态码：

- `404 Not Found`: 股票不存在或无数据
- `500 Internal Server Error`: 服务器内部错误（通常是 yfinance 数据获取失败）

**错误响应示例：**
```json
{
  "detail": "Stock 9999 not found: No data found for this date range (9999.HK)"
}
```

---

## 性能优化建议

1. **启用 CORS 缓存：** 前端可以设置响应缓存头
2. **批量请求合并：** 避免多次请求相同数据
3. **定期刷新：** 实现 30 秒自动刷新机制
4. **离线支持：** 缓存最近数据用于离线访问

---

## 技术细节

- **数据源：** yfinance（Yahoo Finance 数据）
- **并发限制：** 无特殊限制，但 yfinance API 有速率限制
- **数据延迟：** 港股数据通常延迟 15-20 分钟
- **时区：** 香港时间（GMT+8）
