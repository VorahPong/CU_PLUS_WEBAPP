# ⚙️ Settings / Profile Feature Documentation

This document describes how the **Settings (Profile) Feature** works in CU PLUS, including schema design, backend routes, frontend behavior, and data flow.

---

## 🧠 Overview

The settings feature allows users to:

- View their profile information
- Update basic profile fields (name, etc.)
- Upload and replace a profile picture

The profile picture is stored in **Cloudinary**, and old images are automatically deleted when replaced.

---

## 🏗️ Data Model

### User Model (Relevant Fields)

```prisma
profileImageUrl       String?
profileImagePublicId  String?
```

### Explanation

| Field | Purpose |
|------|--------|
| `profileImageUrl` | Used by frontend to display image |
| `profileImagePublicId` | Used by backend to delete image from Cloudinary |

---

## 🔄 Backend Flow

### 1. Get Current User

```
GET /me
```

Returns:

```json
{
  "user": {
    "id": "...",
    "email": "...",
    "firstName": "...",
    "lastName": "...",
    "profileImageUrl": "..."
  }
}
```

---

### 2. Update Profile Info

```
PATCH /me
```

Body:

```json
{
  "firstName": "John",
  "lastName": "Doe",
  "name": "John Doe"
}
```

---

### 3. Upload Profile Image

```
POST /me/profile-image
```

Body:

```json
{
  "dataUrl": "data:image/png;base64,..."
}
```

### Backend Logic

1. Check existing user
2. If `profileImagePublicId` exists → delete old image from Cloudinary
3. Upload new image
4. Save:
   - `profileImageUrl`
   - `profileImagePublicId`

---

## ☁️ Cloudinary Integration

### Upload

```js
cloudinary.uploader.upload(dataUrl, {
  folder: "cuplus/profile-images",
})
```

### Delete Old Image

```js
cloudinary.uploader.destroy(publicId)
```

---

## 🎨 Frontend Flow

### Settings Page

Located at:

```
/dashboard/setting
```

### Features

- View profile information
- Edit name fields
- Upload profile picture
- Preview selected image

---

### API Layer

Uses:

```
SettingsApi
```

Functions:

- `getProfile()`
- `updateProfile()`
- `uploadProfileImage()`

---

## 🔁 Real-Time UI Update (Important)

To update the navbar after profile changes, a global notifier is used.

### Notifier

```dart
final ValueNotifier<int> profileRefreshNotifier
```

---

### Flow

1. User updates profile or image
2. Settings page triggers:

```dart
profileRefreshNotifier.value++;
```

3. `DashboardShell` listens:

```dart
profileRefreshNotifier.addListener(_handleProfileRefresh);
```

4. It refetches:

```dart
_loadCurrentUser();
```

5. Navbar updates automatically

---

## 🧭 Navigation Integration

### Navbar

Displays:

- User name
- Profile picture (if available)

Fallback:

```dart
Icon(Icons.person)
```

---

## ⚠️ Important Notes

- Base64 images increase payload size → backend limit increased to `10mb`
- Old profile images are cleaned up using `profileImagePublicId`
- First upload (before this feature) may leave orphan images

---

## 🚀 Future Improvements

- 🖼️ Image cropping before upload
- 📉 Automatic image compression
- 🔐 Change password feature
- 👤 More editable profile fields
- 🌐 Global user state (Provider / Riverpod)

---

## 💯 Summary

The settings feature provides a complete profile management system with:

- Clean backend architecture
- Proper Cloudinary integration
- Real-time UI updates
- Scalable design for future enhancements
