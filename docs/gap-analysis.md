# Helpdesk Cross-Client Gap Analysis (Before & After Implementation)

> **Generated**: 2026-11-01
> **Source of Truth**: Spring Boot Backend (`D:\Course Wing\Final\fix\helpdesk`)
> **Clients**:
> - **Web Frontend**: Next.js 16 + Redux Toolkit RTK Query (`D:\Course Wing\Final\fix\helpdesk-frontend`)
> - **Mobile App**: Flutter 3 + Dio + GoRouter (`D:\Course Wing\Final\fix\helpdesk_mobile`)

---

## 1. Final Endpoint-by-Endpoint Parity Matrix (After Implementation)

| Backend Feature / Endpoint | Method & Path | Used by Web? | Used by Mobile? | Role | Status After Implementation |
|---|---|---|---|---|---|
| **Auth: Login** | `POST /api/v1/auth/login` | Yes (`authApi.ts`) | Yes (`AuthRepository`) | Public | 🟢 Complete |
| **Auth: Refresh Token** | `POST /api/v1/auth/refresh` | Yes (`apiSlice.ts` + `authApi.ts`) | Yes (`AuthInterceptor` + `AuthRepository`) | Public | 🟢 Complete |
| **Auth: Logout** | `POST /api/v1/auth/logout` | Yes (`authApi.ts`) | Yes (`AuthRepository`) | Public | 🟢 Complete |
| **Users: Current Profile** | `GET /api/v1/users/me` | Yes (`authApi.ts` + `userApi.ts`) | Yes (`UserRepository` -> `ProfileScreen`) | Authenticated | 🟢 Complete |
| **Users: Update Self Profile** | `PUT /api/v1/users/me` | Yes (`userApi.ts` -> `/pages/settings` `PersonalInfoForm` & `UploadPhotoForm`) | Yes (`UserRepository.updateCurrentUser` -> `ProfileScreen` Edit Dialog) | Authenticated | 🟢 **Implemented (P2)** |
| **Users: List All Users** | `GET /api/v1/users` | Yes (`userApi.ts` -> `/users` & `EditTicketView` technician picker) | Yes (`UserRepository` -> `UserManagementScreen` & `EditTicketScreen`) | `ADMIN` | 🟢 **Implemented (P2)** |
| **Users: Get User by ID** | `GET /api/v1/users/{id}` | Yes (`userApi.ts`) | Yes (`UserRepository.getUserById`) | `ADMIN` | 🟢 Complete |
| **Users: Create User** | `POST /api/v1/users` | Yes (`/users/add` & `AddUserModal`) | Yes (`UserFormScreen`) | `ADMIN` | 🟢 Complete |
| **Users: Update User** | `PUT /api/v1/users/{id}` | Yes (`/users/[id]/edit` & `EditUserModal`) | Yes (`UserFormScreen`) | `ADMIN` | 🟢 Complete |
| **Users: Delete User (Soft)** | `DELETE /api/v1/users/{id}` | Yes (`/users`) | Yes (`UserManagementScreen`) | `ADMIN` | 🟢 Complete |
| **Tickets: Create Ticket** | `POST /api/v1/tickets` | Yes (`/incident-catalog/[id]`) | Yes (`CreateTicketScreen`) | `USER`, `ADMIN` | 🟢 Complete |
| **Tickets: List All Queue** | `GET /api/v1/tickets` | Yes (`/tickets` with Status, Priority & Search filters) | Yes (`TicketListScreen` with Status, Priority & Search filters) | `ADMIN`, `TECHNICIAN` | 🟢 **Implemented (P1)** |
| **Tickets: My Tickets** | `GET /api/v1/tickets/my` | Yes (`/user/tickets` with Status, Priority & Search filters) | Yes (`MyTicketsScreen` with Status, Priority & Search filters) | `USER`, `ADMIN` | 🟢 **Implemented (P1)** |
| **Tickets: Completed History** | `GET /api/v1/tickets/history` | Yes (`/user/history` with Priority & Search filters) | Yes (`TicketHistoryScreen` with Priority & Search filters) | Authenticated | 🟢 **Implemented (P1)** |
| **Tickets: Get Ticket by ID** | `GET /api/v1/tickets/{id}` | Yes (`/tickets/[id]`) | Yes (`TicketDetailScreen`) | Authenticated | 🟢 Complete |
| **Tickets: Update Ticket** | `PUT /api/v1/tickets/{id}` | Yes (`/tickets/[id]/edit` `EditTicketView` with category, sub-issue, technician assignment & attachments) | Yes (`/tickets/:id/edit` `EditTicketScreen` with category, sub-issue, technician assignment & attachments) | Creator / `ADMIN` | 🟢 **Implemented (P1)** |
| **Tickets: Update Status** | `PATCH /api/v1/tickets/{id}/status` | Yes (`TicketDetail.tsx` & `TicketRow.tsx` for both `admin` & `technician` with remark modal) | Yes (`TicketDetailScreen` guarded for `ADMIN` & `TECHNICIAN` with remark dialog) | `ADMIN`, `TECHNICIAN` | 🟢 **Implemented (P1)** |
| **Tickets: Delete Ticket** | `DELETE /api/v1/tickets/{id}` | Yes (`TicketDetail.tsx`, `/tickets`, `/user/tickets` for non-completed tickets) | Yes (`TicketDetailScreen` for non-completed tickets) | Creator / `ADMIN` | 🟢 **Implemented (P1)** |
| **Tickets: Dashboard KPIs** | `GET /api/v1/tickets/stats` | Yes (`/` Dashboard) | Yes (`DashboardScreen`) | Authenticated | 🟢 Complete |
| **Tickets: Monthly Chart Stats** | `GET /api/v1/tickets/stats/monthly` | Yes (`/` Dashboard chart) | Yes (`DashboardScreen`) | Authenticated | 🟢 Complete |
| **Tickets: Activity Feed** | `GET /api/v1/tickets/activity` | Yes (Header Notification Dropdown) | Yes (`/notifications` `NotificationsScreen` + Bell icon in `DashboardScreen`, `MyTicketsScreen`, `TicketListScreen`) | Authenticated | 🟢 **Implemented (P3)** |
| **Chat: Get Ticket Messages** | `GET /api/v1/tickets/{ticketId}/messages` | Yes (`TicketChat.tsx`) | Yes (`TicketDetailScreen`) | Authenticated | 🟢 Complete |
| **Chat: Send Ticket Message** | `POST /api/v1/tickets/{ticketId}/messages` + STOMP `/app/chat` | Yes (`TicketChat.tsx` REST POST + STOMP live subscription) | Yes (`TicketDetailScreen` calling `TicketRepository.sendTicketMessage`) | Authenticated | 🟢 **Implemented (P1)** |
| **Status Logs: Lifecycle Timeline** | `GET /api/v1/tickets/{ticketId}/status-logs` | Yes (`TicketDetail.tsx` Status Lifecycle Logs card) | Yes (`TicketDetailScreen` Status Timeline section) | Authenticated | 🟢 **Implemented (P1)** |
| **Audit History: Ticket Logs** | `GET /api/v1/history/ticket/{ticketId}` | Yes (`TicketDetail.tsx` Ticket Audit History card) | Yes (`TicketDetailScreen` Audit History section) | Authenticated | 🟢 **Implemented (P3)** |
| **Categories: List Tree** | `GET /api/v1/categories` | Yes (`/categories`, `/incident-catalog`, `EditTicketView`) | Yes (`CategoryManagementScreen`, `IncidentCatalogScreen`, `EditTicketScreen`) | Authenticated | 🟢 Complete |
| **Categories: Get by ID** | `GET /api/v1/categories/{id}` | Yes (`categoryApi.ts`) | Yes (`CategoryRepository.getCategoryById`) | Authenticated | 🟢 Complete |
| **Categories: Create Category** | `POST /api/v1/categories` | Yes (`CreateCategoryModal.tsx`) | Yes (`CategoryManagementScreen`) | `ADMIN`, `TECHNICIAN` | 🟢 Complete |
| **Categories: Update Category** | `PUT /api/v1/categories/{id}` | Yes (`CategoryManager.tsx` Edit Category / Sub-Issue modal) | Yes (`CategoryManagementScreen` `_showEditCategoryDialog`) | `ADMIN`, `TECHNICIAN` | 🟢 **Implemented (P2)** |
| **Categories: Delete Category** | `DELETE /api/v1/categories/{id}` | Yes (`CategoryManager.tsx`) | Yes (`CategoryManagementScreen`) | `ADMIN`, `TECHNICIAN` | 🟢 Complete |
| **Departments: List All** | `GET /api/v1/departments` | Yes (`/departments` page & user modals) | Yes (`/departments` `DepartmentManagementScreen` & `UserFormScreen`) | Authenticated | 🟢 **Implemented (P2)** |
| **Departments: Get by ID** | `GET /api/v1/departments/{id}` | Yes (`departmentApi.ts`) | Yes (`DepartmentRepository.getDepartmentById`) | Authenticated | 🟢 **Implemented (P2)** |
| **Departments: Create** | `POST /api/v1/departments` | Yes (`/departments` page with `name` & `description`) | Yes (`DepartmentManagementScreen` & `UserFormScreen`) | `ADMIN` | 🟢 **Implemented (P2)** |
| **Departments: Update** | `PUT /api/v1/departments/{id}` | Yes (`/departments` page Edit Department modal) | Yes (`DepartmentManagementScreen` Edit Department dialog) | `ADMIN` | 🟢 **Implemented (P2)** |
| **Images: Upload File** | `POST /api/v1/images/upload` | Yes (`/incident-catalog/[id]`, `/tickets/[id]/edit`, `/pages/settings` `UploadPhotoForm`) | Yes (`CreateTicketScreen`, `EditTicketScreen`, `ProfileScreen`) | Authenticated | 🟢 **Implemented (P1)** |
| **Notifications: Register Token** | `POST /api/v1/notifications/device-token` | N/A (Mobile FCM endpoint) | Yes (`UserRepository.registerDeviceToken` -> `ProfileScreen` Push Notification toggle) | Authenticated | 🟢 **Implemented (P3)** |
| **Notifications: Unregister Token** | `DELETE /api/v1/notifications/device-token` | N/A (Mobile FCM endpoint) | Yes (`UserRepository.unregisterDeviceToken` -> `ProfileScreen` Push Notification toggle) | Authenticated | 🟢 **Implemented (P3)** |

