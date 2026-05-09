# 🌼 智能便签 Smart Note AI

<p align="center">
  <img src="assets/icon/app_icon.png" width="132" alt="Smart Note AI 应用图标" />
</p>

<p align="center">
  <strong>📝 一款便签风格的智能任务与笔记应用</strong>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-跨平台-54C5F8?style=for-the-badge&logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-应用开发-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img alt="Version" src="https://img.shields.io/badge/版本-v1.0.0-FFE88A?style=for-the-badge" />
</p>

---

## ✨ 项目简介

🌟 **智能便签** 是一个基于 Flutter 构建的跨平台应用原型，主打手账便签风格、轻量任务管理和 AI 辅助生成。

🎯 应用包含便签增删改查、完成状态、提醒时间、归档、回收站、服务商配置、本地持久化和智能计划生成等能力。

🚀 这个项目适合作为移动端 Flutter 应用、AI 工具接入、本地数据管理和便签类产品设计的参考。

---

## 🎨 功能亮点

- 🧩 **便签墙**：创建、编辑、删除、归档、标签筛选、固定尺寸便签卡片
- ✅ **今日任务**：只展示当天任务，完成状态实时同步
- 📅 **任务页**：按日期分组，今天显示时间，未来任务显示日期与时间
- 🤖 **AI 便签**：生成任务计划、编辑生成结果、一键加入任务
- 🔐 **服务商配置**：支持 OpenAI、Anthropic、Google Gemini、DeepSeek、硅基流动、Moonshot、智谱 AI、通义千问
- 💾 **本地数据**：使用本地持久化保存便签、任务、标签和配置
- 🗑️ **回收站**：删除内容进入回收站，14 天后自动清理

---

## 🛠️ 技术栈

- 💙 `Flutter / Dart`：跨平台应用开发
- 🌊 `Riverpod`：状态管理
- 🧭 `GoRouter`：声明式路由
- 📦 `Hive`：本地数据存储
- ⚙️ `Shared Preferences`：轻量配置持久化
- 🎭 `Material Design + 自定义组件`：便签风格 UI

---

## 🚀 快速开始

📥 安装依赖并运行：

```bash
flutter pub get
flutter run
```

🌐 运行到 Web：

```bash
powershell -ExecutionPolicy Bypass -File scripts/run_web.ps1
```

默认 Web 地址固定为 `http://127.0.0.1:3000`。

📱 运行到 Android 真机：

```bash
flutter devices
flutter run -d <device-id>
```

---

## 🧪 验证与构建

🔍 代码检查、测试和调试包构建：

```bash
flutter analyze
flutter test
flutter build apk --debug
```

---

### 📦 发布 APK 构建（自动自增版本号）

项目提供了 PowerShell 脚本 `scripts/build_apk.ps1`，每次构建会自动将 `pubspec.yaml` 中的构建号（`+N`）自增 1，保证每个 APK 包的版本唯一。

| 命令 | 说明 |
|------|------|
| `.\scripts\build_apk.ps1` | 自增版本号 + 执行 `flutter build apk --release` |
| `.\scripts\build_apk.ps1 -Preview` | 仅预览下一个版本号，不修改文件、不构建 |
| `.\scripts\build_apk.ps1 -NoBuild` | 仅更新版本号，不构建 APK |

> 版本号格式说明：`pubspec.yaml` 中 `version: 1.0.0+2`，`1.0.0` 为语义化版本名，`2` 为构建号。脚本自动将构建号 +1。

📁 构建产物位置：

```txt
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📁 目录结构

```txt
lib/
├── core/          # 🎨 主题、路由、网络、通用组件与工具
├── data/          # 💾 数据模型、本地存储和仓库层
├── features/      # 🧩 首页、便签、任务、日历、AI、成就、归档等业务模块
└── shared/        # 🔧 跨模块复用组件、枚举和辅助方法
```

---

## 📲 下载安装

🎁 可以在 GitHub Releases 中下载已打包的 APK：

👉 [下载 v1.0.0 APK](https://github.com/MewzCC/smartNoteAi/releases/tag/v1.0.0)

---

## 🌱 开源说明

💡 本项目目前是智能便签应用原型，主要用于学习、展示和二次开发。

🧱 后续可以继续扩展桌面端、移动端系统提醒、更多 AI 服务商和完整的云同步能力。
