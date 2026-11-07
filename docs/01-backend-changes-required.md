# Required Backend Changes & Remediation Roadmap

> **Target**: Spring Boot Backend Engineering Team  
> **Source Verification**: Derived directly from code analysis in [`helpdesk`](file:///D:/Course%20Wing/Final/fix/helpdesk) to resolve integration failures, mobile crashes, and architectural blockers before Flutter client implementation.

---

## 1. Executive Summary & Priority Classification

The backend requires targeted changes before and during mobile app development. These are categorized into three severity levels:

1. **BLOCKER (Must be fixed before Flutter development starts)**: Critical functional bugs, fatal crashes on standard flows, security leaks, and transport incompatibilities that prevent mobile authentication, messaging, or basic operations.
2. **IMPORTANT (Must be fixed during Sprint 1-2)**: Data validation, error handling standardization, server-side filtering, and performance optimizations required for production mobile readiness.
3. **NICE TO HAVE (Post-MVP / Polish)**: Enhancements for self-service user management, automated schema docs, and architectural housekeeping.

---

## 2. BLOCKER Items (Fix Before Mobile Kick-off)

---

### B-01: NullPointerException on Token Refresh when User Department is Null
* **Severity**: **BLOCKER**
* **File to Change**: [`src/main/java/com/zaby/helpdesk/controller/AuthController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/AuthController.java#L52)
* **Root Cause**:
  In `AuthController.java` line 52:
  ```java
  tokenEntity.getUser().getDepartment().getId()
  ```
  If an administrator creates a user without an assigned department, or if a user's department is null, calling `.getId()` throws a fatal `NullPointerException`. The client receives HTTP 500 instead of a refreshed token. The user is permanently locked out until their access token expires and they must log in again from scratch.
* **Impact on Flutter**:
  Flutter's Dio interceptor relies on `POST /api/v1/auth/refresh` when any 401 error occurs. Receiving HTTP 500 will terminate the user session and redirect them to the login screen repeatedly.
* **Exact Fix**:
  In [`AuthController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/AuthController.java#L52), wrap the department call with a null check:
  ```java
  Long departmentId = (tokenEntity.getUser().getDepartment() != null) 
          ? tokenEntity.getUser().getDepartment().getId() 
          : null;

  return ResponseEntity.ok(new AuthResponse(
          tokenEntity.getUser().getEmail(),
          "Token refreshed",
          tokenEntity.getUser().getFirstName(),
          tokenEntity.getUser().getLastName(),
          departmentId,
          tokenEntity.getUser().getRole(),
          newAccessToken,
          refreshToken
  ));
  ```

---

### B-02: `AuthResponse` Lacks User ID and Avatar URL
* **Severity**: **BLOCKER**
* **Files to Change**:
  1. [`src/main/java/com/zaby/helpdesk/dto/response/AuthResponse.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/dto/response/AuthResponse.java)
  2. [`src/main/java/com/zaby/helpdesk/service/impl/AuthServiceImpl.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/service/impl/AuthServiceImpl.java#L50-L59)
  3. [`src/main/java/com/zaby/helpdesk/controller/AuthController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/AuthController.java#L47-L56)
* **Root Cause**:
  `AuthResponse` currently contains:
  ```java
  public record AuthResponse(
      String email, String message, String firstName, String lastName,
      Long departmentId, Role role, String accessToken, String refreshToken
  )
  ```
  It does **not** return `userId` (or `id`) or `imageUrl`.
* **Impact on Flutter**:
  When a user signs in, the mobile client must immediately know their user `id` to:
  1. Identify the sender in STOMP chat messages (`senderId`). (In the web app, this bug caused `senderId` to default to `0`).
  2. Filter personal ticket lists.
  3. Populate local profile state without requiring a second synchronous HTTP roundtrip.
* **Exact Fix**:
  Update `AuthResponse.java`:
  ```java
  package com.zaby.helpdesk.dto.response;

  import com.zaby.helpdesk.enumeration.Role;

  public record AuthResponse(
          Long id,
          String email,
          String message,
          String firstName,
          String lastName,
          String imageUrl,
          Long departmentId,
          Role role,
          String accessToken,
          String refreshToken
  ) {}
  ```
  Update `AuthServiceImpl.java` line 50:
  ```java
  return new AuthResponse(
          userDetails.getUser().getId(),
          userDetails.getUsername(),
          "Login successful",
          userDetails.getFirstName(),
          userDetails.getLastName(),
          userDetails.getUser().getImageUrl(),
          userDetails.getDepartmentId(),
          userDetails.getUser().getRole(),
          accessToken,
          refreshToken.getToken()
  );
  ```
  Update `AuthController.java` line 47 accordingly.

---

### B-03: Hardcoded JWT Secret Key in Plaintext Source Code
* **Severity**: **BLOCKER (Security)**
* **Files to Change**:
  1. [`src/main/java/com/zaby/helpdesk/security/JwtService.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/security/JwtService.java#L15)
  2. [`src/main/resources/application.properties`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/resources/application.properties)
* **Root Cause**:
  In `JwtService.java` line 15:
  ```java
  private final String SECRET = "mysecretkeymysecretkeymysecretkey123";
  ```
  The HMAC SHA-256 signing secret is hardcoded in the public Git repository. Anyone with access to the code can forge administrator JWT tokens with arbitrary claims and bypass authentication.
* **Exact Fix**:
  In `application.properties`, configure:
  ```properties
  jwt.secret=${JWT_SECRET:dGhpcy1pcy1hLXNlY3VyZS0yNTYtYml0LXNlY3JldC1rZXktZm9yLWhlbHBkZXNrLWFwcA==}
  jwt.expiration-ms=900000
  ```
  In `JwtService.java`:
  ```java
  @Value("${jwt.secret}")
  private String secret;
  ```

---

### B-04: Enable Raw WebSocket Endpoint for Native Mobile STOMP Clients
* **Severity**: **BLOCKER**
* **File to Change**: [`src/main/java/com/zaby/helpdesk/config/WebSocketConfig.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/config/WebSocketConfig.java#L20)
* **Root Cause**:
  `WebSocketConfig.java` currently configures:
  ```java
  @Override
  public void registerStompEndpoints(StompEndpointRegistry registry) {
      registry.addEndpoint("/ws-chat").setAllowedOriginPatterns("*").withSockJS();
  }
  ```
  It **only** registers SockJS transport emulation (`.withSockJS()`). Flutter mobile applications run native Dart runtimes and use native WebSocket STOMP packages (e.g. `stomp_dart_client`). Native Dart sockets cannot process browser SockJS HTTP handshake frames (`/info`, iframe transport).
* **Impact on Flutter**:
  The Flutter STOMP client fails during the initial connection handshake with error `WebSocketChannelException: Handshake failed`.
* **Exact Fix**:
  In [`WebSocketConfig.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/config/WebSocketConfig.java#L19-L21), register both the raw WebSocket endpoint and the SockJS fallback:
  ```java
  @Override
  public void registerStompEndpoints(StompEndpointRegistry registry) {
      // Raw WebSocket endpoint for Flutter mobile and native clients
      registry.addEndpoint("/ws-chat")
              .setAllowedOriginPatterns("*");

      // SockJS fallback endpoint for web browser compatibility
      registry.addEndpoint("/ws-chat")
              .setAllowedOriginPatterns("*")
              .withSockJS();
  }
  ```

---

### B-05: Service RuntimeExceptions Masked as Generic HTTP 500 Internal Server Error
* **Severity**: **BLOCKER**
* **Files to Change**:
  1. [`src/main/java/com/zaby/helpdesk/exception/GlobalExceptionHandler.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/exception/GlobalExceptionHandler.java)
  2. [`src/main/java/com/zaby/helpdesk/service/impl/UserServiceImpl.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/service/impl/UserServiceImpl.java#L33)
  3. [`src/main/java/com/zaby/helpdesk/service/impl/DepartmentServiceImpl.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/service/impl/DepartmentServiceImpl.java#L32)
  4. [`src/main/java/com/zaby/helpdesk/service/impl/TicketServiceImpl.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/service/impl/TicketServiceImpl.java#L198)
* **Root Cause**:
  Backend services throw raw `RuntimeException`, `IllegalArgumentException`, and `IllegalStateException`:
  - `UserServiceImpl`: `throw new RuntimeException("User not found")`, `throw new RuntimeException("Email already exists")`
  - `TicketServiceImpl`: `throw new IllegalArgumentException("Completed ticket cannot be modified")`
  Because `GlobalExceptionHandler.java` does not have explicit `@ExceptionHandler` methods for these exceptions, they fall into `handleGenericException(Exception ex)`:
  ```java
  @ExceptionHandler(Exception.class)
  public ResponseEntity<ErrorResponse> handleGenericException(Exception ex) {
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
              .body(new ErrorResponse(HttpStatus.INTERNAL_SERVER_ERROR.value(), "An unexpected error occurred", LocalDateTime.now()));
  }
  ```
* **Impact on Flutter**:
  - Requesting a missing user or ticket returns `500 INTERNAL_SERVER_ERROR` instead of `404 NOT_FOUND`.
  - Creating a user with an existing email returns `500 INTERNAL_SERVER_ERROR` instead of `409 CONFLICT`.
  - Attempting an invalid status transition returns `500 INTERNAL_SERVER_ERROR` instead of `400 BAD_REQUEST`.
  The mobile app cannot distinguish real server crashes from simple client validation errors, breaking user error feedback.
* **Exact Fix**:
  Add explicit handlers to [`GlobalExceptionHandler.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/exception/GlobalExceptionHandler.java):
  ```java
  @ExceptionHandler(IllegalArgumentException.class)
  public ResponseEntity<ErrorResponse> handleIllegalArgumentException(IllegalArgumentException ex) {
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body(new ErrorResponse(HttpStatus.BAD_REQUEST.value(), ex.getMessage(), LocalDateTime.now()));
  }

  @ExceptionHandler(IllegalStateException.class)
  public ResponseEntity<ErrorResponse> handleIllegalStateException(IllegalStateException ex) {
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body(new ErrorResponse(HttpStatus.BAD_REQUEST.value(), ex.getMessage(), LocalDateTime.now()));
  }

  @ExceptionHandler(RuntimeException.class)
  public ResponseEntity<ErrorResponse> handleRuntimeException(RuntimeException ex) {
      // Check for common not found patterns
      if (ex.getMessage() != null && ex.getMessage().toLowerCase().contains("not found")) {
          return ResponseEntity.status(HttpStatus.NOT_FOUND)
                  .body(new ErrorResponse(HttpStatus.NOT_FOUND.value(), ex.getMessage(), LocalDateTime.now()));
      }
      return ResponseEntity.status(HttpStatus.BAD_REQUEST)
              .body(new ErrorResponse(HttpStatus.BAD_REQUEST.value(), ex.getMessage(), LocalDateTime.now()));
  }
  ```
  Replace `throw new RuntimeException("Email already exists")` in `UserServiceImpl` with `throw new BusinessException("Email already exists")`.

---

## 3. IMPORTANT Items (Sprint 1-2 Fixes)

---

### I-01: Add `@Valid` Annotations on Controller Request Bodies
* **Severity**: **IMPORTANT**
* **Files to Change**:
  1. [`src/main/java/com/zaby/helpdesk/controller/TicketController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/TicketController.java#L24)
  2. [`src/main/java/com/zaby/helpdesk/controller/UserController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/UserController.java#L25)
  3. [`src/main/java/com/zaby/helpdesk/controller/CategoryController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/CategoryController.java#L23)
  4. [`src/main/java/com/zaby/helpdesk/controller/DepartmentController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/DepartmentController.java#L21)
* **Root Cause**:
  `TicketRequest.java` declares `@NotBlank String ticketTitle` and `@NotNull Priority priority`. However, in `TicketController.java`:
  ```java
  @PostMapping
  public ResponseEntity<TicketResponse> createTicket(@RequestBody TicketRequest ticketRequest)
  ```
  The `@Valid` annotation is **missing**. Jakarta Bean Validation is completely skipped.
* **Exact Fix**:
  Add `@Valid` to every `@RequestBody` parameter across all controllers:
  ```java
  @PostMapping
  public ResponseEntity<TicketResponse> createTicket(@Valid @RequestBody TicketRequest ticketRequest)
  ```

---

### I-02: Clean Up Dead `/api/v1/debug/**` Permitted Route in SecurityConfig
* **Severity**: **IMPORTANT**
* **File to Change**: [`src/main/java/com/zaby/helpdesk/security/SecurityConfig.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/security/SecurityConfig.java#L46)
* **Root Cause**:
  Line 46 has:
  ```java
  .requestMatchers("/api/v1/debug/**").permitAll()
  ```
  `DebugController.java` was previously removed in commit `aa20b7b`, but the permitAll rule remains active in security configuration.
* **Exact Fix**:
  Delete line 46 from `SecurityConfig.java`.

---

### I-03: Add Server-Side Query Parameters (`status`, `search`, `priority`) to Ticket Feeds
* **Severity**: **IMPORTANT**
* **Files to Change**:
  1. [`src/main/java/com/zaby/helpdesk/controller/TicketController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/TicketController.java#L37-L64)
  2. [`src/main/java/com/zaby/helpdesk/service/TicketService.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/service/TicketService.java)
  3. [`src/main/java/com/zaby/helpdesk/service/impl/TicketServiceImpl.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/service/impl/TicketServiceImpl.java)
  4. [`src/main/java/com/zaby/helpdesk/repository/TicketRepository.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/repository/TicketRepository.java)
* **Root Cause**:
  Currently, `GET /api/v1/tickets`, `GET /api/v1/tickets/my`, and `GET /api/v1/tickets/history` only accept `page` and `size`. Status filtering and search strings are evaluated on the web using client-side JavaScript `.filter()`.
  On mobile devices using infinite scrolling, filtering client-side means records matching a search query on page 5 are invisible until the user scrolls through pages 1–4.
* **Exact Fix**:
  Add optional query parameters to controller methods:
  ```java
  @GetMapping
  public ResponseEntity<Page<TicketResponse>> getAll(
          @RequestParam(defaultValue = "0") int page,
          @RequestParam(defaultValue = "15") int size,
          @RequestParam(required = false) Status status,
          @RequestParam(required = false) Priority priority,
          @RequestParam(required = false) String search
  )
  ```
  Implement dynamic query filtering in Spring Data JPA using `JpaSpecificationExecutor<Ticket>` or query methods in `TicketRepository`.

---

### I-04: Add STOMP ChannelInterceptor for WebSocket Authentication
* **Severity**: **IMPORTANT (Security)**
* **File to Change**: [`src/main/java/com/zaby/helpdesk/config/WebSocketConfig.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/config/WebSocketConfig.java)
* **Root Cause**:
  `/ws-chat/**` is configured as `permitAll()`. There is no JWT authentication interceptor on the STOMP message channel. Anyone who knows the server URL can connect and subscribe to `/topic/ticket/{ticketId}` to read confidential ticket conversations.
* **Exact Fix**:
  Add a `ChannelInterceptor` in `WebSocketConfig.java` that intercepts `StompHeaderAccessor.getCommand() == StompCommand.CONNECT` and validates the Bearer token passed in STOMP headers:
  ```java
  @Override
  public void configureClientInboundChannel(ChannelRegistration registration) {
      registration.interceptors(new ChannelInterceptor() {
          @Override
          public Message<?> preSend(Message<?> message, MessageChannel channel) {
              StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
              if (StompCommand.CONNECT.equals(accessor.getCommand())) {
                  String authHeader = accessor.getFirstNativeHeader("Authorization");
                  if (authHeader != null && authHeader.startsWith("Bearer ")) {
                      String token = authHeader.substring(7);
                      // validate token with jwtService and set SecurityContext
                  } else {
                      throw new AuthenticationCredentialsNotFoundException("Missing JWT Bearer token");
                  }
              }
              return message;
          }
      });
  }
  ```

---

### I-05: Standardize Date/Time Serialization to ISO-8601 UTC
* **Severity**: **IMPORTANT**
* **Files to Change**:
  1. [`src/main/java/com/zaby/helpdesk/dto/response/TicketResponse.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/dto/response/TicketResponse.java#L25-L28)
  2. [`src/main/java/com/zaby/helpdesk/model/AuditableCustom.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/model/AuditableCustom.java#L21)
* **Root Cause**:
  `TicketResponse` uses `@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")`, producing `"2026-10-22 10:15:00"`.
  All other responses (`UserResponse`, `NotificationResponse`, `ChatMessage`, `ErrorResponse`) emit ISO-8601 strings (`"2026-10-22T10:15:00"`). None include timezone offsets.
* **Impact on Flutter**:
  Requires multi-format date parsing in Dart. Without timezone offset, timestamps default to local device time, causing multi-hour clock skew.
* **Exact Fix**:
  Remove `@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")` from `TicketResponse.java` and `AuditableCustom.java`. Let Jackson serialize standard ISO-8601 strings (`yyyy-MM-dd'T'HH:mm:ss'Z'`), or configure in `application.properties`:
  ```properties
  spring.jackson.time-zone=UTC
  spring.jackson.date-format=iso-8601
  ```

---

### I-06: Standardize Error Response Payload Across All Controllers
* **Severity**: **IMPORTANT**
* **File to Change**: [`src/main/java/com/zaby/helpdesk/controller/ImageController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/ImageController.java#L25,L36)
* **Root Cause**:
  `ImageController.java` returns ad-hoc maps:
  `response.put("error", "File is missings"); return ResponseEntity.badRequest().body(response);`
  instead of returning `ErrorResponse(status, message, timestamp)`.
* **Exact Fix**:
  Update `ImageController.java` to return `ResponseEntity<?>` with `ErrorResponse`.

---

### I-07: Push Notification Device Token Endpoint
* **Severity**: **IMPORTANT**
* **New Files to Create**:
  1. `src/main/java/com/zaby/helpdesk/controller/NotificationTokenController.java`
  2. `src/main/java/com/zaby/helpdesk/model/DeviceToken.java`
* **Requirement**:
  Support tickets require real-time alerts when tickets are assigned, status changes, or chat replies arrive while the mobile app is backgrounded.
* **Proposed Endpoint**:
  `POST /api/v1/notifications/device-token`
  ```json
  {
    "deviceToken": "fcm_token_string_...",
    "platform": "ANDROID"
  }
  ```

---

### I-08: Add Pagination to Unbounded Endpoints (`Chat Messages` & `Users`)
* **Severity**: **IMPORTANT**
* **Files to Change**:
  1. [`src/main/java/com/zaby/helpdesk/controller/ChatController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/ChatController.java#L31)
  2. [`src/main/java/com/zaby/helpdesk/controller/UserController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/UserController.java#L49)
* **Root Cause**:
  `GET /api/v1/tickets/{ticketId}/messages` and `GET /api/v1/users` return raw `List<T>`. On active tickets with hundreds of messages or organizations with thousands of users, unpaginated payloads will cause mobile memory spikes and sluggish UI loading.
* **Exact Fix**:
  Add `Pageable` query parameters (`page`, `size`) to both endpoints.

---

## 4. NICE TO HAVE Items (Post-MVP Enhancements)

---

### N-01: User Self-Service Password Reset & Profile Update Endpoints
* **Severity**: **NICE TO HAVE**
* **Files to Change**:
  1. `src/main/java/com/zaby/helpdesk/controller/UserController.java`
  2. `src/main/java/com/zaby/helpdesk/controller/AuthController.java`
* **Enhancements**:
  - Add `PUT /api/v1/users/me` allowing users to update their `phoneNumber` and `imageUrl`.
  - Add `PUT /api/v1/users/me/password` taking `{ oldPassword, newPassword }`.
  - Add `POST /api/v1/auth/forgot-password` and `POST /api/v1/auth/reset-password`.

---

### N-02: Public User Self-Registration Endpoint
* **Severity**: **NICE TO HAVE**
* **File to Change**: `src/main/java/com/zaby/helpdesk/controller/AuthController.java`
* **Enhancement**:
  If public onboarding is required, add `POST /api/v1/auth/register` defaulting to role `USER`.

---

### N-03: Restrict `PUT /api/v1/tickets/{id}` and `DELETE /api/v1/tickets/{id}` with Ownership Checks
* **Severity**: **NICE TO HAVE**
* **Files to Change**:
  1. [`src/main/java/com/zaby/helpdesk/service/impl/TicketServiceImpl.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/service/impl/TicketServiceImpl.java#L235)
  2. [`src/main/java/com/zaby/helpdesk/security/SecurityConfig.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/security/SecurityConfig.java#L59)
* **Enhancement**:
  Ensure users can only edit or delete tickets they created (`createdBy == currentUserId`) and technicians can only edit tickets assigned to them. Restrict `DELETE` to `ROLE_ADMIN`.

---

### N-04: Fix Status Code on `DELETE /api/v1/users/{id}`
* **Severity**: **NICE TO HAVE**
* **File to Change**: [`src/main/java/com/zaby/helpdesk/controller/UserController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/UserController.java#L66)
* **Enhancement**:
  Change `return ResponseEntity.ok(userResponse);` to `return ResponseEntity.noContent().build();` (HTTP 204) to match REST conventions.

---

### N-05: OpenAPI 3.0 / Swagger UI Dependency Integration
* **Severity**: **NICE TO HAVE**
* **Files to Change**:
  1. [`pom.xml`](file:///D:/Course%20Wing/Final/fix/helpdesk/pom.xml)
  2. [`src/main/java/com/zaby/helpdesk/security/SecurityConfig.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/security/SecurityConfig.java)
* **Enhancement**:
  Add `org.springdoc:springdoc-openapi-starter-webmvc-ui:2.8.5` to generate interactive Swagger UI at `/swagger-ui.html` and OpenAPI JSON at `/v3/api-docs`.

---

### N-06: File Type (MIME) Validation on Supabase Image Upload
* **Severity**: **NICE TO HAVE**
* **Files to Change**:
  1. [`src/main/java/com/zaby/helpdesk/controller/ImageController.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/controller/ImageController.java#L22)
  2. [`src/main/java/com/zaby/helpdesk/service/SupabaseStorageService.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/service/SupabaseStorageService.java#L31)
* **Enhancement**:
  Validate `file.getContentType()` against permitted image MIME types (`image/jpeg`, `image/png`, `image/webp`) before uploading to cloud bucket.

---

### N-07: Automatic Soft Delete Filtering via `@SQLRestriction`
* **Severity**: **NICE TO HAVE**
* **Files to Change**:
  1. [`src/main/java/com/zaby/helpdesk/model/Ticket.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/model/Ticket.java)
  2. [`src/main/java/com/zaby/helpdesk/model/User.java`](file:///D:/Course%20Wing/Final/fix/helpdesk/src/main/java/com/zaby/helpdesk/model/User.java)
* **Enhancement**:
  Add Hibernate 7 `@SQLRestriction("deleted = false")` on entities to guarantee soft-deleted records are never leaked across any query.

---

## 5. Summary Matrix & Remediation Timeline

| ID | Issue Title | Severity | Target File | Impact on Flutter |
|---|---|---|---|---|
| **B-01** | Token Refresh NPE on Null Department | **BLOCKER** | `AuthController.java` | Session refresh crashes with 500 |
| **B-02** | Missing User ID in `AuthResponse` | **BLOCKER** | `AuthResponse.java` | User ID undefined; chat broken |
| **B-03** | Hardcoded JWT Secret Key | **BLOCKER** | `JwtService.java` | Critical vulnerability / token forgery |
| **B-04** | Raw WebSocket STOMP Endpoint | **BLOCKER** | `WebSocketConfig.java` | Flutter STOMP cannot connect |
| **B-05** | Service Exceptions Masked as 500 | **BLOCKER** | `GlobalExceptionHandler.java` | 400/404/409 errors hidden |
| **I-01** | Missing `@Valid` on Controllers | **IMPORTANT** | Controllers | Invalid payloads bypass validation |
| **I-02** | Dead `/api/v1/debug/**` Config | **IMPORTANT** | `SecurityConfig.java` | Obsolete configuration cleanup |
| **I-03** | Server-Side Filtering & Search | **IMPORTANT** | `TicketController.java` | Mobile infinite scroll cannot filter |
| **I-04** | STOMP ChannelInterceptor Auth | **IMPORTANT** | `WebSocketConfig.java` | Unauthenticated chat eavesdropping |
| **I-05** | Standardize ISO-8601 UTC Dates | **IMPORTANT** | `TicketResponse.java` | Date parsing crash & clock skew |
| **I-06** | Standardize Image Error Format | **IMPORTANT** | `ImageController.java` | Inconsistent Dio error parsing |
| **I-07** | Push Token Registration Endpoint | **IMPORTANT** | New Controller/Service | Background notifications unavailable |
| **I-08** | Pagination for Chat & Users | **IMPORTANT** | `ChatController.java` | Mobile memory lag on large threads |
| **N-01** | Password Reset & Profile Update | **NICE TO HAVE**| `UserController.java` | Improved mobile self-service |
| **N-02** | Self-Service Registration | **NICE TO HAVE**| `AuthController.java` | Public user registration |
| **N-03** | Ticket Edit/Delete Ownership | **NICE TO HAVE**| `TicketServiceImpl.java` | Authorization boundary integrity |
| **N-04** | User Delete 204 Status Code | **NICE TO HAVE**| `UserController.java` | REST specification consistency |
| **N-05** | Springdoc OpenAPI / Swagger | **NICE TO HAVE**| `pom.xml` | Automated Dart model generation |
| **N-06** | Image MIME Type Validation | **NICE TO HAVE**| `ImageController.java` | Prevents non-image file uploads |
| **N-07** | `@SQLRestriction` Soft Delete | **NICE TO HAVE**| `Ticket.java`, `User.java` | Prevents accidental deleted leaks |
