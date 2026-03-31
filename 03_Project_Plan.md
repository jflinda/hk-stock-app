# 香港股票投资分析 App — 项目计划
**版本：** v3.0  
**原始日期：** 2026-03-29  
**最后更新：** 2026-04-01  
**预计剩余工期：** 约 1–3 周（视发布渠道而定）

---

## 1. 项目目标

构建一个可在 Android 手机安装的港股投资辅助 App，具备市场分析、个股查询、交易记录管理及每日推送功能。

**发布目标（双轨）：**
- **Option A：APK 直接分发** — 目标本周内完成，无需商店审核
- **Option B：Google Play 上架** — 目标 2–3 周内完成（含 7–14 天审核等待）

---

## 2. 开发方式说明

本项目采用 **AI 辅助全栈开发**模式（WorkBuddy Agentic）：

- 代码编写、调试、测试、Git 提交均由 AI 自动执行
- 用户负责方向决策、真机验收测试及最终部署
- 每个 Sprint 完成后自动推送至 GitHub（`jflinda/hk-stock-app`）

**实际开发速度说明：**

| 维度 | 原计划（人工）| 实际（AI 辅助）| 加速倍数 |
|------|-------------|--------------|---------|
| M4 前端 MVP | 第 16 周 | 第 3 天 | ~35x |
| 预计全部完成 | 第 20 周（5 个月）| 第 7–21 天 | ~10–20x |

原计划 5 个月工期已作废，以下采用**按天计算**的新计划。

---

## 3. 整体进度（截至 2026-04-01）

```
阶段 1：规划与设计       ✅ 已完成（2026-03-29，用时 1 天）
阶段 2：环境搭建         ✅ 已完成（2026-03-29 ~ 03-31，用时 2 天）
阶段 3：后端开发         ✅ Sprint 1-2 核心完成（2026-03-31 ~ 04-01）
阶段 4：前端开发         ✅ Sprint 1-2 核心完成（2026-03-31 ~ 04-01）
阶段 5：高级功能         🔜 Sprint 3 进行中
阶段 6：APK 打包测试     ⏳ Sprint 4 计划中
阶段 7A：APK 直接分发    ⏳ Sprint 4 末，约 2026-04-03
阶段 7B：Google Play 上架 ⏳ Sprint 5 末，约 2026-04-08 提交，2026-04-15~22 通过
```

---

## 4. Sprint 进度详情

### ✅ 阶段 1 & 2：规划与环境搭建（2026-03-29 ~ 03-31，3 天）

| 任务 | 状态 | 完成时间 |
|------|------|----------|
| 确认功能需求（v1.1） | ✅ 完成 | 2026-03-29 |
| 安装 Flutter SDK 3.41.6 | ✅ 完成 | 2026-03-31 |
| 安装 Python 3.14.3 | ✅ 完成 | 2026-03-29 |
| 安装 Android Studio | ✅ 完成 | 2026-03-31 |
| 初始化 Git 仓库 + GitHub 推送 | ✅ 完成 | 2026-03-29 |
| 搭建 FastAPI 后端骨架 | ✅ 完成 | 2026-03-29 |
| 搭建 Flutter 前端骨架 | ✅ 完成 | 2026-03-31 |
| HTML 交互原型（5 页面） | ✅ 完成 | 2026-03-30 |
| yfinance + FastAPI 验证 | ✅ 完成 | 2026-03-31 |

---

### ✅ Sprint 1：后端数据服务 + Flutter 基础框架（2026-03-31，1 天）

**Commit：** `029cc0c`, `6219bf9`, `6a4c3d1`, `50d68c2`

| 任务 | 状态 |
|------|------|
| yfinance MarketService（5 分钟缓存） | ✅ |
| `/api/market/indices`（HSI/HSCEI/HSTI/SP500/SSE） | ✅ |
| `/api/stock/{ticker}/quote`（行情 + 52W + P/E + 分红率） | ✅ |
| `/api/stock/{ticker}/history`（K 线 + MA5/MA20） | ✅ |
| `/api/market/movers`（涨幅/跌幅/成交额榜） | ✅ |
| Flutter 底部导航栏 + 5 个 Tab 骨架 | ✅ |
| 页面间导航打通 + 深色主题 | ✅ |

---

### ✅ Sprint 2：真实 API 数据全面集成（2026-03-31 ~ 04-01，1 天）

**Commit：** `3dc42f9`（32 files，+4638/-219 行）

