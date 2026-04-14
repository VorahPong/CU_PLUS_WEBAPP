

# 🧩 CU PLUS – System Architecture

This document serves as the **source of truth** for how the CU PLUS system is structured. It is intended to help restore context quickly when starting new development sessions.

---

## 🧠 High-Level Overview

CU PLUS is a full-stack system composed of:

- **Frontend**: Flutter Web
- **Backend**: Node.js (Express)
- **Database**: PostgreSQL (Prisma ORM)
- **Storage**: Cloudinary (for signatures/images)

The system follows a **role-based architecture**:

- Admin → manages content (folders, forms)
- Student → consumes content and submits forms

---

## 🏗️ Core Architecture Layers

### 1. Frontend (Flutter)

Key Features:
- Dashboard (Admin / Student)
- Course Content Tree UI
- Form Renderer (dynamic forms)
- Submission handling
- Signature drawing & upload

Important Files:
- `course_content_view.dart` → main content tree UI (shared)
- `form_renderer.dart` → dynamic form rendering
- `form_field_widgets.dart` → reusable input components

---

### 2. Backend (Express)

Organized by feature modules:

```
src/features/
  forms/
    admin.forms.routes.js
    student.forms.routes.js
  courseContent/
    admin.courseContent.routes.js
```

Responsibilities:
- API routing
- Validation
- Business logic
- File uploads (Cloudinary)

---

### 3. Database (PostgreSQL + Prisma)

Main Models:

#### CourseFolder
```ts
{
  id: string
  title: string
  parentId: string | null
  sortOrder: number
}
```

#### FormTemplate
```ts
{
  id: string
  title: string
  folderId: string | null
  sortOrder: number
}
```

#### FormSubmission
```ts
{
  id: string
  formId: string
  studentId: string
  status: 'draft' | 'submitted'
}
```

---

## 🌳 Course Content System

Structure:
```
Folder
 ├── Subfolder
 │     └── Form
 └── Form
```

Rules:
- A form belongs to **only one folder** (or root)
- Folders can be nested infinitely
- Ordering is controlled by `sortOrder`

---

## 🔄 Data Flow

### Load Content
```
Frontend → GET /course-content/tree → Backend → DB
```

Returns:
- folders (nested)
- rootForms

---

### Admin Flow

- Create folder / subfolder
- Create form
- Move form/folder
- Drag & reorder
- Delete content

---

### Student Flow

- View course content
- Open form
- Save draft
- Submit form

---

## ✅ Submission System

Each form returns (for students):

```json
{
  "isSubmitted": true | false
}
```

UI:
- ✅ Green check → submitted
- ⚪ Gray check → not submitted

---

## 🧩 Key Design Decisions

### 1. Single Source Tree
All UI is driven by:
```
GET /course-content/tree
```

---

### 2. No Join Table for Forms
Forms use:
```
folderId
```
instead of attach/detach relations.

---

### 3. Shared UI for Admin & Student
Same page:
```
course_content_view.dart
```

Differences:
- Admin → edit controls
- Student → read-only

---

### 4. Draft vs Submit

Backend logic:
```js
if (submitNow) {
  validate required fields
}
```

---

## 📦 External Services

### Cloudinary
Used for:
- Signature uploads
- Image storage

---

## 🚀 Future Improvements

- Draft badge (📝)
- Due date indicators
- Search/filter content
- Persist folder expand state
- Analytics dashboard

---

## 🧠 Context Recovery (IMPORTANT)

When starting a new chat, include:

```
We are working on CU PLUS.

Docs:
- architecture.md
- courseContent-flow.md
- forms-flow.md

Task:
<your task>
```

This restores full system context instantly.

---

## 💯 Summary

CU PLUS uses:
- Tree-based content system
- Role-based UI
- Dynamic form rendering
- Clean separation of frontend + backend

This document should always reflect the **current system design**.