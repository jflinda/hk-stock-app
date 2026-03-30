# 港股 App — 开发准备：分工清单与手动操作指南
**版本：** v2.0（已自动完成部分已标注）  
**日期：** 2026-03-30  
**更新：** 基于实际电脑环境扫描后的真实状态

---

## 一、当前电脑环境（已扫描）

| 工具 | 状态 | 备注 |
|------|------|------|
| Python 3.8 | ✅ 已有（系统）| 版本旧，不用于本项目 |
| **Python 3.14.3** | ✅ **已自动安装** | 路径见下 |
| yfinance | ✅ **已自动安装** | 验证通过，腾讯 HKD 481.60 |
| FastAPI + uvicorn | ✅ **已自动安装** | 验证通过 |
| pandas | ✅ **已自动安装** | v3.0.1 |
| APScheduler | ✅ **已自动安装** | 定时推送用 |
| Git | ❌ 未安装 | **需要你手动安装** |
| Flutter SDK | ❌ 未安装 | **需要你手动安装** |
| Android Studio | ❌ 未安装 | **需要你手动安装** |
| SQLite 数据库 | ✅ **已自动创建** | `backend/database/hkstock.db` |
| 后端骨架代码 | ✅ **已自动创建** | `backend/` 目录，含5个API模块 |
| 项目目录结构 | ✅ **已自动创建** | backend + frontend 骨架均已建好 |

**Python 路径（重要，后续启动 API 用这个）：**
```
C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe
```

---

## 二、技术决策（已替你做完，理由附后）

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 状态管理 | **Riverpod 2.x** | 比 Bloc 更简单，适合没有技术背景的维护；官方推荐；社区活跃 |
| K 线图组件 | **k_chart** | 专为股票设计，支持蜡烛图/折线/成交量/MA 一体；免费开源 |
| 本地存储 | **sqflite（SQLite）** | 已选定；交易记录需要关系型查询；不需要额外账号或云服务 |
| 数据刷新频率 | **每 30 秒** | 延迟报价场景够用；减少 API 调用；省电省流量 |
| 推送方式 | **本地推送（flutter_local_notifications）** | 不需要 Firebase 账号/服务器；数据不经过第三方；安全且免费 |
| 后端运行 | **本机运行（localhost）** | 开发阶段免费；数据不上云；手机与电脑同一 WiFi 即可访问 |
| 技术指标计算 | **pandas rolling（内置）** | pandas-ta 与 Python 3.14 不兼容；手写 rolling 更稳定，已验证 |
| 港股手数单位 | **以"股"记录，UI 显示"手"** | 不同股票每手股数不同（100/500/1000/2000），后端统一用"股"最灵活 |
| 数据来源 | **yfinance（Yahoo Finance）** | 免费；港股覆盖全；已验证可正常获取延迟数据 |
| 新闻来源 | **NewsAPI（MVP 暂缓）** | 免费 100 次/天够开发用；App 完成核心功能后再接入 |

---

## 三、分工一览表

### ✅ 我已经完成的

| 已完成项目 | 说明 |
|-----------|------|
| Python 3.14.3 安装 | 含 yfinance / FastAPI / pandas / APScheduler |
| 数据源验证 | yfinance 实时数据测试通过（腾讯、恒生指数、国企指数） |
| 后端骨架代码 | `backend/main.py` + 5 个 API 模块（market/stocks/watchlist/trades/portfolio） |
| SQLite 数据库初始化 | 4 张表已创建（trades/watchlist/price_cache/stock_info_cache） |
| 项目目录结构 | backend + frontend 骨架目录均已建好 |
| .gitignore | 已配置，防止敏感文件被上传 |
| README.md | 项目说明文档已创建 |
| 需求/技术栈/计划文档 | v1.1 已定稿 |
| UI 原型 | portfolio_prototype.html 全部 6 个页面已完成 |

---

### 🙋 需要你手动完成的（4 件事，按顺序）

---

#### 🔴 手动任务 1：安装 Git（版本控制工具）

**为什么必须你做：** Git 是系统级安装程序，需要管理员权限点击安装，AI 无法操作 Windows 图形安装程序。

**步骤（约 5 分钟）：**

1. 打开浏览器，访问：**https://git-scm.com/download/win**
2. 页面会自动开始下载 `Git-x.x.x-64-bit.exe`（约 50MB）
3. 打开下载的安装程序，点击 **Next** 一路默认，直到 **Install**，不需要改任何选项
4. 安装完成后，打开「开始菜单」→ 搜索「PowerShell」→ 右键「以管理员身份运行」
5. 输入以下命令验证：
   ```
   git --version
   ```
   看到 `git version 2.x.x.windows.x` 即成功

6. 设置你的 Git 身份（只需做一次）：
   ```
   git config --global user.name "你的名字"
   git config --global user.email "你的邮箱"
   ```

✅ 完成后告诉我，我会帮你把项目初始化为 Git 仓库。

---

#### 🔴 手动任务 2：注册 GitHub 账号

**为什么必须你做：** 账号注册需要真实邮箱验证，属于个人身份行为。

**步骤（约 5 分钟）：**

1. 打开浏览器，访问：**https://github.com**
2. 点击右上角 **Sign up**
3. 填写邮箱、设置密码（建议用强密码管理器生成）、用户名
4. 完成邮箱验证
5. 选择免费计划（Free），不需要付费

