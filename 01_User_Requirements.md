# Hong Kong Stock Investment Analysis App — User Requirements Document
**Version:** v1.1  
**Date:** 2026-03-29  
**Platform:** Android (Downloadable & Installable)  
**Status:** Approved for Design & Development

---

## 1. Project Overview

This application is designed to help individual investors analyse the Hong Kong stock market (HKEX), track market trends, record personal buy/sell transactions, review portfolio performance, and receive daily market digests — empowering users to make more informed investment decisions.

---

## 2. Target Users

| Attribute | Description |
|-----------|-------------|
| Primary User | Individual retail investors trading Hong Kong stocks |
| Usage Frequency | Every trading day (daily use) |
| Technical Level | General smartphone user; no programming knowledge required |
| Default Language | **English** (user may switch to Traditional Chinese) |

---

## 3. Functional Requirements

### 3.1 Market Overview
- Display real-time (or delayed) data for major indices: Hang Seng Index (HSI), H-Shares Index (HSCEI), Hang Seng Tech Index (HSTECH)
- Display top gainers and top losers for the day (by % change)
- Display most active stocks by turnover value
- Display intraday and historical market trend charts (Daily / Weekly / Monthly / Yearly)

### 3.2 Sector Analysis
- Browse Hong Kong stocks by major industry sectors (Property, Finance, Technology, Healthcare, Energy, Consumer Goods, etc.)
- View daily sector performance heatmap (sector-level gain/loss at a glance)
- View list of leading stocks within each sector and their trends
- View sector capital flow (net buy / net sell)

### 3.3 Individual Stock Analysis
- Search stocks by name or ticker code (e.g. 0700.HK)
- **Stock Summary Card:**
  - Company name, ticker code, sector
  - Real-time price, % change, volume, market capitalisation
- **Technical Analysis Charts:**
  - Candlestick (K-Line) chart — Daily / Weekly / Monthly
  - Technical indicators: MA (5/10/20/50/200-day), MACD, RSI, Bollinger Bands
  - Support and resistance level annotations
- **Fundamental Data:**
  - P/E Ratio, P/B Ratio, Dividend Yield
  - 52-week high / low
  - Recent earnings summary
- AI-generated trend analysis summary (simple Buy / Hold / Sell recommendation with reasoning)
- Related financial news list (sourced via financial news API)

### 3.4 Watchlist
- Add / remove stocks to a personal watchlist
- View real-time quotes for all watchlist stocks on a single screen
- Support grouping / tagging (e.g. Blue Chips, Tech, Watch List, etc.)

### 3.5 Trade Journal (Transaction Records)
- Manually log each buy/sell transaction:
  - Stock ticker / name
  - Direction: Buy or Sell
  - Price, quantity, brokerage fees / commissions
  - Date and time
  - Notes (e.g. reason for entry)
- **Open Positions Overview:**
  - Current holdings list with average cost, current price, unrealised P&L (amount + %)
  - Total capital invested, total market value, total unrealised P&L
- Closed positions history (full trade log)
- Monthly / yearly P&L summary chart

### 3.6 Portfolio Performance Review
This module provides comprehensive analysis of the user's overall investment portfolio — both current and historical — to help the user understand how their investments are performing and identify areas for improvement.

#### 3.6.1 Overall Portfolio Summary
- Total portfolio value (cost vs. current market value)
- Total realised P&L (from all closed trades)
- Total unrealised P&L (from all open positions)
- Overall portfolio return % (time-weighted)
- Cash balance / uninvested capital tracking

#### 3.6.2 Historical Performance Chart
- Portfolio value over time (line chart — daily / monthly / yearly view)
- Benchmark comparison: overlay HSI or HSTECH index performance for the same period
- Drawdown chart: visualise peak-to-trough declines over time

#### 3.6.3 Closed Trade Analysis
- Complete list of all closed (bought and sold) trades with entry price, exit price, hold duration, and realised P&L
- Win rate: percentage of profitable trades vs. losing trades
- Average profit on winning trades vs. average loss on losing trades
- Profit factor: total gains ÷ total losses
- Best and worst trades (by absolute P&L and by %)
- Average holding period per trade

#### 3.6.4 Portfolio Composition & Allocation
- Current asset allocation by sector (pie / donut chart)
- Concentration risk indicator: flag any single stock exceeding 20% of portfolio
- Top holdings table (ranked by current market value)

#### 3.6.5 Period Performance Reports
- Selectable reporting period: weekly, monthly, quarterly, yearly, or custom date range
- For each period: opening value, closing value, net P&L, return %, number of trades
- Month-by-month performance calendar view (green/red tiles for positive/negative months)
- Exportable performance report (PDF or CSV)

#### 3.6.6 Dividend Income Tracking
- Log dividends received per stock
- Total dividend income by month / year
- Projected annual dividend income based on current holdings and historical yield

