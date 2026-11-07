# API Contract Specification

> **Base URL**:
> - Android Emulator: `http://10.0.2.2:8080/api/v1`
> - Host Machine / Web: `http://localhost:8080/api/v1`
> - Real Device / Wi-Fi LAN: `http://<YOUR_PC_LAN_IP>:8080/api/v1`
>
> **Protocol**: REST over HTTP + WebSocket (STOMP) at `/ws-chat`.

---

## 1. Authentication & Security Mechanism

- **Authentication Type**: Stateless JSON Web Token (JWT) using HS256 algorithm.
- **Access Token Duration**: 15 minutes (900,000 ms).
- **Transport**: Standard HTTP Header `Authorization: Bearer <accessToken>`.
- **Refresh Token Duration**: 7 days.
- **Refresh Mechanism**: Stored UUID in PostgreSQL table `refresh_token`. The client sends `POST /api/v1/auth/refresh` with `{ "refreshToken": "<uuid>" }` in the request body to obtain a fresh access token without re-entering credentials.
- **Roles**:
  - `ROLE_USER`: Regular employee submitting incidents and chatting with technicians.
  - `ROLE_TECHNICIAN`: Support technician triaging, accepting, and resolving tickets.
  - `ROLE_ADMIN`: Superuser with technician capabilities plus User and Department management.

---

## 2. Global Error Format

The backend returns standard JSON error responses:

### 2.1 Standard Error Format
```json
{
  "status": 404,
  "message": "Ticket not found",
  "timestamp": "2026-10-22T13:45:00.123456"
}
```

### 2.2 Validation Error Format
```json
{
  "status": 400,
  "message": "Validation failed",
  "timestamp": "2026-10-22T13:45:00.123456",
  "errors": {
    "ticketTitle": "must not be blank",
    "priority": "must not be null"
  }
}
```

### 2.3 Ad-hoc Image Upload Error
```json
{
  "error": "File is missings"
}
```

---

## 3. Data Enums & Constants

### 3.1 Ticket Status (`Status`)
- `PENDING`: Initial state when created by user.
- `IN_PROGRESS`: Ticket claimed/accepted by technician.
- `COMPLETED`: Ticket resolved/closed.

> Transition Rules: `PENDING -> IN_PROGRESS -> COMPLETED`. No rollback or edits allowed once `COMPLETED`.

### 3.2 Ticket Priority (`Priority`)
- `LOW`: Routine, low impact.
- `MEDIUM`: Standard operational issue.
- `HIGH`: Severe blocker or hardware outage.

### 3.3 Roles (`Role`)
- `ADMIN` (`ROLE_ADMIN`)
- `TECHNICIAN` (`ROLE_TECHNICIAN`)
- `USER` (`ROLE_USER`)

---

## 4. Pagination Conventions

Paginated collections use Spring Data `Page<T>` with query parameters:
- `page`: 0-indexed page number (default: 0).
- `size`: number of records per page (default: 10, web uses 7).

Response Envelope:
```json
{
  "content": [ ... ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 10
  },
  "totalPages": 3,
  "totalElements": 25,
  "last": false,
  "size": 10,
  "number": 0,
  "first": true,
  "empty": false
}
```

---

## 5. Endpoints Reference

### 5.1 Authentication (`/api/v1/auth`)

