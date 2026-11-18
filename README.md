# 记账本 · Pocket Book

一句话记账的 Android 记账 App，用 Flutter 写的。打开就是输入框，打一行「炒饭10 奶茶5」回车就记完；首页显示今日已花和今天还能花多少，额度按月预算自动摊到每天，超支就变红。数据只存在手机本地，不联网、不需要账号。

## 功能

- **一句话批量记账**：空格、中英文逗号、顿号、分号、换行都能分隔，金额写在名称前后都行，纯数字记为「未命名」
- **今日额度**：每月预算 ÷ 当月天数，实时算出今日剩余，超支标红
- **账单页**：按日期查看每天记录与当天合计，颜色条显示花费高低，可往历史日期补记
- **本地存储**：sqflite 单机数据库，没有账号、没有网络请求
- **主题**：浅色 / 深色 / 跟随系统

## 技术

Flutter 3（Dart），sqflite 本地数据库，输入解析器自己写。

```
lib/
├── main.dart          入口、主题模式
├── parser.dart        一句话输入解析（「炒饭10 奶茶5」→ 两条记录）
├── models.dart        Entry / ParseItem
├── db.dart            sqflite 存取
├── app_state.dart     预算、当日统计、状态通知
├── theme.dart         浅色 / 深色配色
└── pages/
    ├── today_page.dart     今日：输入、今日已花 / 剩余、列表
    ├── bills_page.dart     账单：按日查看、热度条、本月合计、补记
    └── settings_page.dart  设置：每月预算、主题
```

## 运行

```bash
flutter pub get
flutter run          # 连真机或模拟器
flutter test         # 布局 / 解析相关单测
```

## 其他文件

- `记账App-完整原型.html`：动手写 Flutter 之前的 HTML 原型，先跑通交互再实现
- `demo/`：原型演示视频（横屏 / 竖屏）、渲染与截图脚本

---

# Pocket Book (English)

A minimalist Android expense tracker built with Flutter. Open the app and you're already at the input box: type `炒饭10 奶茶5` (fried-rice 10, milk-tea 5) and both entries are recorded. The home screen shows today's spending and how much is left for today, derived from a monthly budget split across the days of the month — overspend turns red. Everything stays in a local SQLite database: no account, no network.

## Features

- **One-line batch entry** — split items by spaces, commas, enumeration marks or newlines; the amount can come before or after the name
- **Daily allowance** — monthly budget ÷ days in month, recalculated live, red when overspent
- **Bills view** — per-day records and totals, a heat bar for daily spending, back-dated entries
- **Local only** — sqflite on device, no accounts, no network calls
- **Themes** — light, dark, follow system

## Tech

Flutter 3 (Dart), sqflite, and a hand-written input parser. Structure: `lib/parser.dart` (text → entries), `lib/db.dart` (storage), `lib/app_state.dart` (budget & daily stats), `lib/pages/` (three screens). Tests in `test/layout_test.dart`.

```bash
flutter pub get
flutter run
flutter test
```

`记账App-完整原型.html` is the HTML prototype built before the Flutter implementation, and `demo/` holds the prototype screen recordings.