> **安全提示：** GitHub 免费账号的私有仓库（Private repository）完全免费，你的代码不会被任何人看到。我们会把仓库设为 **Private**。

✅ 完成后把你的 GitHub 用户名告诉我，我会帮你生成 GitHub 的 README 和上传配置。

---

#### 🔴 手动任务 3：安装 Flutter SDK + Android Studio

**为什么必须你做：** 这两个需要图形界面安装，且 Android Studio 需要下载 Android SDK（约 2GB），必须人工操作。

**步骤（约 30-60 分钟，主要是下载时间）：**

**第一步：安装 Android Studio（先装这个）**

1. 访问：**https://developer.android.com/studio**
2. 点击 **Download Android Studio**（约 1GB）
3. 安装程序打开后，全部默认选项，点 Next → Install
4. 首次启动会出现「Android SDK Setup」向导，选择 **Standard** 安装，点 Next → Finish
   - 这一步会自动下载 Android SDK（约 1GB，需等待）
5. 安装完成后，在 Android Studio 顶部菜单：**Tools → Device Manager**
6. 点击 **Create Virtual Device** → 选 **Pixel 6** → 选系统镜像 **API 33（Android 13）** → Finish
   - 这会创建一个手机模拟器，用于测试 App

**第二步：安装 Flutter SDK**

1. 访问：**https://flutter.dev/docs/get-started/install/windows**
2. 点击页面上的蓝色下载按钮，下载 `flutter_windows_x.x.x-stable.zip`（约 1GB）
3. 解压到 `C:\flutter`（注意：路径里不要有空格，不要放在 C:\Program Files）
4. 把 Flutter 加入系统环境变量 PATH：
   - 按 `Win + S` 搜索「编辑系统环境变量」
   - 点「环境变量」→ 在「系统变量」里找到 `Path` → 双击
   - 点「新建」→ 输入 `C:\flutter\bin`
   - 点确定 → 确定 → 确定
5. 打开新的 PowerShell 窗口，输入：
   ```
   flutter doctor
   ```
   第一次会检查各项配置，按提示修复红色 ✗ 项目，直到大部分是绿色 ✓
   
   > 常见问题：如果出现「Android licenses not accepted」，运行：`flutter doctor --android-licenses` 然后全部输入 `y` 回车

✅ 完成后告诉我，我会立即帮你用 Flutter 创建 App 项目骨架并写第一个页面。

---

#### 🟡 手动任务 4：申请 API Keys（可选，MVP 阶段不需要）

以下两个 API 在 MVP（最小可用版本）阶段**不需要**，可以等 App 核心功能完成后再做：

**Alpha Vantage（备用股票数据，yfinance 出问题时用）：**
1. 访问：https://www.alphavantage.co/support/#api-key
2. 填邮箱 → 免费领取 API Key
3. 记录 Key，到时告诉我，我帮你配置到后端

**NewsAPI（财经新闻）：**
1. 访问：https://newsapi.org/register
2. 填邮箱注册 → 免费 Key（100 次/天）
3. 记录 Key，到时告诉我，我帮你加到新闻接口里

---

## 四、什么时候可以开始写代码？

**答：任务 3 完成后就可以。**

具体来说，有两条并行路径：

### 路径 A：后端（你现在就可以开始）
后端的 Python 代码**我已经写好了骨架**，你只需要启动它：

```powershell
# 在 PowerShell 里运行：
$py = "C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe"
cd "c:\Users\jflin\WorkBuddy\20260329125422\stocktrading\backend"
& $py -m uvicorn main:app --reload --port 8000
```

然后打开浏览器访问 **http://localhost:8000/docs** 就能看到所有 API 接口可以测试。

> **这个你现在就能做，不需要等 Flutter。**

### 路径 B：前端 Flutter App（等任务 3 完成）
Flutter 安装完成后，我会立刻帮你：
1. `flutter create frontend` 创建 App 项目
2. 配置主题色、底部导航栏、5个主页面框架
3. 第一个真实页面：Market 页面（接真实 yfinance 数据）

### 开始编码的完整前置条件检查清单

| 条件 | 状态 |
|------|------|
| Python 3.14 + 依赖已安装 | ✅ 完成 |
| yfinance 数据验证通过 | ✅ 完成 |
| FastAPI 后端骨架已创建 | ✅ 完成 |
| SQLite 数据库已初始化 | ✅ 完成 |
| Git 安装 | ❌ 等你手动完成（任务1）|
| GitHub 账号 | ❌ 等你手动完成（任务2）|
| Flutter + Android Studio | ❌ 等你手动完成（任务3）|

**结论：前端从任务3完成即可开始；后端今天就能开始。**

---

## 五、启动后端 API 的方法（你现在可以试）

打开 PowerShell，复制粘贴以下命令：

```powershell
$py = "C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe"
cd "c:\Users\jflin\WorkBuddy\20260329125422\stocktrading\backend"
& $py -m uvicorn main:app --reload --port 8000
```

然后在浏览器打开：
- **http://localhost:8000/ping** → 测试 API 是否运行
- **http://localhost:8000/docs** → 完整 API 文档（可直接在网页里测试每个接口）

---

*更新：2026-03-30 | 下一步：等你完成任务1-3 后，继续 Flutter 前端开发*
