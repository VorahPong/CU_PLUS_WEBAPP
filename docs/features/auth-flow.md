

# 🔐 Authentication Flow (CU Plus Web App)

This document explains how authentication works across the frontend (Flutter) and backend (Node.js + Prisma).

---

## 🧠 Overview

Authentication uses a **JWT + Session hybrid approach**:

- JWT → used for request authorization
- Session (DB) → allows server-side control (e.g., logout, revoke)

---

## 🔄 Full Flow

### 1. User Login

Frontend sends:

```http
POST /auth/login
```

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

---

### 2. Backend Processing

Backend will:

1. Find user by email
2. Compare password (hashed)
3. Generate JWT
4. Create session in database

```text
Session Table:
- id
- userId
- tokenHash
- expiresAt
```

---

### 3. Response to Frontend

```json
{
  "token": "JWT_TOKEN",
  "user": {
    "id": "...",
    "role": "student"
  }
}
```

---

### 4. Store Token (Frontend)

Token is stored in:

- localStorage (web)
- or memory state (Provider)

---

### 5. Authenticated Requests

All protected requests include:

```http
Authorization: Bearer <JWT_TOKEN>
```

Example:

```http
GET /student/forms
Authorization: Bearer eyJhbGci...
```

---

### 6. Backend Middleware (`requireAuth`)

For protected routes:

1. Extract token from header
2. Verify JWT
3. Find matching session in DB
4. Attach user to `req.user`

If any step fails → `401 Unauthorized`

---

## 👮 Role-Based Access

Roles:

- `student`
- `admin`

Admin routes use:

```js
requireAdmin
```

Which checks:

```js
req.user.role === 'admin'
```

---

## 🔓 Logout Flow (Recommended)

Frontend:

```http
POST /auth/logout
```

Backend:

- marks session as revoked OR deletes it

Effect:

- JWT still exists
- BUT session check fails → user is logged out

---

## ⛔ Session Expiration

Each session has:

```text
expiresAt
```

If expired:

- request is rejected
- user must log in again

---

## 🧩 Frontend Integration (Flutter)

### ApiClient

All requests go through:

```dart
ApiClient
```

It automatically adds:

```dart
Authorization: Bearer token
```

---

### Provider Usage

Auth state is managed via Provider:

```dart
final api = context.read<ApiClient>();
```

---

## ⚠️ Common Issues

### 1. Missing Token

Error:
```
401 Unauthorized
```

Fix:
- Ensure token is set in ApiClient

---

### 2. Expired Session

Error:
```
401 Session expired
```

Fix:
- Re-login user

---

### 3. Wrong Role

Error:
```
403 Forbidden
```

Fix:
- Check admin vs student route

---

## 🎯 Summary

- JWT handles identity
- Session handles control
- Middleware enforces both
- Frontend sends token on every request

---

This setup allows:

- secure authentication
- session revocation
- role-based access
- scalable backend control

---