#### 3.6.7 Risk Metrics
- Portfolio Beta (sensitivity vs. HSI benchmark)
- Sharpe Ratio (risk-adjusted return)
- Volatility (annualised standard deviation of returns)
- Maximum Drawdown for the selected period

### 3.7 Daily Market Digest
- Push notification after each trading day closes:
  - Summary of overall market performance
  - Performance of watchlist stocks
  - Performance of current holdings
  - Key financial news summary
- User-configurable push time (default: 4:30 PM HKT, after HKEX market close)

### 3.8 Analysis Tools
- **Stock Comparison Tool:** Compare up to 3 stocks side-by-side (price trend, key metrics)
- **Position Sizing Calculator:** Calculate recommended position size based on account size, risk %, and stop-loss level
- **Dividend Calculator:** Estimate projected annual dividend income from a given holding

### 3.9 Settings
- **Language:** English (default) / Traditional Chinese
- **Currency Display:** HKD (Hong Kong Dollar)
- **Push Notifications:** On/Off toggle, configurable time
- **Data Refresh Rate:** 15 seconds / 1 minute / 5 minutes
- **Local Data Backup / Export:** Export trade journal and portfolio data as CSV
- **Theme:** Dark mode (default) / Light mode
- **Benchmark Index:** Select default benchmark for portfolio comparison (HSI / HSTECH / HSCEI)

---

## 4. Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| Performance | Market data delay ≤ 15 seconds (free tier); charts load within 2 seconds |
| Usability | Clean and intuitive UI; common tasks completable within 3 taps |
| Reliability | Crash rate < 1%; offline cached data viewable when network is unavailable |
| Security | Trade records stored with local encryption; no account login required |
| Compatibility | Android 8.0 and above |
| Localisation | English default; Traditional Chinese switchable; HKT (UTC+8) timezone |
| Data Integrity | P&L calculations verified accurate; portfolio value reconciles with trade log |

---

## 5. Data Source Requirements

| Data Type | Recommended Source |
|-----------|-------------------|
| Real-time / Delayed Quotes | Yahoo Finance API, Alpha Vantage, Futu OpenAPI |
| Historical Price Data | Yahoo Finance (yfinance Python library) |
| Financial News | NewsAPI, AASTOCKS, HKEJ RSS feeds |
| Fundamental Data | Yahoo Finance, Macrotrends |
| Sector Classification | HKEX official website data |
| Dividend Data | Yahoo Finance, manual user input |
| Benchmark Index Data | Yahoo Finance (^HSI, ^HSCE, ^HSTECH) |

---

## 6. UI / UX Design Requirements

- **Style:** Modern financial app aesthetic (reference: Futu NiuNiu, Tiger Brokers)
- **Default Theme:** Dark theme (deep navy / black background)
- **Colour Convention:** Red = price up (gain); Green = price down (loss) — Hong Kong / China market convention
- **Charts:** Smooth, interactive candlestick charts with pinch-to-zoom and swipe
- **Bottom Navigation Bar (5 tabs):**
  1. Market
  2. Watchlist
  3. Portfolio *(combined Trade Journal + Performance Review)*
  4. Tools
  5. Settings
- **Language:** All UI labels, menus, and notifications in English by default; fully translated to Traditional Chinese when user switches language

---

## 7. App Navigation Structure

```
App
├── Market
│   ├── Indices Overview (HSI, HSCEI, HSTECH)
│   ├── Top Gainers / Losers
│   ├── Most Active
│   └── Sector Heatmap
├── Watchlist
│   ├── My Watchlist (grouped)
│   └── Stock Detail Page
│       ├── Price Chart + Indicators
│       ├── Fundamentals
│       ├── AI Summary
│       └── News
├── Portfolio
│   ├── Open Positions
│   ├── Trade Journal (log buy/sell)
│   ├── Performance Review
│   │   ├── Overall Summary
│   │   ├── Historical Chart (vs. benchmark)
│   │   ├── Closed Trade Analysis
│   │   ├── Allocation Breakdown
│   │   ├── Period Reports
│   │   ├── Dividend Tracker
│   │   └── Risk Metrics
│   └── Export Data
├── Tools
│   ├── Stock Comparison
│   ├── Position Sizing Calculator
│   └── Dividend Calculator
└── Settings
    ├── Language
    ├── Theme
    ├── Notifications
    ├── Data Refresh
    └── Backup / Export
```

---

## 8. Future Version Features (V2.0 Roadmap)

- Connect to broker API for automated trade execution (Futu / Tiger Brokers)
- AI stock screening and recommendation engine (technical + fundamental scoring)
- Portfolio stress testing and scenario analysis
- Tax report generation (for realised gains)
- Social / community discussion features
- iPad / iOS version

---

## 9. Document Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-29 | Initial draft |
| v1.1 | 2026-03-29 | Changed default language to English (Traditional Chinese as option); Added Portfolio Performance Review module (§3.6) with 7 sub-sections; Added app navigation structure (§7); Updated Settings and UI sections accordingly |
