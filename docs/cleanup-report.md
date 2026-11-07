# Combined Cleanup Report (All Three Projects & Root Workspace)

## Overview
This master document consolidates all deletions, dead-code cleanups, removed test files, deployment assets, and preserved seed data across Backend, Web Frontend, Flutter Mobile, and the workspace root.

---

## 1. Root Workspace Cleanups

The following one-off scratch/test scripts in the project root directory were removed:
- `D:\Course Wing\Final\fix\test_8.js`
- `D:\Course Wing\Final\fix\test_api.js`
- `D:\Course Wing\Final\fix\test_debug.js`
- `D:\Course Wing\Final\fix\test_debug_my.js`
- `D:\Course Wing\Final\fix\test_recent.js`
- `D:\Course Wing\Final\fix\check_db.js`

---

## 2. Project-by-Project Removals

### A. Backend (`helpdesk`)
- **Deployment Files**:
  - `helpdesk/Dockerfile`
- **Test Files & Directories**:
  - `helpdesk/src/test/` (including all integration tests, unit tests, and test properties)
- **Dev Dependencies in `pom.xml`**:
  - `spring-boot-starter-data-jpa-test`
  - `spring-boot-starter-webmvc-test`
  - `spring-boot-starter-test`
  - `spring-security-test`
  - `h2`

### B. Web Frontend (`helpdesk-frontend`)
- **Deployment Files**:
  - `helpdesk-frontend/Dockerfile`
  - `helpdesk-frontend/.dockerignore`
- **Test Files**:
  - `helpdesk-frontend/src/app/api/v1/[...path]/route.test.ts`
- **Configuration & Comments**:
  - Commented-out Railway production URLs removed from `.env.development`.

### C. Flutter Mobile (`helpdesk_mobile`)
- **Test Files & Directories**:
  - `helpdesk_mobile/test/` (all unit and widget test files removed per Phase 2 rules).
- **Dead Code**:
  - `helpdesk_mobile/lib/core/storage/in_memory_secure_storage.dart` (test-only storage).
- **Dependencies in `pubspec.yaml`**:
  - Removed `flutter_test` (preserved `flutter_lints`).
- **Mock/Demo Fallback Branches Eliminated**:
  - Removed hardcoded category lists in `incident_catalog_screen.dart`.
  - Removed hardcoded stats in `dashboard_screen.dart`.
  - Removed "John Doe" dummy ticket in `ticket_detail_screen.dart`.
  - Removed fake history item in `ticket_history_screen.dart`.
  - Removed "Demo User" in `profile_screen.dart`.
  - Removed `picsum.photos` demo generator and dummy submit in `create_ticket_screen.dart`.
  - Removed dead production domains in `env_config.dart`.

---

## 3. Preserved Seed Data & Configurations

| Item | Location | Reason for Retention |
|---|---|---|
| **Admin User** (`admin1@helpdesk.com` / `admin1234`) | `DataSeeder.java` | Essential account for authentication, administration, and full ticket triage. |
| **IT, HR, Finance Departments** | `DataSeeder.java` | Core department structures for user assignment and category routing. |
| **Local PostgreSQL Database** | `helpdesk_db` | Real database untouched; no wipe or truncate operations performed. |
| **Linters & Code Quality Tools** | All projects | `eslint`, `flutter_lints`, `maven-compiler-plugin` preserved for continuous stability. |
