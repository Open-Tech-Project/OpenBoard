OpenBoard

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
