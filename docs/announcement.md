

# 📣 Announcement Feature (CU Plus Web App)

This document explains how the **Announcement system** works across backend and frontend, including support for **drafts**, **audience targeting**, and **notifications**.

---

## 🧠 Overview

The announcement feature allows:

- **Admins** → create, edit, publish, and save announcements as drafts
- **Students** → view only published announcements relevant to them
- **System** → send notifications when announcements are published

---

## 🏗️ Data Model

### Announcement Model

```prisma
model Announcement {
  id          String             @id @default(uuid())
  message     String
  status      AnnouncementStatus @default(published)
  everyone    Boolean            @default(false)
  firstYear   Boolean            @default(false)
  secondYear  Boolean            @default(false)
  thirdYear   Boolean            @default(false)
  fourthYear  Boolean            @default(false)

  authorId    String
  author      User               @relation("AnnouncementAuthor", fields: [authorId], references: [id])

  createdAt   DateTime           @default(now())
  updatedAt   DateTime           @updatedAt
}
```

### Status Enum

```prisma
enum AnnouncementStatus {
  draft
  published
}
```

---

## 🔄 Backend Flow

### 1. Create Announcement

```http
POST /admin/announcements
```

Body:

```json
{
  "message": "Important update",
  "everyone": true,
  "saveAsDraft": false
}
```

### Logic

- If `saveAsDraft = true`
  - status → `draft`
  - message and audience are optional
  - NO notifications sent

- If `saveAsDraft = false`
  - status → `published`
  - message and audience required
  - notifications are triggered

---

### 2. Update Announcement

```http
PUT /admin/announcements/:id
```

Supports:
- editing content
- converting draft → published
- converting published → draft (optional behavior)

---

### 3. Get Admin Announcements

```http
GET /admin/announcements
```

Returns:
- ALL announcements
  - draft
  - published

---

### 4. Get Student Feed

```http
GET /student/announcements/my-feed
```

Returns ONLY:

```js
status: "published"
```

Plus audience filter:

```js
OR: [
  { everyone: true },
  { firstYear: true },
  ...
]
```

---

## 🔔 Notification Integration

When announcement is **published**:

- backend triggers:

```js
notifyStudentsForAnnouncement(announcement)
```

- notifications are created for matching students
- students see notification bell update

Drafts:
- ❌ do NOT trigger notifications

---

## 🎨 Frontend Flow

### Admin Side

#### Create Page

Location:

```
/dashboard/admin/announcements/create
```

Actions:

- Fill message
- Select audience
- Choose:
  - **Save as Draft**
  - **Publish**

---

#### API Usage

```dart
createAnnouncement(
  message: "...",
  everyone: true,
  saveAsDraft: true,
)
```

---

### Announcement List (Admin)

Each item shows:

- message
- author
- date
- audience
- **status badge**

#### Status UI

- Draft → gray badge
- Published → green badge

Drafts also show:

```
Not visible to students until published
```

---

### Student Side

Students see:

- only published announcements
- filtered by year

---

## 🔁 Draft Workflow

### Typical Flow

1. Admin clicks **Save as Draft**
2. Announcement saved with:

```json
{
  "status": "draft"
}
```

3. Appears in admin list
4. NOT visible to students
5. Later:
   - admin edits → clicks **Publish**
6. Status becomes:

```json
{
  "status": "published"
}
```

7. Notifications sent

---

## ⚠️ Important Rules

- Students MUST never see drafts
- Notifications ONLY for published announcements
- Drafts allow incomplete data
- Published announcements require:
  - message
  - at least one audience

---

## 🧪 Common Issues

### 1. Draft showing to students

Fix:

```js
where: {
  status: "published"
}
```

---

### 2. Notifications sent for drafts

Fix:

```js
if (!isDraft) {
  notifyStudentsForAnnouncement(...)
}
```

---

### 3. Status not showing in UI

Fix:
- ensure `status` is included in API response
- pass `status` into announcement card

---

## 🚀 Future Improvements

- 📝 Rich text editor for announcements
- 📎 Attachments (PDF, images)
- 🗂️ Announcement categories
- 🔍 Search/filter announcements
- 📅 Schedule publish (post later)

---

## 💯 Summary

The announcement system now supports:

- Draft + publish workflow
- Audience targeting
- Notification integration
- Clean admin UI indicators
- Safe student filtering

This design ensures flexibility for admins while keeping students’ experience clean and accurate.