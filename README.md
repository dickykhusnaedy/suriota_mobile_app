# Gateway Config App

## Description

Gateway Config App is a **mobile** application built with Flutter, designed to help users provision and configure gateway devices—ranging from Bluetooth Low Energy (BLE) connection, Wi‑Fi setup, to data synchronization—quickly and intuitively. This app is ideal for field technicians or end-users who need a user-friendly interface to set up a gateway within minutes.

## Key Features

- **Dynamic BLE Service/Characteristic Detection & Selection** Automatically discovers and displays available UUIDs for users to select preferred services and characteristics.
- **Network Configuration** Supports SSID input, password entry, and DHCP/Static IP options.
- **JSON File Read/Write** Synchronize configuration parameters to and from the gateway using JSON files stored on the ESP32 (LittleFS).
- **Responsive UI** Built with Flutter and Material 3 for smooth performance on both Android and iOS.
- **Centralized State Management** Utilizes _provider_ for predictable and testable data flow.

## Tech Stack

| Layer                | Technology               |
| -------------------- | ------------------------ |
| **Language**         | Dart                     |
| **Framework**        | Flutter ≥ 3.22           |
| **State Management** | GetX                     |
| **Bluetooth**        | flutter_blue_plus ≥ 1.31 |

## Requirements

- Flutter SDK ≥ `3.22.x`
- Xcode 15 (for iOS builds)
- Android Studio / Android SDK 34
- Target device with BLE support (Android 5.0+ / iOS 12+)

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/dickykhusnaedy/suriota_mobile_app.git
   cd suriota_mobile_app
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Run the app**
   ```bash
   # Select device then run
   flutter run
   ```

## Project Structure (simplified)

```
lib/
├─ controller/                  # Logic controllers
├─ core/                        # Constants, helpers, etc.
├─ models/                      # Data models
├─ presentation/                # UI and navigation
│  ├─ pages/
│  │  ├─ devices/               # Device configuration screens
│  │  │  ├─ device_communication/
│  │  │  ├─ logging_config/
│  │  │  ├─ modbus_config/
│  │  │  ├─ server_config/
│  │  │  └─ widgets/
│  │  ├─ home/
│  │  ├─ login/
│  │  └─ sidebar_menu/
│  ├─ main_screen.dart
│  ├─ splash_screen.dart
├─ providers/
├─ widgets/                    # Reusable UI components
│  ├─ common/
│  └─ spesific/
├─ main.dart                   # Entry point
```

## Contribution

We welcome contributions! Feel free to open an _issue_ or submit a _pull request_.

1. Fork the repository & create your feature branch (`git checkout -b your-feature`)
2. Commit your changes (`git commit -m 'Add feature X'`)
3. Push to your branch (`git push origin your-feature`) and open a PR

## License

This project is licensed under the **MIT License**. See `LICENSE` for more details.

<hr>

**Built with ❤️ by the Suriota Team**