#### `POST /api/v1/auth/login`
- **Access**: Public
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "id": 1,
    "email": "user@example.com",
    "message": "Login successful",
    "firstName": "John",
    "lastName": "Doe",
    "imageUrl": "https://...",
    "departmentId": 1,
    "role": "USER",
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "e7b0bf34-7393-4a16-928f-7c15e47854a6"
  }
  ```

#### `POST /api/v1/auth/refresh`
- **Access**: Public
- **Request Body**:
  ```json
  {
    "refreshToken": "e7b0bf34-7393-4a16-928f-7c15e47854a6"
  }
  ```
- **Response `200 OK`**: Same shape as Login with renewed `accessToken`.

#### `POST /api/v1/auth/logout`
- **Access**: Public
- **Request Body**:
  ```json
  {
    "refreshToken": "e7b0bf34-7393-4a16-928f-7c15e47854a6"
  }
  ```
- **Response `200 OK`**: Empty body.

---

### 5.2 Users (`/api/v1/users`)

#### `GET /api/v1/users/me`
- **Access**: Authenticated (`USER`, `TECHNICIAN`, `ADMIN`)
- **Response `200 OK`**:
  ```json
  {
    "id": 12,
    "firstName": "John",
    "lastName": "Doe",
    "email": "user@example.com",
    "phoneNumber": "+1234567890",
    "imageUrl": "https://...",
    "role": "USER",
    "departmentId": 1,
    "departmentName": "IT",
    "createdAt": "2026-10-22T08:00:00",
    "updatedAt": "2026-10-22T08:00:00",
    "ticketsCreated": 5,
    "ticketsAssigned": 0,
    "ticketsResolved": 3,
    "ticketsOpen": 2
  }
  ```

#### `PUT /api/v1/users/me`
- **Access**: Authenticated (`USER`, `TECHNICIAN`, `ADMIN`)
- **Request Body** (all fields optional):
  ```json
  {
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "+85512345678",
    "imageUrl": "https://...",
    "password": "newOptionalPassword"
  }
  ```
- **Response `200 OK`**: Updated `UserResponse` with ticket metrics.

#### `GET /api/v1/users`
- **Access**: `ROLE_ADMIN`
- **Response `200 OK`**: `List<UserResponse>`

#### `GET /api/v1/users/{id}`
- **Access**: `ROLE_ADMIN`
- **Response `200 OK`**: `UserResponse`

#### `POST /api/v1/users`
- **Access**: `ROLE_ADMIN`
- **Request Body**:
  ```json
  {
    "firstName": "Jane",
    "lastName": "Smith",
    "email": "jane@example.com",
    "phoneNumber": "+123456789",
    "password": "tempPassword123",
    "imageUrl": null,
    "role": "TECHNICIAN",
    "departmentId": 1
  }
  ```
- **Response `201 CREATED`**: `UserResponse`

#### `PUT /api/v1/users/{id}`
- **Access**: `ROLE_ADMIN`
- **Request Body**: Same as `POST /api/v1/users`
- **Response `200 OK`**: `UserResponse`

#### `DELETE /api/v1/users/{id}`
- **Access**: `ROLE_ADMIN`
- **Response `200 OK`**: Soft-deletes user.

---

### 5.3 Tickets (`/api/v1/tickets`)

#### `POST /api/v1/tickets`
- **Access**: `USER`, `TECHNICIAN`, `ADMIN`
- **Request Body**:
  ```json
  {
    "ticketTitle": "Printer offline on Floor 2",
    "description": "The printer is completely unresponsive and flashing error 50.",
    "priority": "HIGH",
    "categoryId": 1,
    "subCategoryId": 4,
    "assignedTo": null,
    "imageUrls": [
      "https://abkxnzzffuojvumrhlrw.supabase.co/storage/v1/object/public/Image/uuid.png"
    ]
  }
  ```
- **Response `201 CREATED`**: Full `TicketResponse`.

#### `GET /api/v1/tickets`
- **Access**: `TECHNICIAN`, `ADMIN`
- **Query Params**: `page` (default 0), `size` (default 10)
- **Response `200 OK`**: `Page<TicketResponse>` containing non-completed active tickets.

#### `GET /api/v1/tickets/my`
- **Access**: `USER`, `TECHNICIAN`, `ADMIN`
- **Query Params**: `page` (default 0), `size` (default 10)
- **Response `200 OK`**: `Page<TicketResponse>` for active tickets created by caller.

#### `GET /api/v1/tickets/history`
- **Access**: `USER`, `TECHNICIAN`, `ADMIN`
- **Query Params**: `page` (default 0), `size` (default 10)
- **Response `200 OK`**: `Page<TicketResponse>` for `COMPLETED` tickets (scoped to role).

#### `GET /api/v1/tickets/{id}`
- **Access**: `USER`, `TECHNICIAN`, `ADMIN`
- **Response `200 OK`**:
  ```json
  {
    "id": 1,
    "ticketTitle": "Printer offline on Floor 2",
    "description": "The printer is completely unresponsive...",
    "priority": "HIGH",
    "status": "PENDING",
    "categoryId": 1,
    "categoryName": "Hardware",
    "subCategoryId": 4,
    "subCategoryName": "Printers",
    "assignedTo": null,
    "assignedName": null,
    "logs": [
      {
        "id": 1,
        "ticketId": 1,
        "fromStatus": null,
        "toStatus": "PENDING",
        "changedById": 12,
        "changedByName": "John Doe",
        "remark": "Ticket Created",
        "changedAt": "2026-10-22 10:15:00"
      }
    ],
    "createdBy": 12,
    "createdByName": "John Doe",
    "createdAt": "2026-10-22 10:15:00",
    "completedAt": null,
    "imageUrls": [
      "https://...supabase.co/storage/v1/object/public/Image/uuid.png"
    ]
  }
  ```

#### `PATCH /api/v1/tickets/{id}/status`
- **Access**: `TECHNICIAN`, `ADMIN`
- **Request Body**:
  ```json
  {
    "status": "IN_PROGRESS",
    "remark": "Accepted ticket by technician"
  }
  ```
- **Response `200 OK`**: Updated `TicketResponse`.

#### `PUT /api/v1/tickets/{id}`
- **Access**: `USER`, `TECHNICIAN`, `ADMIN`
- **Request Body**: Same as `TicketRequest`.
- **Response `200 OK`**: Updated `TicketResponse`.

#### `DELETE /api/v1/tickets/{id}`
- **Access**: `USER`, `TECHNICIAN`, `ADMIN`
- **Response `204 NO CONTENT`**: Soft-deletes ticket.

#### `GET /api/v1/tickets/stats`
- **Access**: `TECHNICIAN`, `ADMIN`
- **Response `200 OK`**:
  ```json
  {
    "totalTickets": 42,
    "pendingTickets": 10,
    "inProgressTickets": 7,
    "completedTickets": 25,
    "totalUsers": 14
  }
  ```

#### `GET /api/v1/tickets/stats/monthly`
- **Access**: `TECHNICIAN`, `ADMIN`
- **Query Params**: `year` (optional, default current year)
- **Response `200 OK`**:
  ```json
  {
    "received": [2, 4, 1, 0, 5, 3, 2, 8, 4, 1, 0, 0],
    "due": [1, 2, 0, 0, 1, 1, 0, 2, 1, 0, 0, 0]
  }
  ```

#### `GET /api/v1/tickets/activity`
- **Access**: All authenticated roles
- **Query Params**: `page` (default 0), `size` (default 10)
- **Response `200 OK`**: `Page<NotificationResponse>`

---

### 5.4 Categories (`/api/v1/categories`)

#### `GET /api/v1/categories`
- **Access**: Authenticated
- **Response `200 OK`**: `List<CategoryResponse>`
  ```json
  [
    {
      "id": 1,
      "name": "Hardware",
      "description": "Physical devices",
      "parentId": null,
      "subCategories": [
        {
          "id": 4,
          "name": "Printers",
          "description": "Paper jams, toner, offline",
          "parentId": 1,
          "subCategories": []
        }
      ]
    }
  ]
  ```

#### `POST /api/v1/categories`
- **Access**: `ROLE_ADMIN`, `ROLE_TECHNICIAN`
- **Request Body**:
  ```json
  {
    "name": "Software",
    "description": "Application licenses and OS",
    "parentId": null
  }
  ```
- **Response `201 CREATED`**: `CategoryResponse`

#### `PUT /api/v1/categories/{id}`
- **Access**: `ROLE_ADMIN`, `ROLE_TECHNICIAN`
- **Request Body**: Same as `POST /api/v1/categories`
- **Response `200 OK`**: Updated `CategoryResponse`

#### `DELETE /api/v1/categories/{id}`
- **Access**: `ROLE_ADMIN`, `ROLE_TECHNICIAN`
- **Response `204 NO CONTENT`**

---

### 5.5 Departments (`/api/v1/departments`)

#### `GET /api/v1/departments`
- **Access**: Authenticated
- **Response `200 OK`**:
  ```json
  [
    { "id": 1, "name": "IT", "description": "Information Technology" },
    { "id": 2, "name": "HR", "description": "Human Resources" },
    { "id": 3, "name": "Finance", "description": "Finance & Accounting" }
  ]
  ```

#### `POST /api/v1/departments`
- **Access**: `ROLE_ADMIN`
- **Request Body**: `{ "name": "Marketing", "description": "Marketing Team" }`
- **Response `201 CREATED`**: `DepartmentResponse`

#### `PUT /api/v1/departments/{id}`
- **Access**: `ROLE_ADMIN`
- **Request Body**: `{ "name": "Marketing", "description": "Updated description" }`
- **Response `200 OK`**: Updated `DepartmentResponse`

---

### 5.6 Image Management (`/api/v1/images`)

#### `POST /api/v1/images/upload`
- **Access**: Authenticated
- **Header**: `Content-Type: multipart/form-data`
- **Body**: Form field `file` with binary image (Max 5MB).
- **Response `200 OK`**:
  ```json
  {
    "url": "https://abkxnzzffuojvumrhlrw.supabase.co/storage/v1/object/public/Image/93021f42-4dc9-4a9c-9c7f-94ad689b7b91.png"
  }
  ```

---

### 5.7 Real-Time Ticket Messaging

#### `GET /api/v1/tickets/{ticketId}/messages`
- **Access**: Authenticated
- **Response `200 OK`**: `List<ChatMessage>`
  ```json
  [
    {
      "id": 1,
      "ticketId": 1,
      "senderId": 3,
      "sender": "Tech One",
      "content": "Checking printer connectivity now.",
      "timestamp": "2026-10-22T11:00:00"
    }
  ]
  ```

#### `POST /api/v1/tickets/{ticketId}/messages`
- **Access**: Authenticated
- **Request Body**:
  ```json
  {
    "ticketId": 1,
    "senderId": 3,
    "sender": "Tech One",
    "content": "Checking printer connectivity now."
  }
  ```
- **Response `201 CREATED`**: Saved `ChatMessage` (also broadcast to `/topic/ticket/{ticketId}`).

#### WebSocket STOMP
- **Endpoint**: `/ws-chat`
- **Send**: `/app/chat` with `{ ticketId, senderId, sender, content }`
- **Subscribe**: `/topic/ticket/{ticketId}`

---

### 5.8 Ticket Status Logs & Audit History

#### `GET /api/v1/tickets/{ticketId}/status-logs`
- **Access**: Authenticated
- **Response `200 OK`**: `List<TicketStatusLogResponse>` (or `Page` if `page`/`size` passed).

#### `GET /api/v1/history/ticket/{ticketId}`
- **Access**: Authenticated
- **Response `200 OK`**: `List<TicketHistoryResponse>` (`id`, `action`, `comment`, `performAt`, `ticketId`).

---

### 5.9 Device Notification Tokens (`/api/v1/notifications`)

#### `POST /api/v1/notifications/device-token`
- **Access**: Authenticated
- **Request Body**: `{ "token": "<fcmToken>", "deviceType": "ANDROID" }`
- **Response `200 OK`**

#### `DELETE /api/v1/notifications/device-token?token=<fcmToken>`
- **Access**: Authenticated
- **Response `204 NO CONTENT`**
