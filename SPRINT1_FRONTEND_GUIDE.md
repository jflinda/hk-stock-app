# Sprint 1 前端开发指南

**目标：** 搭建 Flutter 底部导航 + Market 页面（指数行情）

**时间线：** 2 天（第 2 天和第 3 天）

---

## 第 2 天：搭建前端框架和 Market 页面

### 任务分解

#### 2.1 搭建底部导航栏（BottomNavigationBar）

**目标：** 5 个 Tab 的导航框架

**步骤：**

1. 创建主应用文件 `lib/main.dart`：
   ```dart
   void main() {
     runApp(const MyApp());
   }

   class MyApp extends StatelessWidget {
     const MyApp({Key? key}) : super(key: key);

     @override
     Widget build(BuildContext context) {
       return MaterialApp(
         title: 'HK Stock App',
         theme: ThemeData(
           primarySwatch: Colors.blue,
           useMaterial3: true,
         ),
         home: const MainScreen(),
       );
     }
   }
   ```

2. 创建主屏幕 `lib/screens/main_screen.dart`（使用 Riverpod）：
   ```dart
   import 'package:flutter_riverpod/flutter_riverpod.dart';

   final currentTabProvider = StateProvider<int>((ref) => 0);

   class MainScreen extends ConsumerWidget {
     const MainScreen({Key? key}) : super(key: key);

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final currentTab = ref.watch(currentTabProvider);
       
       return Scaffold(
         body: IndexedStack(
           index: currentTab,
           children: const [
             PortfolioScreen(),
             MarketScreen(),
             WatchlistScreen(),
             ToolsScreen(),
             SettingsScreen(),
           ],
         ),
         bottomNavigationBar: BottomNavigationBar(
           currentIndex: currentTab,
           onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
           items: const [
             BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Portfolio'),
             BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Market'),
             BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Watchlist'),
             BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Tools'),
             BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
           ],
         ),
       );
     }
   }
   ```

3. 创建 5 个空的屏幕文件（占位符）：
   - `lib/screens/portfolio_screen.dart`
   - `lib/screens/market_screen.dart`
   - `lib/screens/watchlist_screen.dart`
   - `lib/screens/tools_screen.dart`
   - `lib/screens/settings_screen.dart`

#### 2.2 创建 API 客户端

**文件：** `lib/services/api_client.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiClient {
  static const String baseUrl = 'http://localhost:8000/api';

  // 获取指数
  static Future<List<Map<String, dynamic>>> getIndices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/market/indices'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      throw Exception('Failed to load indices');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // 获取涨跌幅排名
  static Future<Map<String, dynamic>> getMovers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/market/movers'));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      throw Exception('Failed to load movers');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // 获取股票报价
  static Future<Map<String, dynamic>> getQuote(String ticker) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stock/$ticker/quote'));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      throw Exception('Failed to load quote');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // 获取 K 线数据
  static Future<List<Map<String, dynamic>>> getHistory(String ticker, String period) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/stock/$ticker/history?period=$period'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      throw Exception('Failed to load history');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // 搜索股票
  static Future<List<Map<String, dynamic>>> searchStocks(String q) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/stock/search?q=$q'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      throw Exception('Failed to search');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
```

#### 2.3 创建 Riverpod 提供者

**文件：** `lib/providers/market_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

final indicesProvider = FutureProvider((ref) {
  return ApiClient.getIndices();
});

final moversProvider = FutureProvider((ref) {
  return ApiClient.getMovers();
});

final stockQuoteProvider = FutureProvider.family((ref, String ticker) {
  return ApiClient.getQuote(ticker);
});

final stockHistoryProvider = FutureProvider.family((ref, (String ticker, String period)) {
  return ApiClient.getHistory(ref.watch(stockProvider).ticker, ref.watch(stockProvider).period);
});
```

#### 2.4 实现 Market 页面

**文件：** `lib/screens/market_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_provider.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicesAsync = ref.watch(indicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        elevation: 0,
      ),
      body: indicesAsync.when(
        data: (indices) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 指数行情条
            const SizedBox(height: 10),
            const Text('Indices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...indices.map((index) => IndexCard(data: index)).toList(),
            const SizedBox(height: 20),
            // 后续可以添加其他部分（板块热力图、涨跌幅排名等）
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class IndexCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const IndexCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final changePct = (data['change_pct'] as num).toDouble();
    final isUp = changePct >= 0;
    final color = isUp ? Colors.red : Colors.green; // 港股惯例

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'N/A',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  data['symbol'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${data['price']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${isUp ? '+' : ''}$changePct%',
                  style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 2.5 更新 pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  flutter_riverpod: ^2.4.0
  riverpod: ^2.4.0
```

**运行命令：**
```bash
flutter pub get
```

---

## 第 3 天：优化和完善

### 任务分解

#### 3.1 完善 Market 页面

- 添加涨跌幅排名（Movers 部分）
- 添加搜索功能
- 实现下拉刷新
- 优化 UI/UX

#### 3.2 测试和调试

- 测试 API 连接
- 测试数据显示
- 处理错误情况
- 测试热重载

#### 3.3 性能优化

- 实现缓存机制
- 优化列表渲染
- 添加加载状态指示

---

## 开发启动指南

### 第 2 天开始前的准备

1. **启动后端 API：**
   ```powershell
   cd "c:\Users\jflin\WorkBuddy\20260329125422\stocktrading\backend"
   & "C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" -m uvicorn main:app --reload --port 8000
   ```

2. **进入 Flutter 项目目录：**
   ```powershell
   cd "c:\Users\jflin\WorkBuddy\20260329125422\stocktrading\frontend\hk_stock_app"
   ```

3. **运行 Flutter 应用（Chrome）：**
   ```powershell
   flutter run -d chrome
   ```

4. **或者在 Android Studio 中运行：**
   - 打开项目 `c:\Users\jflin\WorkBuddy\20260329125422\stocktrading\frontend\hk_stock_app`
   - 点击菜单 **Run** → **Run 'main.dart'**
   - 选择 Chrome 作为目标设备

### 文件结构

```
hk_stock_app/
├── lib/
│   ├── main.dart                 (主应用入口)
│   ├── screens/
│   │   ├── main_screen.dart      (主屏幕 + 底部导航)
│   │   ├── portfolio_screen.dart
│   │   ├── market_screen.dart
│   │   ├── watchlist_screen.dart
│   │   ├── tools_screen.dart
│   │   └── settings_screen.dart
│   ├── services/
│   │   └── api_client.dart       (API 客户端)
│   └── providers/
│       └── market_provider.dart  (Riverpod 提供者)
├── pubspec.yaml                  (依赖管理)
└── test/                          (单元测试)
```

---

## 常见问题

### Q: 后端 API 返回 CORS 错误？
A: 确保后端的 CORSMiddleware 已配置。检查 `main.py` 中的 CORS 设置。

### Q: 如何调试 API 请求？
A: 使用 http 包的日志功能或在浏览器开发者工具中查看网络请求。

### Q: 如何优化性能？
A: 使用 Riverpod 的缓存和 FutureProvider，实现数据缓存策略。

---

## 下一步里程碑

- ✅ Sprint 1 第 1 天：后端数据服务
- 🎯 Sprint 1 第 2 天：前端框架 + Market 页面
- 🎯 Sprint 1 第 3 天：优化和完善
- 📋 Sprint 2：其他页面（Portfolio、Watchlist、Tools）
- 📋 Sprint 3：Database 集成和本地存储
