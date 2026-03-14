# TP Coder - AI-Powered Code Builder

Flutter mobile app for building websites, Android, and iOS apps using AI.

## Quick Start (GitHub Build)

```bash
# 1. Unzip and init
unzip tp_coder_flutter_project.zip && cd tp_coder
git init && git add . && git commit -m "Initial commit"

# 2. Push to GitHub
git remote add origin https://github.com/YOUR_USERNAME/tp-coder.git
git branch -M main && git push -u origin main

# 3. APK builds automatically via GitHub Actions
# Go to Actions tab → download APK artifact
```

## Project Structure

```
lib/
├── main.dart                 # Entry + routing (14 routes)
├── config/                   # Theme (dark/light) + API constants
├── models/models.dart        # 10 data models
├── services/                 # HTTP client + Socket.io
├── providers/                # Auth, Project, Chat, Theme state
├── screens/                  # 14 screens across 5 sections
└── widgets/common_widgets.dart
```

## 14 Screens

Splash → Login/Register → Onboarding → Dashboard → Chats → Notifications → Settings → AI Chat → Project Detail → Build Status → Team → Pricing → Feedback → Forgot Password

## Backend Required

Update `lib/config/constants.dart`:
```dart
static const String baseUrl = 'https://your-server.com/api';
static const String socketUrl = 'https://your-server.com';
```

## Tech

Flutter 3.24+ | Provider | Socket.io | GitHub Actions CI/CD | Package: com.builder.tpo