| 任务 | 状态 |
|------|------|
| 数据模型：WatchlistItem / PortfolioSummary / Position / Trade | ✅ |
| Riverpod providers（watchlist / portfolio / trades） | ✅ |
| Portfolio 屏幕：真实数据 + Add Trade Modal + Swipe-to-delete | ✅ |
| Watchlist 屏幕：真实数据 + 筛选栏 + Add/Remove | ✅ |
| Stock Detail 屏幕：真实行情 + 面积折线图 + Quick Trade | ✅ |
| main.dart：深色 ThemeData + 30s 自动刷新 Timer | ✅ |
| 后端：dividendYield / 52W 区间 / marketCap 全部修复 | ✅ |
| 后端：Portfolio / Watchlist / Trades CRUD 完整实现 | ✅ |
| `flutter analyze`：49 个 info 级（无 errors/warnings） | ✅ |

---

### 🔜 Sprint 3：高级功能（计划：2026-04-01 ~ 04-02，约 1–2 天）

**目标：** 专业 K 线图 + 本地推送通知 + Portfolio Performance Review

#### Day 1：k_chart 蜡烛图集成
| 任务 | 优先级 |
|------|--------|
| `pubspec.yaml` 添加 `k_chart` 依赖，POC 验证兼容性 | 🔴 高 |
| StockDetail 替换 CustomPainter → k_chart 组件 | 🔴 高 |
| 蜡烛图（OHLC）+ 成交量柱 | 🔴 高 |
| MA5 / MA20 / MA50 均线叠加 | 🟡 中 |
| MACD / RSI / 布林带指标 | 🟡 中 |
| 手势缩放 & 滑动（pinch-to-zoom） | 🟡 中 |

#### Day 1-2：本地推送通知
| 任务 | 优先级 |
|------|--------|
| `flutter_local_notifications` 依赖 + Android 权限配置 | 🔴 高 |
| 每日收市后推送（APScheduler 后端触发） | 🔴 高 |
| 价格警报通知（Watchlist alertPrice 触发） | 🟡 中 |
| 通知点击跳转相关股票详情页 | 🟡 中 |

#### Day 2：Portfolio Performance Review（7 子模块）
| 子模块 | 优先级 |
|--------|--------|
| 1. Allocation Overview（持仓分布饼图） | 🔴 高 |
| 2. Return Analysis（累计收益 vs HSI 对比折线图） | 🔴 高 |
| 3. Trade Journal Stats（胜率/均盈/均亏/Profit Factor） | 🔴 高 |
| 4. Risk Metrics（波动率/最大回撤/夏普比率） | 🟡 中 |
| 5. Sector Exposure（行业暴露度热力图） | 🟡 中 |
| 6. Top Performers（最佳/最差持仓排名） | 🟡 中 |
| 7. Monthly P&L Heatmap（月度盈亏热力图） | 🟢 低 |

---

### 🔜 Sprint 4：打包 & 真机测试（计划：2026-04-02 ~ 04-03，约 1 天）

**目标：** 生成可安装 APK，完成真机验收

| 任务 | 优先级 | 备注 |
|------|--------|------|
| NewsAPI 财经新闻集成 | 🟡 中 | 可选，MVP 后再做 |
| CSV 交易记录导出 | 🟡 中 | — |
| 弱网/断网降级处理 + 本地缓存 | 🟡 中 | — |
| **`flutter build apk --debug`（Debug APK）** | 🔴 高 | **Option A 第一步** |
| **真机安装测试**（需用户配合）| 🔴 高 | 开启"未知来源"安装 |
| 真机功能验收（5 页面 + 个股详情）| 🔴 高 | 用户执行 |
| 性能调优（如有 UI 卡顿） | 🟡 中 | — |

> ⭐ **Option A 里程碑（APK 直接分发）**：Sprint 4 末，约 **2026-04-03**，生成 release APK，直接发送给用户安装，无需 Google Play。

---

### 🔜 Sprint 5：Google Play 上架（计划：2026-04-04 ~ 04-22，约 2 周）

**目标：** App 签名 → Release 构建 → Google Play 提交 → 审核通过

#### 技术准备（约 1 天，AI 可完成）
| 任务 | 优先级 | 备注 |
|------|--------|------|
| 创建 Keystore 密钥文件 | 🔴 高 | `keytool -genkey` |
| `key.properties` 配置签名 | 🔴 高 | — |
| `build.gradle` 集成签名配置 | 🔴 高 | — |
| `flutter build appbundle --release`（AAB 格式）| 🔴 高 | Play Store 要求 AAB |
| App 图标生成（各尺寸）| 🔴 高 | `flutter_launcher_icons` |
| 启动屏设计 | 🟡 中 | — |
| Firebase Crashlytics 集成 | 🟢 低 | 可选 |
| 性能优化（K 线分页加载、懒加载）| 🟡 中 | — |

