# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

健康管理アプリ — Flutterで勤務時間・睡眠時間を管理するAndroidアプリ。

**2画面構成:**
- **登録画面** (`registration_screen.dart`): イベント種別ドロップダウン + 日時選択 + 登録ボタン → Roomに保存
- **実績画面** (`results_screen.dart`): 日付選択 + 当日の実績テーブル（睡眠/労働/昼寝/中途覚醒）

**イベント種別:** 起床, 就寝, 出勤, 退勤, 昼寝開始, 昼寝終了, 中途覚醒開始, 中途覚醒終了

## Build Commands

```bash
# 依存関係インストール
flutter pub get

# 静的解析
flutter analyze

# デバッグビルド & 実行
flutter run

# APKビルド
flutter build apk

# ユニットテスト
flutter test

# 単一テストファイル実行
flutter test test/widget_test.dart
```

## Architecture

**MVVM with Provider:**
```
lib/
├── main.dart                          # アプリエントリ、テーマ、MultiProvider、BottomNavigation
├── models/health_record.dart          # HealthRecord エンティティ + EventType 定数
├── database/database_helper.dart      # SQLite (sqflite) ヘルパー、シングルトン
├── viewmodels/
│   ├── registration_viewmodel.dart    # 登録フォームの状態管理
│   └── results_viewmodel.dart        # 実績データ取得・テーブル行生成ロジック
└── screens/
    ├── registration_screen.dart       # 登録UI
    └── results_screen.dart           # 実績テーブルUI
```

**Provider の配置:** `RegistrationViewModel` と `ResultsViewModel` は `_HomeScreen` レベルで `MultiProvider` 提供。実績タブ切替時・リフレッシュボタンで `ResultsViewModel.loadRecords()` を呼ぶ。

**実績テーブル行生成ロジック** (`ResultsViewModel._computeRows`):
- 睡眠: 就寝時刻 → 起床時刻（各1レコード）
- 労働: 出勤時刻 → 退勤時刻（各1レコード）
- 昼寝/中途覚醒: 開始・終了をインデックス順にペアリング、データなしでも1行表示

## Tech Stack

- **Flutter** 3.41.6 / **Dart** 3.11.4
- **sqflite** — ローカルDB（`healthcheck.db`）
- **provider** — 状態管理
- **path** — DBパス解決

## Design

- **minSdk:** API 34（Android 14）
- **背景:** `Color(0xFF1E1E1E)`（濃いグレー）
- **主色:** `Color(0xFF4CAF50)`（グリーン）
- **サーフェス:** `Color(0xFF2A2A2A)`
