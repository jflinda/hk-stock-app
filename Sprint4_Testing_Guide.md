# Sprint 4 & 5 Testing Guide — HK Stock App

**Updated: 2026-04-02**

---

## Current Build Status

| Build | File | Size | Status |
|-------|------|------|--------|
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` | ~142MB | ✅ Ready |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` | ~52MB | ✅ Signed |
| Release AAB | `build/app/outputs/bundle/release/app-release.aab` | ~42MB | ✅ Play Store ready |

**Code Quality:** `flutter analyze` → **No issues found** (0 errors, 0 warnings)

---

## Prerequisites

### 1. Start the Backend API Server

The Flutter app connects to the backend at `http://192.168.3.30:8001`.
Make sure you're on the same WiFi network as your PC.

```
# From the stocktrading/ directory:
python launch_api.py
```

Or verify it's running:
```
netstat -ano | findstr 8001
```

### 2. Confirm API is Working

Open browser: http://localhost:8001/docs

All endpoints should respond. Key endpoints:
- `GET /ping` → `{"status": "ok"}`
- `GET /api/portfolio/summary` → portfolio data
- `GET /api/market/indices` → HSI/HSCEI/etc.

---

## Phone Testing — Install APK

### Option A: USB (ADB)

1. Enable Developer Options on Android:
   - Settings → About Phone → tap "Build Number" 7 times
2. Enable USB Debugging in Developer Options
3. Connect phone via USB
4. Accept "Allow USB Debugging" on phone
5. Verify connection:
   ```
   adb devices
   # Should show: XXXXXXXX   device
   ```
6. Install:
   ```
   adb install -r "frontend\build\app\outputs\flutter-apk\app-release.apk"
   ```

### Option B: Direct Transfer

1. Copy `app-release.apk` to your phone (via email/WeTransfer/USB)
2. On phone: Settings → Security → Allow install from unknown sources
3. Open the APK file on your phone to install

---

## Test Checklist (Sprint 4)

### Portfolio Screen
- [ ] Summary card shows totalValue, P&L, ROI
- [ ] Positions tab: list of holdings with P&L per position
- [ ] Journal tab: list of all trades, swipe left to delete
- [ ] Performance tab: 7 sub-modules visible (Overview, Monthly Returns, etc.)
- [ ] FAB (+) → Add Trade modal opens
- [ ] BUY/SELL toggle, ticker/price/qty fields work
- [ ] Submit trade → appears in journal

### Market Screen
- [ ] Index strip: HSI / HSCEI / HSTI / S&P500 / SSE with prices
- [ ] Sectors tab: sector cards with color coding (red=up, green=down)
- [ ] Movers tab: Top Gainers / Losers / Turnover lists
- [ ] Pull-to-refresh works

### Stock Detail
- [ ] Tap any stock → opens detail page
- [ ] Price hero with change %
- [ ] K-line candlestick chart renders (OHLC + volume + MA lines)
- [ ] 1D / 5D / 1M / 3M / 1Y period switching
- [ ] Key Stats: P/E, Market Cap, 52W range, etc.
- [ ] My Position section shows if in portfolio
- [ ] BUY/SELL quick buttons open Add Trade modal

### Watchlist Screen
- [ ] List of watched stocks with prices
- [ ] Filter chips: All / Gainers / Losers / Alerts
- [ ] FAB (+) → Add Watchlist modal
- [ ] Search by ticker code
- [ ] Quick Add chips work
- [ ] Swipe / X button removes stock

### Tools Screen
- [ ] Position Sizer: fill in portfolio value, risk %, entry/stop → calculates shares
- [ ] P&L Calculator: buy/sell price, qty → net P&L
- [ ] Currency Converter: HKD↔USD↔CNY etc.
- [ ] Quick Screener: filter by sector / PE / yield

### Settings Screen
- [ ] Language toggle (EN / 繁中)
- [ ] Dark mode toggle
- [ ] Notification toggles
- [ ] Export CSV → downloads/opens CSV file
- [ ] Clear data → shows confirmation dialog

---

## Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| "Connection refused" | Backend not running | Run `python launch_api.py` |
| "Network error" | Different WiFi subnet | Ensure phone & PC on same WiFi |
| Charts not showing | No data returned | Check `/api/stock/0700.HK/history` endpoint |
| App crashes on launch | Old APK cached | Uninstall old APK first, then install new one |
| Watchlist empty | DB not seeded | Run `python seed_data.py` |

---

## Sprint 5 — Google Play Store Submission

### Files Needed
- `frontend/android/app/hkstock-release.jks` — signing keystore ✅ exists
- `frontend/android/key.properties` — signing credentials ✅ exists
- `build/app/outputs/bundle/release/app-release.aab` — upload to Play Console ✅ built

### Steps
1. Create Google Play Developer Account (one-time $25 fee)
   - https://play.google.com/console
2. Create new app: "HK Stock Tracker"
3. Upload `app-release.aab` to Internal Testing track
4. Fill in store listing (description, screenshots, icon)
5. Set up content rating questionnaire
6. Submit for review (~3-5 business days)

### Store Listing Assets Needed
- App icon: 512×512 px PNG
- Feature graphic: 1024×500 px PNG
- Screenshots: min 2, max 8 (phone screenshots)
- Short description: ≤80 chars
- Full description: ≤4000 chars

---

## API Base URL Configuration

The app is configured for **local network testing**:
```dart
// lib/services/api_service.dart
static const String baseUrl = 'http://192.168.3.30:8001/api';
```

For production release, this should point to a deployed cloud server.
Current setup: PC acts as server, phone connects via local WiFi.

---

## Git Repository

- **GitHub:** https://github.com/jflinda/hk-stock-app (Private)
- **Latest commit:** See below after today's push
- **Branch:** main