#### 需用户完成的步骤（不可由 AI 代劳）
| 任务 | 预计用时 | 说明 |
|------|----------|------|
| 注册 Google Play 开发者账号 | 30 分钟 | 一次性费用 $25 USD，需信用卡 |
| 在 Play Console 创建应用 | 30 分钟 | 填写 App 基本信息 |
| 上传 AAB 文件 | 15 分钟 | 由 AI 构建后交给用户上传 |
| 填写商店信息（描述/截图/评级）| 1–2 小时 | 需要准备截图素材（AI 可辅助文案）|
| 提交内部测试 → 正式审核 | 15 分钟操作 | — |
| **Google 审核等待** | **7–14 个工作日** | 首次提交通常较长 |

> ⭐ **Option B 里程碑（Google Play 上架）**：预计提交日期 **2026-04-08**，审核通过约 **2026-04-15 ~ 04-22**。

---

## 5. 双轨发布时间轴对比

```
今天 (04-01)
│
├─ Sprint 3 ──────────── 04-01 ~ 04-02（AI 执行，约 1-2 天）
│   k_chart + 推送 + Performance Review
│
├─ Sprint 4 ──────────── 04-02 ~ 04-03（AI + 用户真机测试）
│   Debug APK + 真机验收
│
│  ┌──── Option A（APK 直发）────────────────────────────┐
│  │  04-03：Release APK 生成，发送安装文件               │  ✅ 约 3 天后
│  └────────────────────────────────────────────────────┘
│
├─ Sprint 5 ──────────── 04-04 ~ 04-07（AI 执行，约 3-4 天）
│   签名 + AAB 构建 + 图标 + 商店素材
│
│  ┌──── Option B（Google Play）────────────────────────┐
│  │  04-08：用户提交 Play Console                        │
│  │  04-08 ~ 04-22：Google 审核（7-14 工作日）           │  ⏳ 约 3 周后
│  │  04-15 ~ 04-22：上架 Google Play ✅                  │
│  └────────────────────────────────────────────────────┘
```

---

## 6. 里程碑（更新版）

| 里程碑 | 计划时间 | 实际时间 | 状态 | 验收标准 |
|--------|----------|----------|------|----------|
| M1 - 需求确认 | 第 1 天 | 2026-03-29 | ✅ 完成 | 需求文档 v1.1 定稿 |
| M2 - 环境搭建 | 第 2-3 天 | 2026-03-31 | ✅ 完成 | Flutter + FastAPI 均可运行 |
| M3 - 后端 API MVP | 第 3 天 | 2026-03-31 | ✅ 完成 | 全部核心端点可调用 |
| M4 - 前端 MVP | 第 3-4 天 | 2026-04-01 | ✅ 完成 | 5 页面真实数据运行 |
| M5 - 高级功能 | 第 4-5 天 | ~2026-04-02 | 🔜 Sprint 3 | K 线图 + 推送 + Perf. Review |
| M6 - Debug APK | 第 5-6 天 | ~2026-04-03 | ⏳ Sprint 4 | 真机可安装运行 |
| **M7A - APK 直发** | **第 6 天** | **~2026-04-03** | ⏳ Option A | Release APK 文件生成 |
| M7B - AAB + 签名 | 第 7-10 天 | ~2026-04-07 | ⏳ Sprint 5 | AAB 文件生成，签名完整 |
| **M8B - Play 提交** | **第 10 天** | **~2026-04-08** | ⏳ Option B | Play Console 提交成功 |
| **M9B - Play 上架** | **第 17-24 天** | **~2026-04-22** | ⏳ Option B | Google Play 上架通过 |

---

## 7. 技术栈（实际采用）

| 层级 | 技术 | 版本 | 用途 |
|------|------|------|------|
| 前端框架 | Flutter | 3.41.6 | Android App |
| 前端状态管理 | Riverpod | ^2.x | 状态管理 + 数据缓存 |
| 前端 K 线图 | k_chart（Sprint 3） | 最新 | 专业蜡烛图 |
| 前端本地存储 | sqflite（Sprint 4） | 最新 | 本地持久化 |
| 前端推送 | flutter_local_notifications（Sprint 3） | 最新 | 本地通知 |
| 前端图标 | flutter_launcher_icons（Sprint 5） | 最新 | 各尺寸图标生成 |
| 后端 | Python FastAPI | 0.115.x | REST API 服务 |
| 后端数据 | yfinance | 最新 | 港股行情数据 |
| 后端任务调度 | APScheduler | 3.x | 定时推送任务 |
| 数据库 | SQLite（hkstock.db） | — | 本地数据持久化 |
| 运行时 | Python 3.14.3 | managed | 后端运行环境 |
| 版本控制 | Git + GitHub | — | `jflinda/hk-stock-app`（Private） |
| 发布（Option A） | Release APK | — | 直接分发安装 |
| 发布（Option B） | AAB + Keystore | — | Google Play 上架 |

