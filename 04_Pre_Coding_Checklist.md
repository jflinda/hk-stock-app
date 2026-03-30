# 港股投资分析 App — 开始编码前准备清单
**版本：** v1.0  
**日期：** 2026-03-30  
**状态：** 规划与设计阶段已完成（阶段 1），准备进入阶段 2（环境搭建）

---

## 概览

UI 原型（`portfolio_prototype.html`）已 100% 完成，所有页面均已验证可用。  
以下清单列出开始写正式代码前需要完成的所有准备工作，建议按顺序逐项完成。

---

## ✅ 已完成（阶段 1）

- [x] 用户需求文档 v1.1 定稿
- [x] 技术栈选型确定（Flutter + FastAPI + yfinance + SQLite）
- [x] 项目计划文档完成（20 周时间表）
- [x] UI 原型完成（HTML 单页，含全部 6 个页面）
  - Portfolio、Market（含 Sectors / Movers / IPO）、Watchlist、Tools、Settings、Stock Detail

---

## 📋 阶段 2 准备清单（开始编码前必须全部完成）

### A. 开发环境安装

| 序号 | 任务 | 说明 | 完成 |
|------|------|------|------|
| A1 | 安装 Flutter SDK（最新稳定版 3.x） | 官网：https://flutter.dev/docs/get-started/install | [ ] |
| A2 | 安装 Android Studio | 含 Android SDK、AVD Manager | [ ] |
| A3 | 创建 Android 虚拟机（AVD） | 推荐 Pixel 6，Android 13 | [ ] |
| A4 | 运行 `flutter doctor` | 确保全部绿勾，无报错 | [ ] |
| A5 | 安装 Python 3.11 或 3.12 | https://www.python.org/downloads/ | [ ] |
| A6 | 安装 VS Code + Python & Flutter 插件 | 建议同时安装 Dart 插件 | [ ] |
| A7 | 安装 Git | https://git-scm.com/ | [ ] |

---

### B. 账号注册清单

| 序号 | 服务 | 用途 | 链接 | 完成 |
|------|------|------|------|------|
| B1 | GitHub | 代码版本管理 | https://github.com | [ ] |
| B2 | Alpha Vantage | 备用股票数据 API（免费） | https://www.alphavantage.co/support/#api-key | [ ] |
| B3 | NewsAPI | 财经新闻（免费 100 次/天） | https://newsapi.org/register | [ ] |
| B4 | Render.com | 后端免费部署 | https://render.com | [ ] |
| B5 | Google Play Developer | App 上架（$25 一次性） | https://play.google.com/console | [ ] |
| B6 | 富途证券（可选） | Futu OpenAPI 实时数据 | https://openapi.futunn.com | [ ] |

> **注意：** Yahoo Finance（yfinance）无需注册，直接用 Python 库调用即可。

---

### C. 数据源验证

在写正式代码前，务必验证以下数据源可正常使用：

#### C1. yfinance 验证（必做）

```bash
pip install yfinance pandas
```

```python
import yfinance as yf

# 测试港股数据（腾讯）
ticker = yf.Ticker("0700.HK")
print(ticker.info)           # 基本面信息
print(ticker.history(period="5d"))  # 近5日K线

# 测试大盘指数
hsi = yf.Ticker("^HSI")
print(hsi.history(period="1mo"))
```

**验证要点：**
- [ ] 能获取 `0700.HK` 价格、成交量
- [ ] 能获取 `^HSI`（恒生指数）、`^HSCE`（国企指数）
- [ ] 历史数据返回正常（Open / High / Low / Close / Volume）

#### C2. pandas-ta 技术指标验证（必做）

```bash
pip install pandas-ta
```

```python
import pandas_ta as ta
df = yf.Ticker("0700.HK").history(period="3mo")
df.ta.macd(append=True)
df.ta.rsi(append=True)
df.ta.bbands(append=True)
print(df.columns.tolist())   # 确认指标列已添加
```

**验证要点：**
- [ ] MACD（12/26/9）计算正常
- [ ] RSI（14）计算正常
- [ ] 布林带（20/2）计算正常
- [ ] MA5 / MA20 / MA50 计算正常

#### C3. FastAPI 环境验证（必做）

```bash
pip install fastapi uvicorn
```

```python
# main.py（最小测试）
from fastapi import FastAPI
app = FastAPI()

@app.get("/ping")
def ping():
    return {"status": "ok"}
```

