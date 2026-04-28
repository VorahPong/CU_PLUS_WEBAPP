

# 🔔 Notification System Flow

This document describes how the **Notification System** works in CU PLUS, including backend logic, frontend behavior, and user interactions.

---

## 🧠 Overview

The notification system allows students to receive real-time updates when:

- A new **announcement** is posted for their year
- A new **form** is created and assigned to their year

Each notification is clickable and routes the student directly to the related content.

---

## 🏗️ Data Model

### Notification

```ts
{
  id: string
  userId: string
  type: string            // "announcement" | "form"
  title: string
  message: string
  targetType: string      // "announcement" | "form"
  targetId: string
  isRead: boolean
  createdAt: DateTime
}
```

---

## 🔄 Backend Flow

### 1. Notification Creation

Notifications are created automatically when:

#### 📢 Announcement Created
- Triggered in: `admin.announcements.routes.js`
- Logic:
  - Find all students matching the target year
  - Create notification for each student

#### 📄 Form Created
- Triggered in: `admin.forms.routes.js`
- Logic:
  - Find all students matching the form's year
  - Create notification for each student

---

### 2. Notification API Endpoints

#### Get Notifications
```
GET /student/notifications
```
Returns all notifications for the logged-in student.

#### Get Unread Count
```
GET /student/notifications/unread-count
```
Returns the number of unread notifications.

#### Mark Notification as Read
```
PATCH /student/notifications/:id/read
```

#### Mark All as Read
```
PATCH /student/notifications/read-all
```

#### Delete One Notification
```
DELETE /student/notifications/:id
```

#### Clear All Notifications
```
DELETE /student/notifications
```

---

## 🎨 Frontend Flow

### Notification Bell (Top Navbar)

- Displays unread count badge
- Clicking the bell opens a dropdown panel

---

### Dropdown Panel Features

- Shows list of notifications
- Displays:
  - Title
  - Message
  - Time (e.g., "5m ago")
- Actions:
  - Click notification → navigate to content
  - Dismiss (delete) individual notification
  - Clear all notifications

---

### Navigation Behavior

Each notification contains:

```json
{
  "targetType": "form" | "announcement",
  "targetId": "..."
}
```

Routing logic:

- If `form` →
```
/dashboard/student/forms/:id
```

- If `announcement` →
```
/dashboard/student/announcements
```

---

## ✅ User Interaction Flow

1. Admin creates announcement or form
2. Backend generates notifications for matching students
3. Student sees unread badge in navbar
4. Student clicks bell → dropdown opens
5. Student:
   - clicks notification → navigates + marks as read
   - dismisses notification → removes it
   - clears all → removes all notifications

---

## ⚠️ Important Notes

- Notifications are **user-specific** (stored per student)
- No direct DB relation to forms/announcements (uses `targetType` + `targetId`)
- System is designed for flexibility and scalability

---

## 🚀 Future Improvements

- 🔴 Real-time notifications (WebSocket)
- 📱 Mobile push notifications
- 📝 Draft-related notifications
- 🔔 Notification preferences (enable/disable types)
- 📊 Notification analytics (read rates, engagement)

---

## 💯 Summary

The notification system provides a simple yet scalable way to:
- Inform students of new content
- Improve engagement
- Enable quick navigation to relevant resources

It integrates tightly with Course Content and Forms while remaining loosely coupled for future expansion.