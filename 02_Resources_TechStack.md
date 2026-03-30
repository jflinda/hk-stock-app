# 香港股票投资分析 App — 所需资源及技术栈
**版本：** v1.0  
**日期：** 2026-03-29

---

## 1. 技术架构总览

```
┌─────────────────────────────────────┐
│         Android App (前端)           │
│   React Native / Flutter            │
└──────────────┬──────────────────────┘
               │ REST API / WebSocket
┌──────────────▼──────────────────────┐
│         后端服务 (Backend)           │
│   Python FastAPI / Node.js          │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│     数据层 (Data Layer)              │
│  外部 API + 本地 SQLite              │
└─────────────────────────────────────┘
```

**架构选择说明：**
- 前端优先考虑 **Flutter**（Google 官方跨平台框架，性能好，适合金融图表）
- 后端使用 **Python FastAPI**（数据处理能力强，金融库生态丰富）
- 本地数据用 **SQLite**（交易记录、自选股等离线数据）

---

## 2. 前端技术栈（Android App）

| 技术 | 用途 | 推荐方案 |
|------|------|----------|
| 开发框架 | 跨平台 Android App | **Flutter 3.x**（Dart 语言）|
| K 线图表 | 股票走势图、技术指标 | `k_chart` / `flutter_candlesticks` |
| 普通图表 | 饼图、柱状图、折线图 | `fl_chart` |
| 状态管理 | 全局数据状态 | `Riverpod` 或 `Bloc` |
| 本地数据库 | 交易记录离线存储 | `sqflite`（SQLite for Flutter）|
| 网络请求 | API 调用 | `dio` |
| 推送通知 | 每日行情摘要推送 | `flutter_local_notifications` |
| 本地缓存 | 股票数据缓存 | `Hive` / `shared_preferences` |
| 深色模式 | 主题切换 | Flutter ThemeData |

---

## 3. 后端技术栈

| 技术 | 用途 | 说明 |
|------|------|------|
| **Python 3.11+** | 主要开发语言 | 金融数据处理库丰富 |
| **FastAPI** | REST API 框架 | 高性能，自动生成 API 文档 |
| **yfinance** | 获取 Yahoo Finance 数据 | 免费，支持港股（股票代码加 .HK）|
| **pandas** | 数据处理 | K 线数据计算、统计分析 |
| **ta-lib / pandas-ta** | 技术指标计算 | MA、MACD、RSI、布林带等 |
| **APScheduler** | 定时任务 | 每日数据更新、推送触发 |
| **SQLite / PostgreSQL** | 数据持久化 | 开发用 SQLite，生产可升级 PostgreSQL |
| **Redis**（可选）| 实时数据缓存 | 减少 API 调用频率 |
| **WebSocket** | 实时价格推送 | 使用 `websockets` 库 |

---

## 4. 数据 API 资源

### 4.1 免费方案（推荐入门）

| API | 数据类型 | 限制 | 港股支持 |
|-----|----------|------|----------|
| **Yahoo Finance (yfinance)** | 延迟报价、历史数据、基本面 | 无官方限制（非正式 API）| ✅ 优秀（代码：0700.HK）|
| **Alpha Vantage** | 延迟报价、技术指标 | 25次/天（免费版）| ✅ 支持 |
| **NewsAPI** | 财经新闻 | 100次/天（免费版）| ✅ 英文新闻 |
| **HKEX 官网 RSS** | 官方公告 | 无限制 | ✅ 官方来源 |

### 4.2 付费方案（进阶）

| API | 月费 | 优势 |
|-----|------|------|
| **Polygon.io** | ~$29/月 | 实时数据，稳定可靠 |
| **Futu OpenAPI** | 免费（需开户）| 专业港股数据，富途证券官方 |
| **Tiger Brokers API** | 免费（需开户）| 老虎证券官方，实时数据 |
| **Bloomberg API** | 企业级定价 | 最专业，超出个人需求 |

**建议：** 初期使用 yfinance 免费方案，后期可接入 Futu OpenAPI（富途）以获得实时数据。

---

## 5. 云端部署资源（后端托管）

| 方案 | 月费 | 适合阶段 |
|------|------|----------|
| **本地运行**（开发测试）| 免费 | 开发阶段 |
| **Railway.app** | ~$5/月 | 小型部署，简单易用 |
| **Render.com** | 免费起步 | 个人项目推荐 |
| **腾讯云轻量应用服务器** | ~¥50/月 | 国内访问稳定 |
| **AWS / Google Cloud** | 按用量计费 | 生产环境扩展 |

---

## 6. 开发工具

| 工具 | 用途 |
|------|------|
| **Android Studio** | Flutter Android 开发、调试、打包 |
| **VS Code** | 后端 Python 开发 |
| **Flutter SDK** | App 开发框架 |
| **Postman** | API 测试 |
| **Git + GitHub** | 版本控制 |
| **Figma**（可选）| UI 设计稿 |
| **DBeaver** | SQLite / 数据库管理 |

---

## 7. 人力资源需求

### 个人独立开发（推荐方案）

| 角色 | 技能要求 | 时间投入 |
|------|----------|----------|
| 全栈开发者（你）| Flutter + Python 基础 | 3-6 个月兼职 |

### 或者分工合作

| 角色 | 职责 |
|------|------|
| 前端开发 | Flutter App 开发 |
| 后端开发 | Python API + 数据处理 |
| UI/UX 设计 | 界面设计（可外包）|

---

## 8. 预算估算

### 最低成本方案（个人开发）

| 项目 | 月费/一次性 |
|------|------------|
| 域名 | ~$10/年 |
| 服务器（Render 免费版）| $0 |
| Yahoo Finance API | $0 |
| NewsAPI（免费版）| $0 |
| Android 开发者账号（Google Play）| $25 一次性 |
| **合计** | **约 $35 起步** |

### 进阶方案

| 项目 | 月费 |
|------|------|
| 腾讯云服务器 | ~¥50/月 |
| Futu OpenAPI | 免费（需开富途账户）|
| NewsAPI Pro | ~$50/月 |
| **合计** | **约 ¥50-300/月** |

---

## 9. 第三方服务账号清单

开发前需注册以下账号：

- [ ] Google Play Developer Account（发布 App）
- [ ] Yahoo Finance（直接使用，无需注册）
- [ ] Alpha Vantage 免费 API Key
- [ ] NewsAPI 免费 API Key
- [ ] GitHub 账号（代码版本管理）
- [ ] Render.com / Railway.app 账号（服务器托管）
- [ ] 富途证券账号（可选，获取 Futu OpenAPI 权限）