```bash
uvicorn main:app --reload
# 访问 http://localhost:8000/ping，返回 {"status":"ok"} 即成功
```

**验证要点：**
- [ ] FastAPI 启动无报错
- [ ] http://localhost:8000/docs 可访问（自动生成 API 文档）

#### C4. NewsAPI 验证（可选，非 MVP 必须）

```python
import requests
API_KEY = "YOUR_NEWSAPI_KEY"
url = f"https://newsapi.org/v2/everything?q=Hang+Seng&language=en&apiKey={API_KEY}"
r = requests.get(url)
print(r.json()['articles'][0]['title'])
```

**验证要点：**
- [ ] 能返回英文财经新闻文章列表
- [ ] 免费版 100 次/天额度够用于开发测试

---

### D. 数据库设计确认

在搭建后端前，需要最终确认数据库表结构（SQLite）：

#### D1. 核心数据表

```sql
-- 交易记录表
CREATE TABLE trades (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    ticker      TEXT NOT NULL,          -- 股票代码（如 0700）
    name        TEXT,                   -- 股票名称
    direction   TEXT NOT NULL,          -- BUY / SELL
    qty         INTEGER NOT NULL,       -- 买卖股数（以"股"为单位）
    price       REAL NOT NULL,          -- 成交价（HKD）
    fee         REAL DEFAULT 0,         -- 佣金费用
    trade_date  DATE NOT NULL,          -- 交易日期
    notes       TEXT,                   -- 备注
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 自选股表
CREATE TABLE watchlist (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    ticker      TEXT NOT NULL UNIQUE,
    name        TEXT,
    alert_price REAL,                   -- 价格提醒
    notes       TEXT,
    added_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- K线缓存表（减少 API 调用）
CREATE TABLE price_cache (
    ticker      TEXT NOT NULL,
    date        DATE NOT NULL,
    open        REAL,
    high        REAL,
    low         REAL,
    close       REAL,
    volume      INTEGER,
    PRIMARY KEY (ticker, date)
);

-- 股票基本面缓存表
CREATE TABLE stock_info_cache (
    ticker      TEXT PRIMARY KEY,
    name        TEXT,
    sector      TEXT,
    pe_ratio    REAL,
    market_cap  REAL,
    dividend    REAL,
    updated_at  DATETIME
);
```

**验证要点：**
- [ ] 表结构满足 Portfolio Performance Review 7 个子模块的计算需求
- [ ] 考虑港股"手数"（1手 = 通常 100~2000 股，视个股而定）

---

### E. API 接口设计确认

根据 UI 原型，以下是必须实现的后端接口（MVP 阶段）：

| 接口 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 大盘指数 | GET | `/api/market/indices` | 返回 HSI / HSCEI / HSTECH / S&P500 / SSE |
| 股票报价 | GET | `/api/stock/{ticker}/quote` | 当前价格、涨跌幅 |
| K 线数据 | GET | `/api/stock/{ticker}/history` | 参数：period=1d/5d/1m/3m/1y |
| 技术指标 | GET | `/api/stock/{ticker}/indicators` | MACD / RSI / MA / 布林带 |
| 股票搜索 | GET | `/api/search?q={keyword}` | 模糊匹配股票名称或代码 |
| 涨跌榜 | GET | `/api/market/movers` | type=gainers/losers/turnover |
| 行业分类 | GET | `/api/market/sectors` | 各板块涨跌幅 |
| 自选股列表 | GET | `/api/watchlist` | 读取本地 SQLite |
| 添加自选股 | POST | `/api/watchlist` | body: {ticker} |
| 删除自选股 | DELETE | `/api/watchlist/{ticker}` | |
| 添加交易 | POST | `/api/trades` | body: 交易记录 |
| 获取持仓 | GET | `/api/portfolio/positions` | 计算加权平均成本、浮动盈亏 |
| 盈亏统计 | GET | `/api/portfolio/performance` | 7 个子模块数据 |
| 每日推送 | POST | `/api/push/daily` | 定时任务触发 |

---

### F. Flutter 项目结构规划

建议 Flutter 项目目录结构（参考 UI 原型页面划分）：

