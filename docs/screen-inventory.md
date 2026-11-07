# Screen Inventory & Web-to-Mobile Mapping

This document provides a 1:1 mapping between the Next.js web frontend pages (`helpdesk-frontend`) and the Flutter Android mobile screens (`helpdesk_mobile`), detailing component adaptations, form validations, and role-based user flows.

---

## 1. Screen Mapping Master Table

| Web Route | Mobile Route | Target Roles | Web UI Paradigm | Mobile Adapted Pattern |
|---|---|---|---|---|
| `/auth/sign-in` | `/auth/sign-in` | All (Public) | Centered auth card with email & password | SafeArea card form, keyboard-aware scroll |
| `/` (Dashboard) | `/` (Dashboard) | `ADMIN`, `TECHNICIAN` | KPI stat cards + Monthly Area Spline Chart + Sidebar | KPI scrollable grid + monthly trend card + Quick Action tiles + Notification Bell |
| `/user/tickets` | `/user/tickets` | `USER` | Master table of user's reported tickets | Card list with pull-to-refresh, Status & Priority chip filters, search bar, Notification Bell |
| `/tickets` | `/tickets` | `ADMIN`, `TECHNICIAN` | Multi-column table of organization tickets | Card list with status & priority filter chips, search bar, Notification Bell |
| `/tickets/[id]` | `/tickets/:id` | All | Details grid + Edit/Delete/Accept/Close actions + Status & Audit History + Live Chat | Scrollable detail screen with Edit/Delete/Accept/Close actions, multi-image viewer, Status Timeline, Audit History, and REST+WS Chat |
| `/tickets/[id]/edit` | `/tickets/:id/edit` | Creator / `ADMIN` | Form: title, priority, category, sub-issue, technician assignment, attachments | `EditTicketScreen` with priority chips, category/sub-issue/technician dropdowns, and attachment upload/removal |
| `/incident-catalog` | `/incident-catalog` | All | Grid of categories -> Sub-issue templates | Categorized grid / list with icon mapping and template selection |
| `/incident-catalog/[id]` | `/incident-catalog/:subCategoryId/create` | All | Form: priority select, description, photo upload box | `CreateTicketScreen` with priority chips, description validation, and multipart image upload (`POST /api/v1/images/upload`) |
| `/user/history` | `/user/history` | All | Resolved ticket history table with completed dates | `TicketHistoryScreen` with Priority filter chips, search bar, and completion timestamps |
| Header Notification Bell | `/notifications` | All | Dropdown activity feed (`GET /api/v1/tickets/activity`) | `NotificationsScreen` listing recent ticket activity with tap-to-open ticket navigation |
| `/profile` & `/pages/settings` | `/profile` | All | Profile KPI view + Settings personal info & photo upload forms (`PUT /api/v1/users/me`) | `ProfileScreen` with KPI metrics, Edit Profile & Avatar Upload dialog (`PUT /api/v1/users/me`), and Push Notification device token toggle |
| `/categories` | `/categories` | `ADMIN`, `TECHNICIAN` | Tree grid with Create, Edit (`PUT /api/v1/categories/{id}`), and Delete modals | `CategoryManagementScreen` with Create, Edit, and Delete dialogs for main categories and sub-issues |
| `/departments` | `/departments` | `ADMIN` | Department grid with Create & Edit (`PUT /api/v1/departments/{id}`) modal | `DepartmentManagementScreen` with Create & Edit department dialogs |
| `/users` | `/users` | `ADMIN` | Admin data table with search, role badges, delete modal | `UserManagementScreen` directory list with search, role badges, edit & soft-delete actions |
| `/users/add` | `/users/add` | `ADMIN` | User creation form with inline department launcher | `UserFormScreen` (create mode) with role dropdown, department picker, and inline department creation |
| `/users/[id]/edit` | `/users/:id/edit` | `ADMIN` | User edit form with preloaded values | `UserFormScreen` (edit mode) with pre-populated values and optional password update |

---

## 2. Navigation Architecture & Role Guards

### 2.1 Role-Based Entry & Route Protection
- **Unauthenticated**: Redirected to `/auth/sign-in`.
- **Authenticated `USER`**:
  - Lands on `/user/tickets` ("My Tickets").
  - Allowed routes: `/user/tickets`, `/incident-catalog`, `/incident-catalog/:subCategoryId/create`, `/tickets/:id`, `/tickets/:id/edit`, `/user/history`, `/notifications`, `/profile`, `/pages/settings` (Web).
  - Blocked from: `/` (Dashboard), `/tickets` (Organization Queue), `/categories`, `/departments`, `/users`.
- **Authenticated `TECHNICIAN`**:
  - Lands on `/` ("Dashboard").
  - Allowed routes: `/`, `/tickets`, `/tickets/:id`, `/incident-catalog`, `/categories`, `/user/history`, `/notifications`, `/profile`, `/pages/settings` (Web).
  - Blocked from: `/users`, `/departments`.
- **Authenticated `ADMIN`**:
  - Lands on `/` ("Dashboard").
  - Full access to all routes including `/users`, `/users/add`, `/users/:id/edit`, `/departments`, `/categories`, and technician assignment on `/tickets/:id/edit`.
