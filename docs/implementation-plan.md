# Implementation Plan: Flutter Helpdesk Mobile

This document outlines the ordered implementation milestones for building the Flutter Android mobile application.

---

## Milestone 1: Discovery & Architecture Alignment (COMPLETED)
- [x] Analyze backend API architecture, security filters, endpoints, and data models.
- [x] Analyze web frontend screens, forms, validations, color palette, and component design tokens.
- [x] Generate comprehensive documentation: `api-contract.md`, `screen-inventory.md`, `design-tokens.md`, `backend-gaps.md`.

## Milestone 2: Core Foundation & Theme Integration (COMPLETED)
- [x] Configure Flutter project with null-safe Dart, Material 3, and custom Satoshi typography.
- [x] Define exact `AppColors`, `AppTypography`, `AppSpacing`, and `AppTheme` (Light and Dark modes).
- [x] Build shared primitive widgets: `AppButton`, `AppBadge`, `AppTextField`, `AppLoadingIndicator`, `AppEmptyState`, `AppErrorState`.
- [x] Verify theme and widget tests.

## Milestone 3: Networking, Storage & Authentication Engine (COMPLETED)
- [x] Setup `EnvConfig` supporting Android Emulator (`10.0.2.2:8080`), LAN IP, and production cloud backend.
- [x] Implement `SecureStorage` with `flutter_secure_storage` and in-memory test harness.
- [x] Implement `ApiClient` with Dio and `AuthInterceptor` (JWT bearer header attach, 401 refresh flow, session revocation).
- [x] Implement robust `ApiError` polymorphic JSON parser.
- [x] Setup `AuthController` and `GoRouter` declarative navigation with `authGuardRedirect`.

## Milestone 4: Incident Catalog & Ticket Creation (COMPLETED)
- [x] Build models for `Category`, `SubCategory`, `TicketRequest`, `TicketResponse`.
- [x] Implement `CategoryRepository` & fetch `GET /api/v1/categories`.
- [x] Implement `IncidentCatalogScreen` with category grid and sub-issue template picker.
- [x] Implement `CreateTicketScreen` with priority selection chips, description validation, photo attachment gallery, and `POST /api/v1/images/upload` file upload pipeline.

## Milestone 5: Ticket Queues & Dashboards (COMPLETED)
- [x] Implement `MyTicketsScreen` (`GET /api/v1/tickets/my`) for `ROLE_USER` with pull-to-refresh, status filters, and search.
- [x] Implement `TicketListScreen` (`GET /api/v1/tickets`) for `ROLE_TECHNICIAN` and `ROLE_ADMIN`.
- [x] Implement `TicketHistoryScreen` (`GET /api/v1/tickets/history`) for resolved issues.
- [x] Implement `DashboardScreen` with KPI metric counters (`GET /api/v1/tickets/stats`) and monthly volume overview (`GET /api/v1/tickets/stats/monthly`).

## Milestone 6: Ticket Details, Status Transitions & Live Chat (COMPLETED)
- [x] Implement `TicketDetailScreen` (`GET /api/v1/tickets/{id}`).
- [x] Implement Status Transition controls (Technician: "Accept Ticket" -> `IN_PROGRESS`, "Close Ticket" -> `COMPLETED`).
- [x] Implement multi-image attachment viewer with full-screen zoom preview.
- [x] Implement ticket status logs timeline.
- [x] Implement ticket chat view (`GET /api/v1/tickets/{id}/messages`) with send input and live messaging.

## Milestone 7: User Profile & Admin Capabilities (COMPLETED)
- [x] Implement `ProfileScreen` calling `GET /api/v1/users/me` with personal ticket metrics.
- [x] Implement Admin Category Management (`CategoryManagementScreen` with CRUD).
- [x] Implement Admin User Management (`UserManagementScreen` list, `UserFormScreen` for add & edit).
- [x] Implement Admin Department creation modal.

## Milestone 8: Quality Assurance & Build Verification (COMPLETED)
- [x] Run `flutter analyze` with zero errors or warnings (`No issues found!`).
- [x] Run all unit, repository, and widget tests (43 passed).
- [x] Compile debug Android APK (`flutter build apk --debug`) -> `build/app/outputs/flutter-apk/app-debug.apk`.
- [x] Generate comprehensive `README.md` with complete developer instructions.
