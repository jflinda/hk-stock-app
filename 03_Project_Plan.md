# 香港股票投资分析 App — 项目计划
**版本：** v2.0  
**原始日期：** 2026-03-29  
**最后更新：** 2026-04-01  
**预计总工期：** 约 20 周（5 个月）

---

## 1. 项目目标

在 5 个月内完成一个可在 Android 手机安装的港股投资辅助 App，具备市场分析、个股查询、交易记录管理及每日推送功能。

---

## 2. 开发方式说明

本项目采用 **AI 辅助全栈开发**模式（WorkBuddy Agentic）：

- 代码编写、调试、测试、Git 提交均由 AI 自动执行
- 项目计划实时更新，反映每次 AI 工作的实际成果
- 每个 Sprint 完成后自动推送至 GitHub（`jflinda/hk-stock-app`）
- 用户负责方向决策、验收测试及最终部署

**实际开发节奏**远快于原计划，原"按周"计划已调整为"按 Sprint"。

---

## 3. 整体进度（截至 2026-04-01）

```
阶段 1：规划与设计    ✅ 已完成（2026-03-29）
阶段 2：环境搭建      ✅ 已完成（2026-03-29 ~ 03-31）
阶段 3：后端开发      🟡 Sprint 1-2 已完成核心部分
阶段 4：前端开发      🟡 Sprint 1-2 已完成核心部分
阶段 5：测试与优化    ⏳ Sprint 3 起逐步进行
阶段 6：发布上线      ⏳ 待定
```

---

## 4. Sprint 进度详情

### ✅ 阶段 1 & 2：规划与环境搭建（2026-03-29 ~ 03-31）

| 任务 | 状态 | 完成时间 | 备注 |
|------|------|----------|------|
| 确认功能需求（v1.1） | ✅ 完成 | 2026-03-29 | 需求文档已定稿 |
| 安装 Flutter SDK 3.41.6 | ✅ 完成 | 2026-03-31 | `C:\flutter\flutter\bin` |
| 安装 Python 3.14.3 | ✅ 完成 | 2026-03-29 | managed runtime |
| 安装 Android Studio | ✅ 完成 | 2026-03-31 | SDK 36.1.0，licenses 已接受 |
| 初始化 Git 仓库 | ✅ 完成 | 2026-03-29 | commit 4f20e7c |
| 推送至 GitHub | ✅ 完成 | 2026-03-29 | `jflinda/hk-stock-app`（Private） |
| 搭建 FastAPI 后端骨架 | ✅ 完成 | 2026-03-29 | 5 个 router，SQLite 4 张表 |
| 搭建 Flutter 前端骨架 | ✅ 完成 | 2026-03-31 | `hk_stock_app` 项目已生成 |
| HTML 交互原型 | ✅ 完成 | 2026-03-30 | 全部 5 页面 + 个股详情页 |
| yfinance + FastAPI 验证 | ✅ 完成 | 2026-03-31 | `http://localhost:8000/ping` 正常 |

**产出物：**
- `01_User_Requirements.md / .docx`（v1.1）
- `02_Resources_TechStack.md / .docx`
- `04_Pre_Coding_Checklist.md`
- `05_Setup_Guide.md`
- `portfolio_prototype.html`（完整 HTML 原型）
- `HK_StockApp_Protocol_v2.0.zip`（完整打包）

---

### ✅ Sprint 1：后端数据服务 + Flutter 基础框架（2026-03-31）

**Commit：** `029cc0c`，`6219bf9`，`6a4c3d1`，`50d68c2`

#### 后端（Sprint 1 Day 1）
| 任务 | 状态 |
|------|------|
| 封装 yfinance MarketService（5 分钟缓存） | ✅ |
| `/api/market/indices`（HSI/HSCEI/HSTI/SP500/SSE） | ✅ |
| `/api/stock/{ticker}/quote`（详细行情 + 52W + P/E + 分红率） | ✅ |
| `/api/stock/{ticker}/history`（K 线 + MA5/MA20，多时间跨度） | ✅ |
| `/api/market/movers`（涨幅/跌幅/成交额榜） | ✅ |
| 所有端点实测通过（实时数据） | ✅ |

#### 前端（Sprint 1 Day 2-3）
| 任务 | 状态 |
|------|------|
| Flutter 底部导航栏（5 个 Tab） | ✅ |
| Market / Portfolio / Watchlist / Tools / Settings 屏幕骨架 | ✅ |
| 个股详情页（StockDetail）骨架 | ✅ |
| 页面间导航打通 | ✅ |
| 深色主题 UI 设计 | ✅ |

