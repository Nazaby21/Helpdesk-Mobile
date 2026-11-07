# Reconciled Open Questions & Architectural Clarifications

> **Source Verification**: Merged from [`helpdesk/docs/backend-analysis/07-open-questions.md`](file:///D:/Course%20Wing/Final/fix/helpdesk/docs/backend-analysis/07-open-questions.md) and [`helpdesk-frontend/docs/mobile-migration/09-open-questions.md`](file:///D:/Course%20Wing/Final/fix/helpdesk-frontend/docs/mobile-migration/09-open-questions.md). Verified against source code in both repositories.

---

## 1. Questions Answered Directly by Source Code Verification

The following questions from the initial frontend and backend analysis documents have been definitively resolved through direct inspection of the codebase.

---

### Q1: Does the backend support editing an existing ticket (`PUT /api/v1/tickets/{id}`), and what is its contract?
* **Origin**: Frontend Open Question #1 & Backend Open Question #4
* **Code Answer**: **YES**.
  - **Controller**: [`TicketController.java#L78`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/TicketController.java#L78):
    ```java
    @PutMapping("/{id}")
    public ResponseEntity<TicketResponse> updateTicket(@RequestBody TicketRequest ticketRequest, @PathVariable Long id)
    ```
  - **Service**: [`TicketServiceImpl.java#L235`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/service/impl/TicketServiceImpl.java#L235) updates `ticketTitle`, `description`, `category`, `subCategory`, `priority`, `assignedTo`, and `imageUrls`.
  - **Constraints**: If `ticket.getStatus() == Status.COMPLETED`, throws `IllegalArgumentException("Completed ticket cannot be modified")`. If `ticket.isDeleted()`, throws `IllegalStateException`.
  - **Security Bug in Current Code**: There is **no creator ownership check** (`createdBy == currentUserId`) in `TicketServiceImpl.updateTicket`. Any authenticated caller (`USER`, `TECHNICIAN`, `ADMIN`) can overwrite any non-completed ticket.
  - **Frontend Status**: The web frontend never implemented a mutation for `PUT /tickets/{id}`. Web route `/tickets/[id]/edit` mistakenly calls `POST /tickets`, creating duplicate tickets.

---

### Q2: Will Spring Boot CORS configuration block direct Flutter mobile HTTP requests?
* **Origin**: Frontend Open Question #2
* **Code Answer**: **NO for native mobile; YES for Flutter Web**.
  - **Code Citation**: [`CorsConfig.java#L16`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/config/CorsConfig.java#L16) restricts browser origins to `localhost:3000` and the Railway web URL.
  - **Native Mobile Reality**: Native mobile applications (Android/iOS) communicate via native platform sockets using `Dio` or `HttpClient`. They do not send browser `Origin` headers and do not enforce browser CORS policies.
  - **Conclusion**: Native Flutter apps can call the Spring Boot API directly without CORS errors. If building for Flutter Web, the web hosting domain must be added to `CorsConfig.java`.

---

### Q3: Does the backend support server-side pagination parameters (`page`, `size`)?
* **Origin**: Frontend Open Question #3 & Backend Open Question #11
* **Code Answer**: **YES for tickets & activity; NO for users, chat, categories, departments**.
  - **Supported Endpoints**:
    - `GET /api/v1/tickets` ([TicketController.java#L38](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/TicketController.java#L38))
    - `GET /api/v1/tickets/history` ([TicketController.java#L48](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/TicketController.java#L48))
    - `GET /api/v1/tickets/my` ([TicketController.java#L60](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/TicketController.java#L60))
    - `GET /api/v1/tickets/activity` ([TicketController.java#L113](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/TicketController.java#L113))
    All accept `@RequestParam(defaultValue = "0") int page` and `@RequestParam(defaultValue = "10") int size`, returning Spring Data `Page<T>`.
  - **Unpaginated Endpoints**: `GET /api/v1/users`, `GET /api/v1/tickets/{id}/messages`, `GET /api/v1/categories`, `GET /api/v1/departments` return raw `List<T>`.
  - **Web Frontend Bug**: The web frontend never passes `page` or `size`, so backend defaults to 10 items. The web app extracts `response.content` and discards pagination metadata, resulting in silent data truncation at 10 items.

---

### Q4: Does the backend support server-side search or status filtering via query parameters?
* **Origin**: Frontend Open Question #4
* **Code Answer**: **NO**.
  - **Code Citation**: Inspecting [`TicketController.java#L37-L64`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/TicketController.java#L37-L64) confirms that only `page` and `size` parameters exist.
  - Queries are hardcoded:
    - `getAll`: `status IN ('PENDING', 'IN_PROGRESS')`
    - `getMyTickets`: `createdBy = :userId AND status IN ('PENDING', 'IN_PROGRESS')`
    - `getHistory`: `status = 'COMPLETED'`
  - There is no support for `?status=`, `?priority=`, or `?search=`. The web app performed all filtering in-memory using JavaScript `.filter()`.

---

### Q5: Does the backend support native WebSocket STOMP, and is JWT authentication required?
* **Origin**: Frontend Open Question #5 & Backend Open Questions #9, #10
* **Code Answer**:
  - **SockJS vs Native**: Backend [`WebSocketConfig.java#L20`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/config/WebSocketConfig.java#L20) registers:
    ```java
    registry.addEndpoint("/ws-chat").setAllowedOriginPatterns("*").withSockJS();
    ```
    It **only** enables SockJS. Native Dart clients fail unless a raw endpoint is added. (Backend change B-04 is required).
  - **Authentication**: In [`SecurityConfig.java#L72`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/security/SecurityConfig.java#L72):
    ```java
    .requestMatchers("/ws-chat/**").permitAll()
    ```
    There is **no** STOMP `ChannelInterceptor` or JWT validation configured. The WebSocket broker accepts unauthenticated connections and subscriptions.

---

### Q6: What do `monthlyStats.received` and `due` represent in the backend?
* **Origin**: Frontend Open Question #13 (Secondary)
* **Code Answer**:
  - **Code Citation**: [`TicketServiceImpl.java#L345-L349`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/service/impl/TicketServiceImpl.java#L345-L349):
    ```java
    if (status == Status.COMPLETED) {
        received[month - 1] += count;
    } else if (status == Status.PENDING || status == Status.IN_PROGRESS) {
        due[month - 1] += count;
    }
    ```
  - **Verification**: `received` represents **COMPLETED** tickets. `due` represents **PENDING + IN_PROGRESS** tickets. The web frontend chart labels ("Completed" vs "Pending") are accurate.

---

### Q7: Can a completed ticket be reopened in the backend?
* **Origin**: Backend Open Question #6
* **Code Answer**: **NO**.
  - **Code Citation**: [`TicketServiceImpl.java#L205`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/service/impl/TicketServiceImpl.java#L205):
    ```java
    if (ticket.getStatus() == Status.COMPLETED) {
        throw new IllegalArgumentException("Completed ticket cannot be updated");
    }
    ```
  - Status progression is strictly unidirectional: `PENDING -> IN_PROGRESS -> COMPLETED`. A completed ticket cannot transition to any other status.

---

### Q8: How does technician assignment work upon status transition?
* **Origin**: Backend Open Question #7
* **Code Answer**:
  - **Code Citation**: [`TicketServiceImpl.java#L214-L218`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/service/impl/TicketServiceImpl.java#L214-L218):
    ```java
    if (newStatus == Status.IN_PROGRESS && ticket.getAssignedTo() == null && currentUserId != null) {
        User currentUser = userRepository.findById(currentUserId).orElse(null);
        ticket.setAssignedTo(currentUser);
    }
    ```
  - When transitioning from `PENDING` to `IN_PROGRESS`, if the ticket is unassigned, the backend **automatically assigns the calling user** as the technician.

---

### Q9: Why does selecting a profile photo on the web not persist to the backend?
* **Origin**: Frontend Open Question #7 & #8
* **Code Answer**:
  - In [`ProfileView.tsx#L29`](file:///D:/Course%20Wing/Final/fix/helpdesk-frontend/src/components/Profile/ProfileView.tsx#L29) and [`upload-photo.tsx`](file:///D:/Course%20Wing/Final/fix/helpdesk-frontend/src/components/Settings/upload-photo.tsx), selecting a photo creates a temporary local browser blob (`URL.createObjectURL(file)`). No network mutation is triggered.
  - Furthermore, while `POST /api/v1/images/upload` exists, saving the resulting URL to a user profile requires `PUT /api/v1/users/{id}`, which is restricted to `ROLE_ADMIN` in [`SecurityConfig.java#L53`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/security/SecurityConfig.java#L53). Non-admin users get HTTP 403 Forbidden.

---

### Q10: What is the status of the Static Calendar component (`/calendar`)?
* **Origin**: Frontend Open Question #11 (Secondary)
* **Code Answer**: **Dead code / Exclude from mobile**.
  - **Code Citation**: [`src/app/(Dashboard)/calendar/page.tsx`](file:///D:/Course%20Wing/Final/fix/helpdesk-frontend/src/app/(Dashboard)/calendar/page.tsx) is not linked anywhere in the navigation sidebar or header. It renders hardcoded dummy events with no backend backing.

---

### Q11: Does the backend support custom dynamic form fields per category?
* **Origin**: Frontend Open Question #12 (Secondary)
* **Code Answer**: **NO**.
  - **Code Citation**: [`Category.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/model/Category.java) and [`Ticket.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/model/Ticket.java) contain fixed relational fields. There is no schema or JSON column for custom dynamic category form fields.

---

### Q12: How does Logout work, and why were refresh tokens persisting?
* **Origin**: Code Discovery during Auth Cross-Check
* **Code Answer**:
  - In [`AuthController.java#L60-L63`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/AuthController.java#L60-L63):
    ```java
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestBody(required = false) RefreshTokenRequest request) {
        if (request != null && request.refreshToken() != null) {
            refreshTokenService.deleteByToken(request.refreshToken());
        }
        return ResponseEntity.ok().build();
    }
    ```
  - The backend only deletes the refresh token from PostgreSQL if the client sends `{ "refreshToken": "..." }` in the request body.
  - In [`authApi.ts#L61`](file:///D:/Course%20Wing/Final/fix/helpdesk-frontend/src/redux/feature/auth/authApi.ts#L61), the web frontend sends an empty body (`{}`), so the token is never revoked on logout.
  - **Flutter Fix**: Flutter must send `{ "refreshToken": "<token>" }`.

---

### Q13: What happened to DebugController (`/api/v1/debug/**`)?
* **Origin**: Backend Analysis GAP-01 vs Git History
* **Code Answer**:
  - Backend docs (`03-endpoints.md`, `06-mobile-gap-analysis.md`) documented `DebugController` as an active blocker exposing tickets publicly.
  - Git inspection confirms `DebugController.java` was **deleted in commit `aa20b7b`** ("deleted missing file").
  - However, [`SecurityConfig.java#L46`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/security/SecurityConfig.java#L46) still contains `.requestMatchers("/api/v1/debug/**").permitAll()`. The route is dead configuration returning HTTP 404, but should be cleaned up.

---

## 2. The Top 10 Critical Questions the User Must Answer

The following 10 architectural and product questions **cannot** be answered by reading the code alone. They represent business rules, operational policies, and scoping decisions required from project stakeholders.

---

### 1. User Registration Strategy
* **Current Code**: Only an Administrator can create users via `POST /api/v1/users`. No self-service registration endpoint exists.
* **Question for You**: Is Helpdesk strictly an internal corporate portal where employee accounts are pre-provisioned by IT administrators, or must we implement public self-service registration (`POST /api/v1/auth/register`) for the mobile app?
* **If self-registration is required**: Should newly registered accounts default to role `USER`, and is department assignment mandatory or optional during signup?

---

### 2. Account Recovery & Password Reset Flow
* **Current Code**: No forgot-password or password-reset API exists. The web "Forgot password?" button links to `#`.
* **Question for You**: How should locked-out mobile users recover their accounts?
  - *Option A*: Implement backend password recovery endpoints (`POST /api/v1/auth/forgot-password` and `POST /api/v1/auth/reset-password`) using email OTP verification.
  - *Option B*: Launch a native phone dialer or email client linking directly to the corporate IT Helpdesk support team.

---

### 3. Self-Service Profile & Password Updates
* **Current Code**: `PUT /api/v1/users/{id}` is restricted to `ROLE_ADMIN`. Normal users and technicians cannot change their own password, phone number, or profile photo.
* **Question for You**: Should regular users and technicians be allowed to update their own profile information and change their password directly from the mobile app settings? (Requires adding `PUT /api/v1/users/me` and `PUT /api/v1/users/me/password`).

---

### 4. Multi-Device Session Invalidation Policy
* **Current Code**: When a user logs in, a new refresh token is inserted into `refresh_token`. Older refresh tokens for that user remain valid until their 7-day expiration.
* **Question for You**: Does the business allow concurrent logins across multiple devices (e.g. mobile app + web browser simultaneously), or should logging into a new device automatically invalidate all previous refresh tokens for that user?

---

### 5. Ticket Modification Permissions & Ownership Rules
* **Current Code**: `PUT /api/v1/tickets/{id}` allows any authenticated user (`USER`, `TECHNICIAN`, `ADMIN`) to modify any non-completed ticket, regardless of who created or is assigned to it.
* **Question for You**: What should the authorization boundary be for ticket editing?
  - Can regular users edit a ticket after submission, and if so, only while `PENDING`?
  - Should editing be restricted strictly to the creator (`createdBy == currentUserId`) and assigned technician?
  - Or should tickets become completely immutable once submitted, allowing updates only via chat comments?

---

### 6. Ticket Deletion Policy
* **Current Code**: `DELETE /api/v1/tickets/{id}` soft-deletes a ticket and is permitted to all authenticated roles (`ADMIN`, `USER`, `TECHNICIAN`) in `SecurityConfig.java#L59`.
* **Question for You**: Should regular employees or field technicians have permission to delete tickets, or should ticket deletion be restricted strictly to `ROLE_ADMIN`?

---

### 7. Ticket Lifecycle & Reopening Policy
* **Current Code**: Status progression is strictly one-way (`PENDING -> IN_PROGRESS -> COMPLETED`). Completed tickets throw an exception if any status change is attempted.
* **Question for You**: Can a user or technician reopen a completed ticket if the underlying issue reoccurs (e.g. `COMPLETED -> IN_PROGRESS`), or must they submit a brand new ticket?

---

### 8. Push Notifications (FCM) Integration Scope
* **Current Code**: No push notification service exists. The system only delivers notifications via active STOMP WebSocket subscriptions or polling `GET /api/v1/tickets/activity`.
* **Question for You**: Should native push notifications (Firebase Cloud Messaging / Apple APNs) be a mandatory requirement for the Phase 1 mobile release, or can it be deferred to Phase 2, relying on in-app activity feeds for MVP?

---

### 9. Technician Ticket Assignment & Reassignment Workflow
* **Current Code**: Transitioning a ticket from `PENDING` to `IN_PROGRESS` automatically assigns the calling user as the technician.
* **Question for You**: Can a technician reassign an in-progress ticket to a different colleague if they need specialized assistance, or can only an `ADMIN` reassign tickets?

---

### 10. Timezone Standardization Policy
* **Current Code**: The web frontend hardcodes all date/time formatting to `"Asia/Phnom_Penh"` (UTC+7, Cambodia). Backend timestamps are transmitted as `LocalDateTime` without UTC offset (`Z`).
* **Question for You**: Should the mobile application continue forcing all timestamps to `Asia/Phnom_Penh` for organizational uniformity, or should timestamps display in the user device's local timezone?
