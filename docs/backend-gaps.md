# Backend Gaps, Discrepancies & Mobile Workarounds

This document records all architectural gaps, missing endpoints, data format inconsistencies, and bugs discovered in the Spring Boot backend (`helpdesk`), along with suggested backend fixes and the defensive workarounds implemented in the Flutter mobile client.

---

## 1. Summary of Gaps

| ID | Issue | Severity | Mobile Workaround | Recommended Backend Fix |
|---|---|---|---|---|
| **GAP-01** | `AuthResponse` lacks user `id` and `imageUrl` | High | Mobile invokes `GET /api/v1/users/me` immediately after successful login to capture `id` and profile details. | Update `AuthResponse.java` and `AuthServiceImpl.java` to return `id`, `imageUrl`, and `phoneNumber`. |
| **GAP-02** | Refresh token NPE when user has null department | Critical | Ensure user creation populates department, and handle 500 refresh error by safely requesting re-login. | Change `tokenEntity.getUser().getDepartment().getId()` in `AuthController.java#L52` to safe navigation `?.getId()`. |
| **GAP-03** | Lack of public user self-registration endpoint | Medium | Note in UI that accounts are pre-provisioned by IT administrators; admin can provision users via `/users/add`. | Add `POST /api/v1/auth/register` with role defaulting to `ROLE_USER`. |
| **GAP-04** | Missing self-service password reset | Low | Provide customer support contact prompt on the sign-in screen. | Implement `POST /api/v1/auth/forgot-password` and `POST /api/v1/auth/reset-password`. |
| **GAP-05** | Mixed date/time formats across endpoints | Medium | Flexible custom DateTime parser in `JsonUtils` supporting both `"yyyy-MM-dd HH:mm:ss"` and ISO-8601 strings. | Standardize all backend dates to ISO-8601 UTC string (`yyyy-MM-dd'T'HH:mm:ss'Z'`). |
| **GAP-06** | Inconsistent error payload structures | Medium | Polymorphic error deserialization in `ApiError` supporting Standard `ErrorResponse`, Validation maps, and plain text. | Standardize exception handler to emit unified error model with code, message, and errors dictionary. |
| **GAP-07** | WebSocket `/ws-chat` uses `.withSockJS()` | Medium | Use STOMP WebSocket client connecting to raw endpoint or fallback gracefully to REST chat polling. | Add `.addEndpoint("/ws-chat").setAllowedOriginPatterns("*")` alongside SockJS for native mobile clients. |
| **GAP-08** | Unpaginated endpoints for Users, Categories, Messages | Medium | Mobile handles array responses defensively with client-side search/filtering. | Add `Pageable` parameters to `/users` and `/tickets/{id}/messages`. |
| **GAP-09** | Web calls admin-only `GET /api/v1/users/{id}` for user profile | Medium | Mobile correctly calls `GET /api/v1/users/me` for all authenticated users. | Allow non-admins to read own profile via `/users/{id}` or keep `/users/me` as primary. |
| **GAP-10** | Multipart upload endpoint returns raw string wrapper | Low | Model `ImageUploadResponse` parses `{ "url": "..." }`. | Keep current endpoint or add bulk upload. |