---

### ✅ Sprint 2：真实 API 数据集成（2026-03-31 ~ 04-01）

**Commit：** `3dc42f9`（32 files，+4638/-219 行）

#### Day 1：数据模型 & Providers
| 任务 | 状态 |
|------|------|
| 数据模型：WatchlistItem, PortfolioSummary, Position, Trade | ✅ |
| JSON 序列化代码生成（.g.dart） | ✅ |
| Riverpod providers：watchlist / portfolio / trades | ✅ |
| API Service 扩展（Watchlist / Portfolio / Trades 端点） | ✅ |

#### Day 2-4：屏幕集成 & 后端修复
| 任务 | 状态 |
|------|------|
| Portfolio 屏幕：真实数据 + Add Trade Modal + Swipe-to-delete | ✅ |
| Watchlist 屏幕：真实数据 + 筛选栏 + Add/Remove | ✅ |
| Stock Detail 屏幕：真实行情 + 面积折线图（CustomPainter）+ Quick Trade | ✅ |
| Market 屏幕：修复 `ref.invalidate()` RefreshIndicator | ✅ |
| main.dart：深色 ThemeData + 30s 自动刷新 Timer | ✅ |
| 后端：修复 dividendYield（× 100 问题） | ✅ |
| 后端：修复 52W 区间（改用 1y 历史数据） | ✅ |
| 后端：marketCap 格式化（HK$4.37T 等） | ✅ |
| 后端：Portfolio / Watchlist / Trades CRUD 完整实现 | ✅ |
| `flutter analyze`：49 个 info 级（无 errors/warnings） | ✅ |
| Git commit + GitHub push | ✅ |

---

### 🔜 Sprint 3：K 线图升级 + 推送通知 + Portfolio Review（计划中）

**目标：** 完成专业 K 线图、本地推送通知、Portfolio Performance Review 7 子模块

#### Day 1-2：k_chart 包集成（蜡烛图）
| 任务 | 优先级 |
|------|--------|
| 在 `pubspec.yaml` 添加 `k_chart` 依赖 | 🔴 高 |
| 在 StockDetail 替换 CustomPainter 为 k_chart 组件 | 🔴 高 |
| 支持蜡烛图（OHLC）+ 成交量柱 | 🔴 高 |
| 叠加 MA5 / MA20 / MA50 均线 | 🟡 中 |
| 叠加 MACD / RSI / 布林带（Bollinger Bands）指标 | 🟡 中 |
| 手势缩放 & 滑动（pinch-to-zoom，scroll） | 🟡 中 |

#### Day 3：本地推送通知
| 任务 | 优先级 |
|------|--------|
| 添加 `flutter_local_notifications` 依赖 | 🔴 高 |
| Android 通知权限配置 | 🔴 高 |
| 实现每日收市后推送（APScheduler + 后端触发） | 🔴 高 |
| 实现价格警报通知（Watchlist alertPrice 触发） | 🟡 中 |
| 通知点击跳转相关股票详情页 | 🟡 中 |

#### Day 4-5：Portfolio Performance Review（7 子模块）
| 子模块 | 优先级 |
|--------|--------|
| 1. Allocation Overview（持仓分布饼图） | 🔴 高 |
| 2. Return Analysis（累计收益折线图，与 HSI 对比） | 🔴 高 |
| 3. Trade Journal Stats（胜率/均盈/均亏/Profit Factor） | 🔴 高 |
| 4. Risk Metrics（波动率/最大回撤/夏普比率） | 🟡 中 |
| 5. Sector Exposure（行业暴露度热力图） | 🟡 中 |
| 6. Top Performers（最佳/最差持仓排名） | 🟡 中 |
| 7. Monthly P&L Heatmap（月度盈亏热力图） | 🟢 低 |

---

### 📋 Sprint 4（初步规划）

| 功能 | 优先级 |
|------|--------|
| NewsAPI 财经新闻集成 | 🟡 中 |
| 个股新闻列表（StockDetail 新闻 Tab） | 🟡 中 |
| CSV 交易记录导出 | 🟡 中 |
| 弱网/断网降级处理 + 本地缓存 | 🟡 中 |
| Android APK 打包（debug） | 🟡 中 |
| 真机调试 | 🟡 中 |

