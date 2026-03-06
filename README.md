# 📔 Daily Diary App

<p align="center">
  <img src="assets/logo (2).png" alt="Daily Diary App Logo" width="120"/>
</p>

<p align="center">
  <a href="https://flutter.dev/">
    <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg" alt="Flutter"/>
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT"/>
  </a>
  <a href="https://android.com">
    <img src="https://img.shields.io/badge/Platform-Android-green.svg" alt="Platform: Android"/>
  </a>
</p>

---

## 📱 Overview

**Daily Diary App** is a beautiful Flutter application that allows you to write and manage your personal diary entries with cloud backup support via Google Drive. It features a modern Material Design 3 interface with customizable themes and background colors.

---

## ✨ Features

### Core Features
- 📝 **Create Diary Entries** - Write personal thoughts, memories, and daily notes
- 🖼️ **Image Attachments** - Add photos to your diary entries
- 📂 **Local Storage** - Securely stored on device using Hive database
- ☁️ **Google Drive Backup** - Backup all entries to Google Drive
- 📥 **Google Drive Import** - Import entries from Google Drive

### Customization
- 🎨 **Theme Modes** - System, Light, and Dark themes
- 🖌️ **Background Colors** - Choose from 8 background colors (White, Light Grey, Light Blue, Light Green, Light Pink, Light Purple, Light Amber, Light Teal)
- 🔤 **Font Colors** - Customize text color (Black, Dark Grey, Blue Grey, Brown, Indigo, Deep Purple)

### User Experience
- 🔄 **Pull-to-Refresh** - Refresh your diary list easily
- 🗑️ **Delete Entries** - Remove unwanted entries with confirmation
- 📱 **Responsive Design** - Works on various screen sizes

---

## 📸 Screenshots

| Home Screen | Add Entry | Settings Menu |
|:-----------:|:----------:|:-------------:|
| ![Home](screenshots/home.png) | ![Add](screenshots/add.png) | ![Settings](screenshots/settings.png) |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Android SDK
- Google Cloud Console account (for Drive API)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/daily_diary_app.git
   cd daily_diary_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Google Drive API**

   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project
   - Enable Google Drive API
   - Configure OAuth consent screen
   - Add your SHA-1 fingerprint:
     ```
     6F:48:0C:8A:C7:28:01:FF:8E:91:68:D4:E3:AE:83:05:A8:77:18:A8
     ```
   - Create OAuth 2.0 client ID for Android
   - Replace `YOUR_CLIENT_ID` in:
     - `lib/services/drive_service.dart`
     - `android/app/src/main/AndroidManifest.xml`

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── diary_model.dart      # Diary entry model
│   └── diary_model.g.dart    # Hive type adapter
├── screens/
│   ├── home_screen.dart      # Main screen with diary list
│   └── add_diary_screen.dart # Add/edit diary entry
└── services/
    └── drive_service.dart   # Google Drive integration

assets/
└── logo (2).png            # App logo
```

---

## 🛠️ Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  image_picker: ^1.1.2
  path_provider: ^2.1.3
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  google_sign_in: ^6.2.1
  googleapis: ^13.1.0
  googleapis_auth: ^1.6.0
  http: ^1.2.1
  intl: ^0.19.0
```

---

## 📱 How to Use

### Writing a Diary Entry
1. Tap the **"New Entry"** button (FAB)
2. Write your thoughts in the text field
3. Optionally add a photo using the camera/gallery icon
4. Tap **"Save"** to store your entry

### Backing Up to Google Drive
1. Tap the **cloud icon** in the app bar
2. Sign in with your Google account (first time)
3. Your entries will be backed up automatically

### Importing from Google Drive
1. Tap the **settings icon** (⚙️)
2. Select **"Import from Drive"**
3. Sign in if prompted
4. Entries will be downloaded and saved locally

### Changing Theme/Colors
1. Tap the **settings icon** (⚙️)
2. Choose:
   - **Theme** → System/Light/Dark
   - **Background Color** → Select your preferred color
   - **Font Color** → Select text color

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Google Drive API](https://developers.google.com/drive/api) - Cloud storage
- [Hive](https://hivedb.dev/) - Local database
- [Google Sign-In](https://developers.google.com/identity/sign-in/web/sign-in) - Authentication

---

<p align="center">Made with ❤️ using Flutter</p>

