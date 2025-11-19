# OpenBoard

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-6.0-red)](https://developer.harmonyos.com/)
[![ArkTS](https://img.shields.io/badge/ArkTS-Language-blue)](https://developer.harmonyos.com/en/docs/documentation/doc-guides/arkts-get-started-0000001774119986)
[![AppGallery](https://img.shields.io/badge/Available%20on-AppGallery-orange)](https://appgallery.huawei.com/)
[![License](https://img.shields.io/badge/License-Open%20Source-green)](#license)

OpenBoard is a modern, open-source keyboard application designed specifically for **HarmonyOS 6.0**. Built with ArkTS, OpenBoard delivers a seamless typing experience with advanced features and multi-language support, available exclusively on Huawei AppGallery.

## 🌟 Features

- **Multi-Language Support**: Full keyboard layouts for Polish, English, Italian, and Persian
- **Smart Word Prediction**: Context-aware suggestions in all supported languages
- **Voice Typing**: Speech-to-text functionality across all languages
- **Clipboard Integration**: Quick access to paste recently copied items
- **Emoji Panel**: Extensive emoji collection with categorized browsing
- **Smart Toolbars**: Context-aware interface that adapts to your typing needs
- **Gesture Support**: Swipe gestures for language switching and navigation
- **Customizable Themes**: Beautiful, responsive design with theme support

## 📱 Supported Languages
```bash
| Language | Status | Layout | Prediction |
|----------|--------|--------|------------|
| English | ✅ Full Support | QWERTY | ✅ Available |
| Polish | ✅ Full Support | QWERTY | ✅ Available |
| Italian | ✅ Full Support | QWERTY | ✅ Available |
| Persian | ✅ Full Support | فارسی | ✅ Available |
```
## 🚀 Quick Start
```bash
### Prerequisites

- **HarmonyOS 6.0** or later
- **DevEco Studio** (for development)
- **ArkTS** development environment
```

### Installation

1. **Download from AppGallery**
   - Visit [Huawei AppGallery](https://appgallery.huawei.com/)
   - Search for "OpenBoard"
   - Install the application

2. **Enable OpenBoard as Default Keyboard**
   - Go to **Settings** > **System & updates** > **Language & input** > **Virtual keyboard**
   - Select **OpenBoard** as your default keyboard
   - Grant necessary permissions for voice typing and clipboard access

## 🛠️ Architecture

OpenBoard is built using a modular architecture with the following key components:

- **Keyboard Controller**: Core input management (`keyboardController`)
- **Prediction Engine**: Smart word suggestions (`predictionModel`)
- **Layout System**: Dynamic keyboard layouts for all languages
- **UI Components**: ArkTS-based responsive interface
- **Input Method Extension**: HarmonyOS IME integration

### Key Components
```bash
// Core keyboard structure
- KeyboardLayout (Alphabet, Symbols1, Symbols2)
- KeyAction system for special keys
- Multi-language layout definitions
- Prediction model integration
```
## 🎯 Smart Toolbars

OpenBoard features intelligent toolbars that adapt to your usage context:

1. **Standard Typing Toolbar**
[Close] [Suggestion 1 | Suggestion 2 | Suggestion 3] [Microphone]
- Active during regular typing
- Shows word predictions and voice input option

2. **Pre-Typing Toolbar**
[Close] [Clipboard] [Microphone]
- Appears after 5 seconds of inactivity
- Quick access to clipboard and voice input

3. **Emoji Toolbar**
[⌨ Return] [Empty Space] [Empty Space]
- Active in emoji selection mode
- Easy return to main keyboard

4. **Voice Typing Toolbar**
[Close] [🎤 Typing with voice...]
- Active during voice input sessions
- Shows voice recognition status

## 🤝 Contributing

We welcome contributions from the HarmonyOS developer community! Please read our Contributing Guidelines before submitting pull requests.

### Development Setup

1. **Fork the repository**
   ```bash
   git clone https://github.com/your-username/OpenBoard.git
   cd OpenBoard
Open in DevEco Studio
```bash
   Import project into DevEco Studio
   Configure HarmonyOS SDK
   Set up signing certificates
```
Build and Test
```bash
Connect HarmonyOS device or emulator
Build project: Build > Build Project
Run on target device
```
Adding New Languages
```bash
To add support for a new language:
Create layout definition in model/KeyboardKeyData.ets
Add language code to LanguageCode type
Implement prediction model integration
Update language switching logic
```
📖 Documentation
```bash
API Documentation