---

### 📋 Sprint 5（初步规划）

| 功能 | 优先级 |
|------|--------|
| App 签名（Keystore） | 🔴 高 |
| Release APK 构建 | 🔴 高 |
| 性能优化（K 线分页加载、懒加载） | 🟡 中 |
| Google Play 上架 / APK 直接分发 | 🟡 中 |
| 崩溃监控（Firebase Crashlytics） | 🟢 低 |

---

## 5. 里程碑（Milestones）

| 里程碑 | 计划时间 | 实际时间 | 状态 | 验收标准 |
|--------|----------|----------|------|----------|
| M1 - 需求确认 | 第 2 周末 | 2026-03-29 | ✅ 完成 | 需求文档 v1.1 定稿 |
| M2 - 环境搭建 | 第 3 周末 | 2026-03-31 | ✅ 完成 | Flutter + FastAPI 均可运行 |
| M3 - 后端 API MVP | 第 8 周末 | 2026-03-31 | ✅ 完成 | 全部核心端点可调用 |
| M4 - 前端 MVP（基础） | 第 16 周末 | 2026-04-01 | ✅ 完成 | 5 页面真实数据运行 |
| M5 - 前端 MVP（完整） | Sprint 3 末 | 待定 | 🔜 进行中 | K 线图 + 推送 + Performance Review |
| M6 - 测试完成 | 第 19 周末 | 待定 | ⏳ 待开始 | 测试通过率 ≥ 95% |
| M7 - 正式上线 | 第 20 周末 | 待定 | ⏳ 待开始 | APK 可安装使用 |

---

## 6. 技术栈（实际采用）

| 层级 | 技术 | 版本 | 用途 |
|------|------|------|------|
| 前端 | Flutter | 3.41.6 | Android App 框架 |
| 前端状态管理 | Riverpod | ^2.x | 状态管理 + 数据缓存 |
| 前端 K 线图 | k_chart（Sprint 3） | 最新 | 专业蜡烛图 |
| 前端本地存储 | sqflite（Sprint 4） | 最新 | 本地持久化 |
| 前端推送 | flutter_local_notifications（Sprint 3） | 最新 | 本地通知 |
| 后端 | Python FastAPI | 0.115.x | REST API 服务 |
| 后端数据 | yfinance | 最新 | 港股行情数据 |
| 后端任务调度 | APScheduler | 3.x | 定时推送任务 |
| 数据库 | SQLite（hkstock.db） | — | 本地数据持久化 |
| 运行时 | Python 3.14.3 | managed | 后端运行环境 |
| 版本控制 | Git + GitHub | — | `jflinda/hk-stock-app`（Private） |

---

## 7. 已知技术问题 & 踩坑记录

| 问题 | 解决方案 |
|------|----------|
| yfinance `dividendYield` 已是百分比（1.1 = 1.1%），不需 ×100 | 已修复（Sprint 2） |
| 52W 高低需用 `history(period="1y")` 单独获取 | 已修复（Sprint 2） |
| `ref.refresh()` 返回 Future，产生 unused_result 警告 | 改用 `ref.invalidate()`（Sprint 2） |
| uvicorn 重启需先 `Stop-Process` 清理旧进程（端口 8000 残留） | 已记录，每次重启前执行 |
| Flutter `late final` 不能用于构造函数可选参数 | 去掉 `late final` 修饰符 |
| `WidthType.PERCENTAGE` 在 Google Docs 中破版 | 全部改用 `WidthType.DXA` |

---

## 8. 关键路径（Critical Path）

```
Sprint 3: k_chart 集成
    ↓
Sprint 3: 推送通知
    ↓
Sprint 3: Portfolio Performance Review
    ↓
Sprint 4: 新闻 + CSV 导出 + 本地缓存
    ↓
Sprint 4: Debug APK + 真机测试
    ↓
Sprint 5: Release APK + 签名 + 上架
```

---

## 9. 风险管理（更新）