```
frontend/
└── lib/
    ├── main.dart                 # 入口文件
    ├── app.dart                  # App 主题、路由配置
    ├── constants/
    │   ├── colors.dart           # 主题色（深色模式）
    │   └── api_endpoints.dart    # API 地址常量
    ├── models/
    │   ├── stock.dart            # 股票数据模型
    │   ├── trade.dart            # 交易记录模型
    │   └── portfolio.dart        # 持仓 / 盈亏模型
    ├── services/
    │   ├── api_service.dart      # HTTP 请求封装（dio）
    │   ├── db_service.dart       # SQLite 操作（sqflite）
    │   └── notification_service.dart
    ├── providers/                # Riverpod 状态管理
    │   ├── market_provider.dart
    │   ├── portfolio_provider.dart
    │   └── watchlist_provider.dart
    ├── screens/
    │   ├── market/               # Market 页面
    │   ├── portfolio/            # Portfolio 页面
    │   ├── watchlist/            # Watchlist 页面
    │   ├── tools/                # Tools 页面
    │   ├── settings/             # Settings 页面
    │   └── stock_detail/         # 个股详情页
    └── widgets/
        ├── stock_chart.dart      # K 线图组件
        ├── index_card.dart       # 指数卡片
        ├── trade_form.dart       # 交易记录表单
        └── common/               # 通用组件
```

---

### G. 关键技术决策确认

在开始编码前，以下决策需最终确认：

| 决策点 | 当前选择 | 备选方案 | 状态 |
|--------|----------|----------|------|
| 状态管理方案 | Riverpod 2.x | Bloc / Provider | [ ] 确认 |
| K 线图组件 | `k_chart` | `flutter_candlesticks` / `syncfusion_flutter_charts` | [ ] 确认 |
| 本地缓存策略 | sqflite（主）+ Hive（快速缓存）| 仅 sqflite | [ ] 确认 |
| 数据刷新频率 | 每 15 秒（延迟报价）| 每 30 秒 / 手动刷新 | [ ] 确认 |
| 后端运行模式 | 本地运行（开发阶段）| Render.com（部署后）| [ ] 确认 |
| 港股手数单位 | 以"手"为单位记录，折算时 × 每手股数 | 直接以"股"记录 | [ ] 确认 |
| 推送实现方式 | flutter_local_notifications（本地）| Firebase FCM（远程）| [ ] 确认 |

---

### H. 开始第一个 Sprint 的前置条件

以下所有条件满足后，可以开始 Sprint 1（后端数据服务层）：

- [ ] A1–A7 全部安装完成，`flutter doctor` 全绿
- [ ] B1（GitHub）账号已创建，仓库已初始化
- [ ] C1（yfinance）验证通过
- [ ] C3（FastAPI）验证通过
- [ ] D1 数据库表结构已最终确认
- [ ] G 中所有技术决策已完成

---

## 📱 UI 原型使用说明

文件：`portfolio_prototype.html`

这是一个**单文件 HTML 原型**，包含完整的交互和 mock 数据，可直接在浏览器中打开。

**手机查看方式：**
1. 将文件传至手机（微信/邮件/AirDrop/USB）
2. 直接用手机浏览器（Chrome）打开 `.html` 文件
3. 建议加至"主屏幕"获得全屏体验

**设计规范（Flutter 开发时参照）：**
- 背景色：`#0d1117`（深黑）
- 卡片背景：`#161b22`
- 边框色：`#30363d`
- 主强调色：`#58a6ff`（蓝）
- 涨色：`#f03e3e`（红）/ 跌色：`#3fb950`（绿）—— 港股惯例
- 字体：系统默认 sans-serif
- 底部导航：5 个 Tab（Market / Portfolio / Watchlist / Tools / Settings）

---

## 📦 文件清单

本压缩包包含以下文件：

| 文件 | 说明 |
|------|------|
| `01_User_Requirements.md` | 用户需求文档 v1.1 |
| `01_User_Requirements.docx` | 同上（Word 版） |
| `02_Resources_TechStack.md` | 技术栈与资源清单 |
| `02_Resources_TechStack.docx` | 同上（Word 版） |
| `03_Project_Plan.md` | 项目计划（20 周）|
| `03_Project_Plan.docx` | 同上（Word 版） |
| `04_Pre_Coding_Checklist.md` | **本文档** — 编码前准备清单 |
| `portfolio_prototype.html` | **UI 原型** — 全功能交互原型 |

---

*最后更新：2026-03-30*
