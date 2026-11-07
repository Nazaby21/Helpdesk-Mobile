# Helpdesk Mobile Application (Flutter Android - Local Setup)

Native Android mobile application for the Helpdesk Incident Management and Support System, built with **Flutter (Dart)**. It interfaces directly with the local Spring Boot backend REST APIs and reproduces 1:1 the design, branding, and workflows of the web frontend adapted to modern mobile UX patterns.

---

## 1. System Requirements & Tech Stack

- **Flutter SDK**: `3.44.2` (channel stable)
- **Dart SDK**: `^3.12.2` (null-safe)
- **Android Target**: Android 14 / API 34+ (minSdkVersion 21)
- **Architecture**: Clean, feature-first architecture (`core/`, `features/<feature>/{data,domain,presentation}`, `shared/widgets`)
- **State Management**: Riverpod & ChangeNotifier controllers
- **Networking**: Dio with `AuthInterceptor` (JWT bearer injection, automatic 401 token refresh retry, session revocation)
- **Routing**: `GoRouter` with role-aware declarative redirect guards (`AuthGuard`)
- **Secure Storage**: `flutter_secure_storage` for hardware-backed token encryption
- **Design System**: Material 3 with custom **Satoshi** font family typography and exact design tokens from the web frontend (Tailwind tokens).

---

## 2. API Base URL & Local Network Configuration