---

## 2. Summary of Gaps Resolved

1. **P1 Core Flows**:
   - Fixed backend `TicketServiceImpl.updateTicket` ignoring `imageUrls` on `PUT /api/v1/tickets/{id}`.
   - Added backend `POST /api/v1/tickets/{ticketId}/messages` in `ChatController.java` and connected both Mobile (`TicketDetailScreen`) and Web (`TicketChat.tsx`) so chat messages persist to PostgreSQL and broadcast in real time.
   - Implemented `EditTicketScreen` (`/tickets/:id/edit`) and Delete Ticket confirmation (`DELETE /api/v1/tickets/{id}`) in Mobile, and added Edit/Delete buttons, Technician Assignment selector, Sub-Issue selector, and Status Lifecycle Logs in Web (`TicketDetail.tsx`, `EditTicketView.tsx`).
   - Added Priority filtering (`ALL`, `LOW`, `MEDIUM`, `HIGH`) across all ticket queues in both Web and Mobile.
   - Wired multipart image upload (`POST /api/v1/images/upload`) in Mobile `CreateTicketScreen`, `EditTicketScreen`, and `ProfileScreen`, and in Web `UploadPhotoForm`.
2. **P2 Admin & Management**:
   - Added Edit Category & Edit Sub-Issue modals (`PUT /api/v1/categories/{id}`) in both Web (`CategoryManager.tsx`) and Mobile (`CategoryManagementScreen`).
   - Created dedicated Department Management screens (`/departments`) in both Web (`src/app/(Dashboard)/departments/page.tsx`) and Mobile (`DepartmentManagementScreen`) supporting list, create, and update (`PUT /api/v1/departments/{id}`).
   - Added `PUT /api/v1/users/me` on Backend and wired self-profile & photo updates in Web (`/pages/settings`) and Mobile (`ProfileScreen`).
   - Updated Mobile `DashboardScreen` Quick Actions and `auth_guard.dart` so `ADMIN` and `TECHNICIAN` can navigate to `/categories` and `/user/history`, and `ADMIN` can navigate to `/users` and `/departments`.
3. **P3 Reports, Notifications & Audit History**:
   - Integrated `GET /api/v1/history/ticket/{ticketId}` in both Web (`TicketDetail.tsx`) and Mobile (`TicketDetailScreen`) to display the full Ticket Audit History alongside Status Transition Logs.
   - Created Mobile `NotificationsScreen` (`/notifications`) calling `GET /api/v1/tickets/activity` and added Notification Bell icons in `DashboardScreen`, `MyTicketsScreen`, and `TicketListScreen`.
   - Integrated `POST /api/v1/notifications/device-token` and `DELETE /api/v1/notifications/device-token` in Mobile `UserRepository` and `ProfileScreen`.
   - Consolidated `/api/v1` into `EnvConfig.apiBaseUrl` in `helpdesk_mobile` so `/api/v1` exists in **one place per client**.