---

## 8. 已知技术问题 & 踩坑记录

| 问题 | 解决方案 | 状态 |
|------|----------|------|
| yfinance `dividendYield` 已是百分比，不需 ×100 | 已移除乘法 | ✅ 已修复 |
| 52W 高低需用 `history(period="1y")` 单独获取 | 已分开请求 | ✅ 已修复 |
| `ref.refresh()` 返回 Future，产生 unused_result 警告 | 改用 `ref.invalidate()` | ✅ 已修复 |
| uvicorn 重启需先 `Stop-Process` 清理旧进程 | 每次重启前执行 | 📝 已记录 |
| Flutter `late final` 不能用于构造函数可选参数 | 去掉 `late final` | ✅ 已修复 |
| k_chart 包 Flutter 3.x 兼容性未验证 | Sprint 3 开始前 POC 验证 | ⏳ 待验证 |
| Android 13+ 推送通知需运行时权限 | Sprint 3 实现时处理 | ⏳ 待处理 |
| Google Play 首次审核通常较慢（7-14 天）| 双轨方案，Option A 不受影响 | 📝 已规划 |

---

## 9. 风险管理

| 风险 | 可能性 | 影响 | 应对措施 |
|------|--------|------|----------|
| yfinance API 不稳定 | 中 | 高 | 已有多项修复经验；备选 Alpha Vantage |
| k_chart 与 Flutter 3.41.6 不兼容 | 低 | 中 | Sprint 3 先做 POC；如不兼容改用 `fl_chart` |
| Google Play 审核被拒 | 低 | 低 | Option A APK 直发不受影响，可独立完成 |
| Google Play 审核超 14 天 | 中 | 低 | Option A 已经交付，不影响用户使用 |
| 真机测试发现严重 UI 问题 | 低 | 中 | Sprint 4 留有 buffer；AI 可快速修复 |
| Android 13+ 通知权限被拒绝 | 中 | 中 | 应用内引导用户手动开启 |

---

## 10. 关键路径

```
Sprint 3：k_chart + 推送 + Performance Review
    ↓
Sprint 4：真机 Debug APK 测试
    ↓ ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
    ↓                                         │
Option A：Release APK 打包               Option B：AAB + 签名 + Play 提交
（约 04-03，AI 完成，用户直接安装）       （约 04-08 提交，04-15~22 上架）
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
| `6561137` | 2026-04-01 | docs: 项目计划升级至 v2.0 |

---

## 12. 成功标准

用户最终应可以：
- ✅ 查看港股大盘指数及个股实时（延迟）行情
- ✅ 管理自选股列表（添加/删除/筛选）
- ✅ 记录每笔买卖，查看持仓盈亏
- 🔜 查看专业蜡烛图及技术指标（Sprint 3）
- 🔜 每日收市后收到行情推送摘要（Sprint 3）
- 🔜 查看 Portfolio Performance Review（Sprint 3）
- ⏳ 在 Android 手机上安装并启动 App（Sprint 4）
- ⭐ **[Option A]** 通过 APK 直接安装（Sprint 4 末，~04-03）
- ⭐ **[Option B]** 在 Google Play 搜索并下载（Sprint 5 末，~04-22）

---

## 13. 项目文件夹结构（实际）

```
stocktrading/
├── 01_User_Requirements.md / .docx
├── 02_Resources_TechStack.md / .docx
├── 03_Project_Plan.md / .docx         ← 本文档 v3.0
├── 04_Pre_Coding_Checklist.md
├── 05_Setup_Guide.md
├── portfolio_prototype.html
├── HK_StockApp_Protocol_v2.0.zip
├── backend/
│   ├── main.py
│   ├── routers/ (market / stocks / watchlist / trades / portfolio)
│   ├── services/market_service.py
│   ├── database/init_db.py
│   ├── hkstock.db
│   └── run_api.bat
└── frontend/
    ├── lib/
    │   ├── main.dart
    │   ├── constants/app_constants.dart
    │   ├── models/ (6 models + .g.dart)
    │   ├── providers/ (4 provider files)
    │   ├── services/api_service.dart
    │   ├── screens/ (market / portfolio / watchlist / stock_detail / tools / settings)
    │   └── widgets/
    ├── android/
    └── pubspec.yaml
```
