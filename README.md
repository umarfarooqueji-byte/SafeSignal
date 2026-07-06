# 🛡️ SafeSignal

**AI-powered scam detection app — elderly-friendly, bilingual (Hindi + English)**

> _"Koi bhi shak wala message bhejein — SafeSignal bata dega: SCAM hai ya SAFE hai."_

---

## ✨ Features

- 🔴🟡🟢 **Color-coded Verdicts** — SCAM / SAVDHAN / SAFE at a glance
- 💬 **WhatsApp-style Chat UI** — Paste or forward any suspicious message
- 📸 **Screenshot Analysis** — Attach image for OCR-based analysis
- 🌐 **Bilingual** — Full Hindi + English support
- 📰 **Daily Alert Feed** — Latest scam trends delivered daily
- 📋 **History** — All past checks stored locally with Hive
- 🔒 **Privacy-first** — No personal data sent to servers
- 👴 **Elderly-friendly** — Large text, big buttons, simple UI
- 📞 **1930 Integration** — Direct link to National Cybercrime Helpline

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.x + Riverpod v3 + GoRouter |
| **State** | Riverpod (NotifierProvider) |
| **Local DB** | Hive (offline cache + history) |
| **Remote DB** | Supabase (user history, alerts) |
| **Networking** | Dio with interceptors |
| **Backend** | FastAPI + Python |
| **AI Engine** | Mesh API — Two-tier (Speed + Quality) |
| **RAG** | FAISS + Mesh embeddings |
| **Notifications** | FCM + flutter_local_notifications |
| **Localization** | Flutter Gen L10n (EN + HI) |

---

## 📁 Project Structure

```
lib/
├── main.dart
├── core/
│   ├── theme/app_theme.dart       # scamRed, cautionYellow, safeGreen
│   ├── constants.dart             # API URLs, thresholds
│   ├── router/app_router.dart     # GoRouter config
│   └── network/dio_client.dart    # Dio singleton
├── data/
│   ├── models/                    # VerdictModel, AlertModel, CheckHistoryModel
│   ├── local/                     # Hive service
│   └── repositories/              # Analysis, Feed, History repos
├── features/
│   ├── onboarding/                # Splash → Slides → Language → Disclaimer
│   ├── chat/                      # Main input screen
│   ├── verdict/                   # Color-coded result screen
│   ├── feed/                      # Daily alert feed
│   ├── history/                   # Past checks
│   └── settings/                  # Language, text size, notifications
├── l10n/
│   ├── app_en.arb                 # English strings
│   └── app_hi.arb                 # Hindi strings
└── shared/widgets/                # Reusable components
```

---

## 🚀 Getting Started

```bash
git clone https://github.com/YOUR_USERNAME/safesignal.git
cd safesignal
flutter pub get
flutter run
```

### Supabase Setup
1. Create project at [supabase.com](https://supabase.com)
2. Update `lib/core/constants.dart` with your URL and anon key

---

## 📋 Build Roadmap

| Step | Status | Description |
|------|--------|-------------|
| 0 | ✅ | Flutter deps installed |
| 1 | ✅ | Folder structure |
| 2 | ✅ | Theme + models |
| 3 | ✅ | Onboarding + language |
| 4 | ✅ | Chat screen |
| 5 | ✅ | Verdict screen |
| 6 | ✅ | Feed + History + Settings |
| 7 | 🔜 | FastAPI backend |
| 8 | 🔜 | Mesh API two-tier AI |
| 9 | 🔜 | Daily feed + FCM |
| 10 | 🔜 | Polish + deploy |

---

## ⚠️ Disclaimer

SafeSignal is an AI assistant — not an authority. For real fraud, always report to:
📞 **1930** — National Cybercrime Helpline (India)

---

## 📄 License

MIT License
