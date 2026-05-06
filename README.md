# 🥕 ScrapChef

AI-powered food scrap tracking app that turns kitchen leftovers into delicious meal suggestions.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-green?logo=dart)

## ✨ Features

- **📷 AI-Powered Scanning** - Take photos of food scraps for instant classification
- **📦 Smart Inventory** - Track your scrap bin with cute veggie mascots
- **🍳 Recipe Suggestions** - Get personalized recipes based on your available scraps
- **🎨 Beautiful UI** - Warm earthy color palette with adorable custom mascots
- **📳 Haptic Feedback** - Satisfying interactions throughout

## 🎨 Design

**Color Palette:**
- Cream (#FAF7F2) - Background
- Terracotta (#C17A4A) - Primary actions
- Sage (#7A9E7E) - Secondary/Success
- Deep Brown (#3D2914) - Text

**Mascots:**
- 🥕 Sad Carrot (empty bin)
- 🍅 Happy Tomato (success)
- 🥦 Thinking Broccoli (no recipes)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Dart 3.x
- Android Studio / Xcode (for emulators)

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/ScrapChef.git

# Navigate to project
cd ScrapChef

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 📁 Project Structure

```
lib/
├── src/
│   ├── app.dart              # App entry point
│   ├── models.dart           # Data models
│   ├── screens/              # UI screens
│   │   ├── splash_screen.dart
│   │   ├── home_screen.dart
│   │   ├── scan_screen.dart
│   │   └── ...
│   ├── state/                # State management
│   │   └── app_state.dart
│   ├── services/             # Business logic
│   │   └── sound_service.dart
│   └── widgets/              # Reusable components
│       ├── veggie_mascots.dart
│       ├── animated_button.dart
│       └── ...
├── main.dart
└── ...

wireframe/                      # Interactive HTML wireframe
├── index.html
├── styles.css
└── script.js
```

## 🎯 MVP Features

- [x] Camera-based scrap scanning
- [x] Manual scrap entry
- [x] Inventory tracking
- [x] Recipe suggestions
- [x] Cute veggie mascots
- [x] Haptic feedback
- [x] Settings screen

## 🔮 Future Improvements

- [ ] Real AI image classification
- [ ] Backend integration
- [ ] User accounts
- [ ] Dark mode
- [ ] Notifications
- [ ] Recipe saving
- [ ] Waste analytics

## 📱 Screenshots

*Coming soon...*

## 🎨 Wireframe

Check out the interactive wireframe in the `wireframe/` folder - open `index.html` in your browser to explore the UI flow!

## 🤝 Contributing

This is a prototype project. Contributions welcome!

## 📄 License

MIT License - feel free to use this project as a starting point for your own apps!

---

Built with 💚 and Flutter
