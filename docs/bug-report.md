# Combined Helpdesk Bug Report (Backend, Web Frontend & Flutter Mobile)

## Overview
This master document consolidates all bugs, structural issues, protocol mismatches, and mobile lifecycle bugs discovered and resolved across the entire Helpdesk System.

---

## 1. Backend (Spring Boot 4.0.3 / Java 21)

| Bug ID | Component / File | Issue Description | Resolution | Status |
|---|---|---|---|:---:|
| **BE-01** | [`AuthController.java`](file:///D:/Course Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/AuthController.java) | NPE on `/api/v1/auth/refresh` when user has no assigned department. | Added safe null-check for `user.getDepartment() != null ? user.getDepartment().getId() : null`. | 🟢 FIXED |
| **BE-02** | [`AuthResponse.java`](file:///D:/Course Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/dto/response/AuthResponse.java) | Missing user `id` and `imageUrl` in login response, requiring an extra network roundtrip. | Added `Long id` and `String imageUrl` fields to record and mapped them in `AuthServiceImpl`. | 🟢 FIXED |
| **BE-03** | [`CorsConfig.java`](file:///D:/Course Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/config/CorsConfig.java) | CORS restricted strictly to `http://localhost:3000`; alternate ports and mobile dev tools were rejected. | Replaced with `.allowedOriginPatterns("*")` and `.allowCredentials(true)`. | 🟢 FIXED |
| **BE-04** | [`application.properties`](file:///D:/Course Wing/Final/fix/helpdesk/src/main/resources/application.properties) | Default loopback server binding prevented mobile phones on local Wi-Fi from connecting. | Set `server.address=0.0.0.0` and verified port 8080. | 🟢 FIXED |

---

## 2. Web Frontend (Next.js 16 / React 19 / Redux Toolkit)

| Bug ID | Component / File | Issue Description | Resolution | Status |
|---|---|---|---|:---:|
| **FE-01** | [`ProfileView.tsx`](file:///D:/Course Wing/Final/fix/helpdesk-frontend/src/components/Profile/ProfileView.tsx) | Profile called `GET /api/v1/users/{id}`, triggering 403 Forbidden for non-admin accounts. | Added `getCurrentUser` query (`GET /api/v1/users/me`) and updated `ProfileView` to use `useGetCurrentUserQuery`. | 🟢 FIXED |
| **FE-02** | [`/tickets/[id]/edit/page.tsx`](file:///D:/Course Wing/Final/fix/helpdesk-frontend/src/app/(Dashboard)/tickets/[id]/edit/page.tsx) | Edit route mounted `TicketDetailView` which executed `createTicket` (POST), creating duplicates. | Added `updateTicket` mutation (`PUT /api/v1/tickets/{id}`) and created `EditTicketView.tsx` with full edit form. | 🟢 FIXED |
| **FE-03** | [`.env.development`](file:///D:/Course Wing/Final/fix/helpdesk-frontend/.env.development) | Contained commented-out Railway production URLs and inconsistent environment variables. | Standardized on local backend `http://localhost:8080/api/v1/` and provided `.env.example`. | 🟢 FIXED |

---

## 3. Flutter Mobile App (Flutter 3.44 / Android)

| Bug ID | Component / File | Issue Description | Resolution | Status |
|---|---|---|---|:---:|
| **MOB-01** | [`AndroidManifest.xml`](file:///D:/Course Wing/Final/fix/helpdesk_mobile/android/app/src/main/AndroidManifest.xml) | Missing `INTERNET` permission and cleartext HTTP disabled, causing Android network blocks to `10.0.2.2`. | Added `INTERNET`, `ACCESS_NETWORK_STATE`, and `android:usesCleartextTraffic="true"`. | 🟢 FIXED |
| **MOB-02** | [`UrlUtils.dart`](file:///D:/Course Wing/Final/fix/helpdesk_mobile/lib/core/utils/url_utils.dart) | Backend-returned image URLs with `localhost` failed to render on physical devices and Android emulators. | Built `UrlUtils.resolveImageUrl` to automatically rewrite `localhost`/`127.0.0.1` into the active target host. | 🟢 FIXED |
| **MOB-03** | [`create_ticket_screen.dart`](file:///D:/Course Wing/Final/fix/helpdesk_mobile/lib/features/tickets/presentation/screens/create_ticket_screen.dart) | Used fake `picsum.photos` demo generator and dummy delayed submission branch. | Replaced with URL attachment dialog and direct `POST /api/v1/tickets` repository submission. | 🟢 FIXED |
| **MOB-04** | [`ticket_detail_screen.dart`](file:///D:/Course Wing/Final/fix/helpdesk_mobile/lib/features/tickets/presentation/screens/ticket_detail_screen.dart) | Contained hardcoded "John Doe" dummy ticket fallback and simulated delay status updates. | Connected live API endpoints (`GET /api/v1/tickets/{id}` and `PATCH /api/v1/tickets/{id}/status`). | 🟢 FIXED |
| **MOB-05** | [`incident_catalog_screen.dart`](file:///D:/Course Wing/Final/fix/helpdesk_mobile/lib/features/incident_catalog/presentation/screens/incident_catalog_screen.dart) | Hardcoded fake categories fallback when `apiClient` was not explicitly passed. | Bound directly to `CategoryRepository.getCategories()` with `AppErrorState` retry on error. | 🟢 FIXED |
| **MOB-06** | [`dashboard_screen.dart`](file:///D:/Course Wing/Final/fix/helpdesk_mobile/lib/features/dashboard/presentation/screens/dashboard_screen.dart) | Fallback hardcoded stats (total: 42) masked API connection errors. | Removed fake stats; now surfaces live KPIs with pull-to-refresh and retry button. | 🟢 FIXED |
| **MOB-07** | [`ticket_history_screen.dart`](file:///D:/Course Wing/Final/fix/helpdesk_mobile/lib/features/tickets/presentation/screens/ticket_history_screen.dart) | Fallback dummy ticket masked history queue failures. | Connected directly to `GET /api/v1/tickets/history`. | 🟢 FIXED |
| **MOB-08** | [`profile_screen.dart`](file:///D:/Course Wing/Final/fix/helpdesk_mobile/lib/features/profile/presentation/screens/profile_screen.dart) | "Demo User" fallback concealed auth/profile retrieval errors. | Connected directly to `GET /api/v1/users/me` with dynamic avatar and real ticket counts. | 🟢 FIXED |
| **MOB-09** | [`env_config.dart`](file:///D:/Course Wing/Final/fix/helpdesk_mobile/lib/core/config/env_config.dart) | Contained dead staging/prod cloud domains (`staging-api.helpdesk.com`). | Stripped cloud domains, configuring strictly local targets (`10.0.2.2`, `localhost`, LAN IP override). | 🟢 FIXED |
| **MOB-10** | [`api_client.dart`](file:///D:/Course Wing/Final/fix/helpdesk_mobile/lib/core/network/api_client.dart) | Constructor required explicit arguments, causing initialization errors across isolated screens. | Added default fallbacks to `EnvConfig.fromEnvironment()` and `FlutterSecureStorageImpl()`. | 🟢 FIXED |
