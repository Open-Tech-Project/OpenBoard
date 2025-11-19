[OpenBoard

OpenBoard is a modern, feature-rich, open-source Input Method Editor (IME) designed specifically for HarmonyOS 6. Built with the native ArkTS language, OpenBoard aims to provide a fast, secure, and highly customizable typing experience for users on the HarmonyOS platform.

This project is slated for release on the AppGallery.

🌟 Key Features

OpenBoard provides intelligent and efficient input across multiple languages:

Seamless Multi-Language Support: Dedicated layouts for four major languages:

English

Polish (Polski)

Italian (Italiano)

Persian (فارسی)

Intelligent Word Prediction: Uses a client-side prediction model to offer relevant word suggestions, speeding up typing and reducing errors.

Integrated Clipboard Access: Quickly view and paste clipboard history directly from the keyboard panel.

Voice Typing (Voice Input): Easily switch to voice input for hands-free dictation in all supported languages.

ArkTS Native Performance: Optimized for HarmonyOS 6 for smooth, low-latency performance and minimal resource usage.

Emoji Panel: Quick access to a comprehensive set of emojis.

🚀 Quick Start (For Developers)

To build and run OpenBoard, you'll need the HarmonyOS development environment.

Prerequisites

DevEco Studio: The official IDE for HarmonyOS development.

HarmonyOS SDK (API 9+): Ensure you have the HarmonyOS SDK for API version 9 or later installed.

Installation & Setup

Clone the repository

git clone [https://github.com/OpenBoard-Project/OpenBoard.git](https://github.com/OpenBoard-Project/OpenBoard.git)
cd OpenBoard


Open in DevEco Studio
Open the OpenBoard project folder in DevEco Studio.

Build and Deploy
Ensure your development device or emulator is running HarmonyOS 6.
Select your device and click Run to install and test the Input Method Extension Ability.

📱 Platform Support

Platform

Status

Notes

HarmonyOS 6+

✅ Supported

Full feature support (Input Method Extension Ability)

🛠️ Architecture Overview

OpenBoard is structured as a standard HarmonyOS Input Method Extension Ability:

ArkTS/UI Layer (entry/src/main/ets/): Contains all the keyboard components, layout logic, and user interface defined using ArkUI.

Input Method Engine (@kit.IMEKit): Utilizes the native ArkTS IME kit for communicating with the operating system and managing text input.

Model/Controller Layer: Separate modules (model/KeyboardController.ts, model/PredictionModel.ts) handle the business logic, state management, and language processing.

🤝 Contributing

We welcome contributions from the community! Please read our Contributing Guidelines before submitting pull requests.

Development Setup

Fork the repository

Create a feature branch: git checkout -b feature/add-new-theme

Make your changes and test thoroughly

Commit your changes: git commit -m 'Implement dark theme support'

Push to the branch: git push origin feature/add-new-theme

Open a Pull Request

📖 Documentation

Contributing Guidelines - How to contribute to the project

Code of Conduct - Community guidelines

Changelog - Project history and updates

🔒 Privacy & Security

OpenBoard respects user privacy and does not collect personal data. The application:

Operates entirely client-side

Does not require network access for core typing features

Does not store user input on external servers

Supports anonymous usage

🐛 Troubleshooting

Common Issues

Build Errors

Ensure DevEco Studio is up to date.

Verify HarmonyOS SDK (API 9+) is properly installed.

Clear build cache and synchronize the project in DevEco Studio.

IME Activation Issues

Ensure OpenBoard is enabled in your device's System Settings > Language & Input.

Restart the application experiencing the keyboard issue.

📞 Support

Issues: GitHub Issues

Discussions: GitHub Discussions

Wiki: Project Wiki

🙏 Acknowledgments

The HarmonyOS team for the excellent ArkTS framework and DevEco Studio.

All contributors who make this project possible.

🗺️ Roadmap

[ ] Advanced theming options

[ ] Customizable key sizes and keyboard height

[ ] Integration with system-level clipboard for paste functionality (Once API is stabilized)

[ ] Handwriting input support

📄 License

This project is licensed under the GNU Affero General Public License, Version 3 or later (AGPLv3+).

Copyright (C) 2025 The OpenBoard Project Authors

Key License Points

Free Software: You are free to run, study, share, and modify this software.

Full Text: The complete license is included in the file LICENSE in this repository.

No Warranty: This program is provided without any warranty.

AGPL Requirement: If you modify and run a version of OpenBoard as a public network service, you must prominently offer all users access to the Corresponding Source Code of your modified version.

Made with ❤️ by the OpenTech community

](https://img.shields.io/badge/HarmonyOS-6.0-red
https://img.shields.io/badge/ArkTS-Language-blue
https://img.shields.io/badge/Available%2520on-AppGallery-orange
https://img.shields.io/badge/License-Open%2520Source-green

OpenBoard is a modern, open-source keyboard application designed specifically for HarmonyOS 6.0. Built with ArkTS, OpenBoard delivers a seamless typing experience with advanced features and multi-language support, available exclusively on Huawei AppGallery.
🌟 Features

    Multi-Language Support: Full keyboard layouts for Polish, English, Italian, and Persian

    Smart Word Prediction: Context-aware suggestions in all supported languages

    Voice Typing: Speech-to-text functionality across all languages

    Clipboard Integration: Quick access to paste recently copied items

    Emoji Panel: Extensive emoji collection with categorized browsing

    Smart Toolbars: Context-aware interface that adapts to your typing needs

    Gesture Support: Swipe gestures for language switching and navigation

    Customizable Themes: Beautiful, responsive design with theme support

📱 Supported Languages
Language	Status	Layout	Prediction
English	✅ Full Support	QWERTY	✅ Available
Polish	✅ Full Support	QWERTY	✅ Available
Italian	✅ Full Support	QWERTY	✅ Available
Persian	✅ Full Support	فارسی	✅ Available
🚀 Quick Start
Prerequisites

    HarmonyOS 6.0 or later

    DevEco Studio (for development)

    ArkTS development environment

Installation

    Download from AppGallery

        Visit Huawei AppGallery

        Search for "OpenBoard"

        Install the application

    Enable OpenBoard as Default Keyboard

        Go to Settings > System & updates > Language & input > Virtual keyboard

        Select OpenBoard as your default keyboard

        Grant necessary permissions for voice typing and clipboard access

🛠️ Architecture

OpenBoard is built using a modular architecture with the following key components:

    Keyboard Controller: Core input management (keyboardController)

    Prediction Engine: Smart word suggestions (predictionModel)

    Layout System: Dynamic keyboard layouts for all languages

    UI Components: ArkTS-based responsive interface

    Input Method Extension: HarmonyOS IME integration

Key Components
typescript

// Core keyboard structure
- KeyboardLayout (Alphabet, Symbols1, Symbols2)
- KeyAction system for special keys
- Multi-language layout definitions
- Prediction model integration

🎯 Smart Toolbars

OpenBoard features intelligent toolbars that adapt to your usage context:
1. Standard Typing Toolbar
text

[Close] [Suggestion 1 | Suggestion 2 | Suggestion 3] [Microphone]

    Active during regular typing

    Shows word predictions and voice input option

2. Pre-Typing Toolbar
text

[Close] [Clipboard] [Microphone]

    Appears after 5 seconds of inactivity

    Quick access to clipboard and voice input

3. Emoji Toolbar
text

[⌨ Return] [Empty Space] [Empty Space]

    Active in emoji selection mode

    Easy return to main keyboard

4. Voice Typing Toolbar
text

[Close] [🎤 Typing with voice...]

    Active during voice input sessions

    Shows voice recognition status

🤝 Contributing

We welcome contributions from the HarmonyOS developer community! Please read our Contributing Guidelines before submitting pull requests.
Development Setup

    Fork the repository
    bash

git clone https://github.com/your-username/OpenBoard.git
cd OpenBoard

    Open in DevEco Studio

        Import project into DevEco Studio

        Configure HarmonyOS SDK

        Set up signing certificates

    Build and Test

        Connect HarmonyOS device or emulator

        Build project: Build > Build Project

        Run on target device

Adding New Languages

To add support for a new language:

    Create layout definition in model/KeyboardKeyData.ts

    Add language code to LanguageCode type

    Implement prediction model integration

    Update language switching logic

📖 Documentation

    API Documentation - Keyboard controller and prediction model

    Layout Guide - Adding custom keyboard layouts

    Contributing Guidelines - How to contribute to the project

    Code of Conduct - Community guidelines

🔒 Privacy & Security

OpenBoard respects user privacy and operates with transparency:

    Local Processing: All word prediction happens on-device

    Minimal Permissions: Only requests necessary keyboard permissions

    No Data Collection: Does not transmit typing data to external servers

    Open Source: Full code transparency for security verification

🐛 Troubleshooting
Common Issues

Keyboard Not Appearing

    Ensure OpenBoard is set as default keyboard in system settings

    Check app permissions in Settings > Apps > OpenBoard

    Restart the device if issues persist

Voice Typing Not Working

    Verify microphone permissions are granted

    Check internet connection (if using cloud speech recognition)

    Ensure language pack is downloaded for offline recognition

Language Switching Issues

    Confirm all language packs are properly installed

    Check available languages in keyboard settings

    Restart the keyboard application

📞 Support

    Issues: GitHub Issues

    Discussions: GitHub Discussions

    Documentation: Project Wiki

🙏 Acknowledgments

    HarmonyOS team for the excellent development platform

    ArkTS language developers

    Huawei AppGallery for distribution support

    Open-source community for inspiration and contributions

    All users and contributors who help improve OpenBoard

📄 License

This project is licensed under the GNU Affero General Public License, Version 3 or later (AGPLv3+).

Copyright (C) 2025 The OpenBoard Project Authors
Key License Points

    Free Software: You are free to run, study, share, and modify this software.

    Full Text: The complete license is included in the file LICENSE in this repository.

    No Warranty: This program is provided without any warranty.

    AGPL Requirement: If you modify and run a version of OpenBoard as a public network service, you must prominently offer all users access to the Corresponding Source Code of your modified version.

Made with ❤️ for the HarmonyOS community
)
