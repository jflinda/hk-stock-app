# 🎯 港股投资分析 App - 测试指南

**用户：Linda Wong**  
**日期：2026-04-01**  
**状态：Portfolio页面已准备好测试**

---

## ✅ 当前已完成

### 1. 后端API服务
- ✅ **FastAPI服务器**：运行在 `http://localhost:8000`
- ✅ **数据库**：SQLite数据库已初始化（`hkstock.db`）
- ✅ **测试数据**：12个测试交易 + 10个自选股已添加
- ✅ **API文档**：`http://localhost:8000/docs`（自动生成）

### 2. Flutter应用
- ✅ **Portfolio页面**：完整实现（基于HTML原型设计）
- ✅ **数据连接**：已配置真实API（非mock模式）
- ✅ **状态管理**：Riverpod providers已配置
- ✅ **APK文件**：已安装在手机上（`com.jflin.hk_stock_app`）

### 3. 核心功能
- ✅ **持仓显示**：基于真实交易计算
- ✅ **交易记录**：Journal tab，支持滑动删除
- ✅ **业绩分析**：7个子模块的Performance Review
- ✅ **添加交易**：Modal表单（BUY/SELL）

---

## 📱 手机测试流程

### 当你回来后（重新连接手机）：

#### 步骤1：检查后端API
```
# 确保后端正在运行
python -m uvicorn main:app --reload --port 8000
# 或使用我们已创建的启动脚本
run_api.bat
```

#### 步骤2：启动Flutter应用
```
cd frontend
flutter run
```

#### 步骤3：在手机上查看
1. **应用会自动启动**（如果已连接调试）
2. **Portfolio页面**会显示真实数据
3. **查看持仓**：基于测试交易计算
4. **测试添加交易**：点击"Add Trade"按钮

---

## 📊 测试数据详情

### 持仓组合（Linda Wong的测试账户）
| 股票 | 代码 | 股数 | 平均成本 | 当前价格 | 浮动盈亏 |
|------|------|------|----------|----------|----------|
| 腾讯控股 | 0700 | 250 | 约244.70 | 245.80 | +0.45% |
| 阿里巴巴 | 9988 | 500 | 约121.29 | 123.45 | +1.78% |
| 美团 | 3690 | 150 | 456.78 | 456.78 | 0.00% |
| 汇丰控股 | 0005 | 600 | 约236.34 | 234.56 | -0.75% |
| 安踏体育 | 2020 | 500 | 12.34 | 12.34 | 0.00% |
| 小米集团 | 1810 | 800 | 89.23 | 89.23 | 0.00% |
| 中国平安 | 2382 | 300 | 45.67 | 45.67 | 0.00% |
| 香港交易所 | 0388 | 100 | 345.67 | 345.67 | 0.00% |

### 预期看到的Portfolio数据
- **总投资额**：约 HKD 285,000
- **当前市值**：实时获取（yfinance API）
- **浮动盈亏**：基于实时价格计算
- **持仓数量**：8支股票

---

## 🔧 测试要点

### 功能测试
1. **Portfolio Summary**：检查总价值、P&L计算是否正确
2. **Position Cards**：检查持仓卡片显示（进度条、盈亏）
3. **Journal Tab**：滑动删除交易记录
4. **Performance Tab**：7个子模块的数据展示
5. **Add Trade Modal**：添加新交易，观察实时更新

### 数据流测试
1. **后端→前端**：确保API调用成功
2. **实时价格**：检查yfinance数据获取
3. **本地存储**：SQLite数据库操作
4. **状态更新**：Riverpod providers的响应性

### UI/UX测试
1. **深色主题**：检查所有UI组件
2. **响应式布局**：不同屏幕尺寸适配
3. **加载状态**：网络请求时的loading显示
4. **错误处理**：网络断开时的降级处理

---

## 🐛 已知问题与解决方案

### 问题1：API连接失败
```
症状：Portfolio页面显示"无法连接到服务器"
解决方案：
1. 检查后端是否运行：netstat -an | findstr :8000
2. 重启后端：Stop-Process -Name python; 然后重新启动
3. 检查防火墙：确保8000端口开放
```

### 问题2：实时价格获取失败
```
症状：价格显示"---"或旧数据
解决方案：
1. 检查网络连接
2. 检查yfinance库是否正常工作
3. 等待30秒自动刷新
```

### 问题3：手机无法识别
```
症状：flutter run 找不到设备
解决方案：
1. 重新插拔USB线
2. 手机开启USB调试
3. 运行：adb devices
```

---

## 🚀 下一步开发计划

### 短期（今天）
1. **修复任何测试发现的问题**
2. **完善Market页面**（基于HTML原型）
3. **完善Watchlist页面**（添加/删除功能）

### 中期（本周）
1. **实现Tools页面**（计算器、筛选器）
2. **实现Settings页面**（主题、语言切换）
3. **K线图集成**（k_chart包）

### 长期（下周）
1. **推送通知**（价格提醒）
2. **CSV导出**（交易记录）
3. **APK发布**（Google Play准备）

---

## 📞 技术支持

### 快速诊断命令
```bash
# 检查后端
curl http://localhost:8000/ping

# 检查数据库
python backend/add_test_data.py

# 检查Flutter
cd frontend && flutter doctor

# 检查设备
adb devices
```

### 关键文件位置
```
后端API：stocktrading\backend\main.py
数据库：stocktrading\backend\database\hkstock.db
Flutter入口：stocktrading\frontend\lib\main.dart
Portfolio页面：stocktrading\frontend\lib\screens\portfolio\portfolio_screen.dart
```

---

## 🎉 恭喜！

现在你有一个**功能完整的Portfolio页面**，可以：
1. 显示真实的持仓数据
2. 管理交易记录
3. 查看业绩分析
4. 添加新交易

**今晚你就能在手机上测试核心功能！** 等你回来重新连接手机，我们就能看到完整的应用运行效果。

---

*最后更新：2026-04-01*  
*测试状态：✅ 准备就绪*