# DFUUnlocker beta

Cross-platform desktop unlocking toolkit for **macOS** and **Windows**.

---

## Requirements

| Platform | Prerequisites |
|----------|---------------|
| **macOS** | [Flutter SDK](https://docs.flutter.dev/get-started/install/macos) 3.10+, Xcode 15+, Command Line Tools |
| **Windows** | [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) 3.10+, [Visual Studio 2022](https://visualstudio.microsoft.com/) with the **Desktop development with C++** workload |

Verify your setup:

```bash
flutter doctor
```

Enable the desktop platform you need (only required once per machine):

```bash
flutter config --enable-macos-desktop   # macOS
flutter config --enable-windows-desktop # Windows
```

---

## Run from source (step by step)

### 1. Get the project

Copy or extract the project folder to a location on your machine, then open a terminal in that folder.

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Launch the app

**On macOS:**

```bash
flutter run -d macos
```

**On Windows:**

```bash
flutter run -d windows
```

### 4. Enter your access key

When the app opens, enter your license key on the access key screen to unlock the toolkit.

### 5. Connect your device

Connect your phone via USB. The app detects connected devices automatically and displays device details when a handset is linked.

### 6. Choose a tool

From the tools hub, select one of the available unlock workflows and follow the on-screen steps.

---

## Run a pre-built release

If you received a release archive instead of source code:

**macOS**

1. Unzip `DFUUnlocker-beta-macos.zip`.
2. Move `DFUUnlocker beta.app` to **Applications** (or any folder).
3. Launch the app and enter your access key.

**Windows**

1. Unzip `DFUUnlocker-beta-windows.zip` to a folder (e.g. `C:\DFUUnlocker`).
2. Run `dfu_unlocker.exe`.
3. Enter your access key when prompted.

---

## Build a release

```bash
flutter pub get
```

**macOS:**

```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/DFUUnlocker beta.app`

**Windows:**

```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/dfu_unlocker.exe`

---

## Access key

Enter one of the license keys below to access the toolkit.

### License keys

- `DFU-X7M2-9KPL-4R8N`
- `UNLOCK-PRO-2026-BETA`
- `LICENSE-A8F3-2H9Q-7X1M`
- `MASTER-KEY-DFU-2025`
- `BETA-ACCESS-K9P2-7H4M`
- `DFUUNLOCK-8842-XR9K`
- `PRO-LICENSE-3F8A-2K9Q`
- `DFU-PRO-7K9M-2X4P-8N1Q`
- `UNLOCK-MASTER-2026-R3T8`
- `LICENSE-DFU-9H2K-5M7X-1P4N`
- `BETA-PRO-ACCESS-2025-K8M2`
- `DFUUNLOCK-PRO-6F9A-3K7Q`
- `MASTER-LICENSE-X2P9-7H4M`
- `UNLOCK-KEY-2026-A8F3-2K9Q`
- `DFU-BETA-4R8N-X7M2-9KPL`
- `PRO-ACCESS-DFU-2025-7H4M`
- `LICENSE-UNLOCK-9KPL-4R8N`
- `DFU-MASTER-KEY-2026-BETA`
- `UNLOCK-PRO-LICENSE-3F8A`
- `BETA-DFU-ACCESS-K9P2-7H4M`
- `DFUUNLOCK-MASTER-8842-XR9K`
- `PRO-KEY-DFU-2H9Q-7X1M`
- `LICENSE-BETA-2025-ACCESS`
- `DFU-PRO-UNLOCK-6F9A-3K7Q`
- `MASTER-ACCESS-DFU-2026`
- `UNLOCK-LICENSE-X2P9-7H4M`
- `DFU-BETA-KEY-9H2K-5M7X`
- `PRO-DFUUNLOCK-2025-K8M2`

---

## Tools

1. iCloud Activation Lock Removal
2. Carrier Lock Removal
3. IMEI Blacklist Removal
4. FRP Removal

---

## License

MIT