| 风险 | 可能性 | 影响 | 应对措施 | 状态 |
|------|--------|------|----------|------|
| yfinance API 不稳定 / 数据错误 | 中 | 高 | 已记录多项数据修复经验；备选 Alpha Vantage | 🟡 持续监控 |
| 港股数据延迟 > 15 分钟 | 低 | 中 | 接受延迟数据（免费方案）；付费 Futu API 待定 | 🟢 已接受 |
| k_chart 包 Flutter 3.x 兼容性 | 低 | 高 | Sprint 3 开始前做 POC 验证 | ⏳ 待验证 |
| 开发时间超期 | 低（AI 加速后） | 中 | AI 辅助开发大幅提速；优先保 MVP | 🟢 可控 |
| Google Play 审核被拒 | 低 | 低 | 先通过 APK 直接分发 | 🟢 已有备案 |
| flutter_local_notifications Android 13+ 权限 | 中 | 中 | Sprint 3 实现时处理运行时权限请求 | ⏳ 待处理 |

---

## 10. 项目文件夹结构（实际）

```
stocktrading/
├── 01_User_Requirements.md / .docx   # 用户需求文档 v1.1
├── 02_Resources_TechStack.md / .docx # 资源与技术栈
├── 03_Project_Plan.md / .docx        # 项目计划（本文档）v2.0
├── 04_Pre_Coding_Checklist.md        # 开发前检查清单
├── 05_Setup_Guide.md                 # 环境搭建指南
├── portfolio_prototype.html          # 完整 HTML 交互原型
├── HK_StockApp_Protocol_v2.0.zip    # 文档打包
├── backend/
│   ├── main.py                       # FastAPI 入口
│   ├── routers/
│   │   ├── market.py                 # 行情路由
│   │   ├── stocks.py                 # 个股路由
│   │   ├── watchlist.py              # 自选股路由（CRUD）
│   │   ├── trades.py                 # 交易记录路由（CRUD）
│   │   └── portfolio.py              # 持仓路由（CRUD）
│   ├── services/
│   │   └── market_service.py         # yfinance 封装 + 缓存
│   ├── database/
│   │   └── init_db.py                # SQLite 初始化（4 张表）
│   ├── hkstock.db                    # SQLite 数据库
│   └── run_api.bat                   # 快捷启动脚本
└── frontend/
    ├── lib/
    │   ├── main.dart                 # 入口 + ThemeData + 30s 刷新
    │   ├── constants/
    │   │   └── app_constants.dart    # 颜色常量、配置
    │   ├── models/                   # 数据模型 + .g.dart 序列化
    │   │   ├── stock_quote.dart
    │   │   ├── kline_data.dart
    │   │   ├── watchlist_item.dart
    │   │   ├── portfolio_summary.dart
    │   │   ├── position.dart
    │   │   └── trade.dart
    │   ├── providers/                # Riverpod 状态管理
    │   │   ├── market_providers.dart
    │   │   ├── watchlist_providers.dart
    │   │   ├── portfolio_providers.dart
    │   │   └── trades_providers.dart
    │   ├── services/
    │   │   └── api_service.dart      # HTTP 客户端
    │   ├── screens/                  # 主屏幕
    │   │   ├── market/
    │   │   ├── portfolio/
    │   │   ├── watchlist/
    │   │   ├── stock_detail/
    │   │   ├── tools/
    │   │   └── settings/
    │   └── widgets/                  # 公共组件
    ├── android/
    └── pubspec.yaml
```

---

## 11. GitHub 提交历史

| Commit | 时间 | 内容 |
|--------|------|------|
| `4f20e7c` | 2026-03-29 | Initial commit: 项目结构 + 后端骨架 + HTML 原型 |
| `029cc0c` | 2026-03-31 | Sprint 1: yfinance 数据服务层 + 所有核心 API 端点 |
| `6a4c3d1` | 2026-03-31 | Sprint 1 Day 1 completion summary |
| `50d68c2` | 2026-03-31 | API 文档 + 前端开发指南 |
| `6219bf9` | 2026-03-31 | Sprint 1 Day 2: Flutter 前端框架 + Market 页面 + 导航 |
| `3dc42f9` | 2026-04-01 | Sprint 2: 真实 API 集成 + 数据模型 + Riverpod providers |

---

## 12. 成功标准

项目完成时，用户应可以：
- ✅ 查看港股大盘指数及个股实时（延迟）行情
- ✅ 管理自选股列表（添加/删除/筛选）
- ✅ 记录每笔买卖，查看持仓盈亏
- 🔜 查看专业 K 线图及技术指标（Sprint 3）
- 🔜 每日收市后收到行情推送摘要（Sprint 3）
- 🔜 查看 Portfolio Performance Review（Sprint 3）
- ⏳ 在 Android 手机上安装并启动 App（Sprint 4-5）