The application centrally manages environment configuration via `EnvConfig` ([`lib/core/config/env_config.dart`](file:///D:/Course%20Wing/Final/fix/helpdesk_mobile/lib/core/config/env_config.dart)). The `/api/v1` prefix exists in **one place** (`EnvConfig.apiBaseUrl`), while all `ApiEndpoints` paths are relative (e.g. `/auth/login`).

| Target | Default API Base URL | Default WebSocket URL | Use Case |
|---|---|---|---|
| **Android Emulator** | `http://10.0.2.2:8080/api/v1` | `ws://10.0.2.2:8080/ws-chat` | Standard Android Studio / AVD emulator |
| **Local Machine (Web/Desktop)**| `http://localhost:8080/api/v1` | `ws://localhost:8080/ws-chat` | Local machine debugging |
| **Real Device (Wi-Fi LAN)**| `http://<YOUR_LAN_IP>:8080/api/v1` | `ws://<YOUR_LAN_IP>:8080/ws-chat` | Physical Android device over local Wi-Fi |

### Setting Custom API URL via Dart Defines

You can pass environment overrides during run or build without modifying source code:

```bash
# Connect to Android Emulator (default)
flutter run

# Connect to physical device via LAN IP
flutter run --dart-define=BASE_URL=http://192.168.1.50:8080/api/v1 --dart-define=WS_URL=ws://192.168.1.50:8080/ws-chat
```

---

## 3. How to Run the App

### 3.1 On Android Emulator
1. Start an Android Virtual Device (AVD) from Android Studio.
2. Ensure the Spring Boot backend is running locally on port 8080.
3. Run:
   ```bash
   flutter pub get
   flutter run
   ```

### 3.2 On Physical Android Device
1. Connect device via USB and enable **USB Debugging** in Developer Options.
2. Ensure device is connected to the same Wi-Fi as your workstation.
3. Find your workstation's LAN IP (`ipconfig` -> IPv4 Address, e.g. `192.168.1.X`).
4. Run:
   ```bash
   flutter run -d <device-id> --dart-define=BASE_URL=http://192.168.1.X:8080/api/v1
   ```

---

## 4. How to Build the APK

To generate the standalone debug APK:

```bash
cd helpdesk_mobile
flutter build apk --debug
```

The compiled APK will be output to:
```
build/app/outputs/flutter-apk/app-debug.apk
```

---

## 5. Verification & Code Quality

### Running Static Analysis
```bash
flutter analyze
```
*Result: "No issues found!" (0 errors, 0 warnings).*

---

## 6. Project Architecture & Feature Directory Map

```
lib/
├── app/
│   ├── app.dart                   # MaterialApp configuration & theme setup
│   ├── constants/                 # Design tokens (AppColors, AppTypography, AppSpacing, relative ApiEndpoints)
│   ├── routes/                    # GoRouter configuration & role-based auth guards
│   └── theme/                     # Light & Dark theme definitions
├── core/
│   ├── config/                    # EnvConfig (single source of /api/v1 prefix)
│   ├── network/                   # ApiClient, AuthInterceptor, ApiError polymorphic parser
│   ├── storage/                   # SecureStorage implementation
│   └── utils/                     # UrlUtils (rewrites localhost/127.0.0.1 to active host)
├── features/
│   ├── auth/                      # Login screen & AuthController
│   ├── dashboard/                 # KPI metrics cards, quick actions & monthly resolution charts
│   ├── incident_catalog/          # Incident categories grid & template picker
│   ├── tickets/                   # My Tickets, Org Queue, Create/Edit Ticket, Detail, Live Chat, Status Logs & Audit History
│   ├── categories/                # Category & Sub-Issue CRUD (Admin & Technician)
│   ├── users/                     # Admin User Directory & User Add/Edit Forms
│   ├── departments/               # Admin Department Management CRUD
│   ├── notifications/             # Notification Feed, Mark as Read & FCM Device Registration
│   └── profile/                   # User profile, Self-Service Edit Profile, Avatar Upload & Personal Stats
└── shared/
    └── widgets/                   # AppButton, AppBadge, AppTextField, AppLoadingIndicator, AppEmptyState, AppErrorState
```

---

## 7. Role-Based Capabilities

| Feature | Regular User (`USER`) | Technician (`TECHNICIAN`) | Administrator (`ADMIN`) |
|---|:---:|:---:|:---:|
| **Sign In & Auto Refresh** | ✅ | ✅ | ✅ |
| **Browse Incident Catalog** | ✅ | ✅ | ✅ |
| **Submit Incident with Photos** | ✅ | ✅ | ✅ |
| **Edit / Delete Ticket** | ✅ (Own) | ✅ | ✅ |
| **My Tickets Queue (Status + Priority filter)** | ✅ | ✅ | ✅ |
| **Organization Ticket Queue (Status + Priority filter)** | ❌ | ✅ | ✅ |
| **Accept Ticket (`IN_PROGRESS`)** | ❌ | ✅ | ✅ |
| **Close Ticket (`COMPLETED`)** | ❌ | ✅ | ✅ |
| **Ticket Details, REST Chat, Status Logs & Audit History** | ✅ (Own) | ✅ (Assigned) | ✅ (All) |
| **Resolved History Archive (Priority filter)** | ✅ (Own) | ✅ (Assigned) | ✅ (All) |
| **Operations Dashboard** | ❌ | ✅ (4 KPI cards) | ✅ (5 KPI cards) |
| **Category & Sub-Issue Management (Create/Edit/Delete)** | ❌ | ✅ | ✅ |
| **Department Management (Create/Edit/Delete)** | ❌ | ❌ | ✅ |
| **User Directory & Add/Edit/Delete User** | ❌ | ❌ | ✅ |
| **Notifications Feed & Device Token Toggle** | ✅ | ✅ | ✅ |
| **Self-Service Profile & Photo Update (`PUT /users/me`)** | ✅ | ✅ | ✅ |

---

## 8. Documentation References

For exhaustive technical references, see [`docs/`](file:///D:/Course%20Wing/Final/fix/helpdesk_mobile/docs):
- [backend-feature-inventory.md](file:///D:/Course%20Wing/Final/fix/helpdesk_mobile/docs/backend-feature-inventory.md): Complete inventory of all backend controllers, services, entities, and rules.
- [gap-analysis.md](file:///D:/Course%20Wing/Final/fix/helpdesk_mobile/docs/gap-analysis.md): Before & After feature parity matrix across Backend, Web, and Mobile.
- [backend-changes.md](file:///D:/Course%20Wing/Final/fix/helpdesk_mobile/docs/backend-changes.md): Minimal backend additions (`POST /tickets/{id}/messages`, `PUT /users/me`, `imageUrls` fix).
- [api-contract.md](file:///D:/Course%20Wing/Final/fix/helpdesk_mobile/docs/api-contract.md): Complete backend REST & STOMP endpoint contract.
- [screen-inventory.md](file:///D:/Course%20Wing/Final/fix/helpdesk_mobile/docs/screen-inventory.md): Web page to mobile screen mapping.
- [design-tokens.md](file:///D:/Course%20Wing/Final/fix/helpdesk_mobile/docs/design-tokens.md): Typography, color palette, spacing, and radiuses.
- [progress.md](file:///D:/Course%20Wing/Final/fix/helpdesk_mobile/docs/progress.md): Implementation & work sessions log.
