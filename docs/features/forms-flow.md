# 📝 Forms Flow (CU Plus Web App)

This document explains how the dynamic form system works across the frontend (Flutter) and backend (Node.js + Prisma), including recent improvements.

---

## 🧠 Overview

The Forms system allows:

- **Admins** → create and manage forms
- **Students** → fill, submit, and review forms

Forms are **fully dynamic**, meaning fields are created by admins and rendered by the frontend at runtime.

---

## 🔄 Full Flow

### 1. Admin Creates Form

Admin builds a form with:

- Title
- Description / Instructions
- Optional Year targeting
- Dynamic fields

Supported field types:

- `text` (short input)
- `textarea` (long input)
- `checkbox` (multiple options)
- `date`
- `year`
- `signature`

---

### 2. Form Stored in Database

Tables involved:

```
FormTemplate
FormField
```

Each field includes:

- `label`
- `type`
- `required`
- `sortOrder`
- `configJson` (e.g., checkbox options)

---

### 3. Student Views Forms

```http
GET /student/forms
```

Student sees:
- available forms
- forms filtered by year

---

### 4. Student Opens Form

```http
GET /student/forms/:id
```

Response:

```json
{
  "form": { ... },
  "submission": { ... } | null
}
```

---

### 5. Frontend Builds UI Dynamically

Based on `form.fields`, the UI is rendered dynamically:

| Type       | UI Component            |
|------------|-------------------------|
| text       | TextField               |
| textarea   | Multi-line TextField    |
| checkbox   | Checkbox list           |
| date       | Date picker             |
| year       | Numeric input (YYYY)    |
| signature  | Signature pad / image   |

---

### 6. Student Fills Form

State is stored in:

- TextEditingControllers
- Maps (checkbox, date, year)
- Signature pad (image capture)

---

### 7. Signature Upload Flow

1. Capture drawing → PNG (base64)
2. Send to:

```http
POST /student/forms/signature
```

3. Backend uploads to Cloudinary
4. Returns image URL

---

### 8. Submit Form

```http
POST /student/forms/:id/submissions
```

Payload:

```json
{
  "answers": [
    {
      "formFieldId": "...",
      "valueText": "..."
    }
  ]
}
```

Backend:

- creates `FormSubmission`
- stores answers in `FormAnswer`

---

## 🧾 Submission Storage

Tables:

```
FormSubmission
FormAnswer
```

Each answer stores:

- `valueText`
- `valueDate`
- `valueBoolean`
- `valueSignatureUrl`

---

## 🔒 Submission Rules

- One submission per student per form
- After submission:
  - form becomes read-only
  - submission cannot be modified

---

## 👁 Student Review Mode

When reopening a submitted form:

Frontend:

- loads submission data
- pre-fills all fields
- disables inputs
- displays signature image

---

## ✨ UX Improvements (Recent)

### 1. Selectable Text (Web)

- Forms are wrapped with `SelectionArea`
- Users can now:
  - highlight text
  - copy instructions
  - copy form content

---

### 2. Cleaner Form Builder Defaults

Admin form builder now:

- starts with empty values
- uses placeholders instead of real data
- improves first-time UX

---

### 3. Signature Handling (Improved)

- Stored as PNG in Cloudinary
- Replaces old signatures cleanly
- Uses URL instead of raw data

---

### 4. Payload Size Handling

- Backend increased limit to `10mb`
- Supports base64 signature uploads

---

## ⚠️ Common Issues

### 1. Submission Not Showing

Possible causes:
- frontend not reading `submission`
- API not returning submission

---

### 2. Signature Not Displaying

Possible causes:
- using signature pad instead of `Image.network`
- incorrect URL storage

---

### 3. Checkbox Issues

Fix:
- use `Set<String>` instead of boolean

---

### 4. Text Not Copyable (Web)

Fix:
- wrap content in `SelectionArea`
- use `SelectableText` where needed

---

## 🎯 Summary

- Forms are dynamic and backend-driven
- UI is generated at runtime
- Submission is normalized in DB
- Signature handled via Cloudinary
- Read-only mode enforced after submission
- Web UX improved with selectable text

---

This system provides a scalable, flexible form builder similar to Google Forms.
# 📝 Forms Flow (CU Plus Web App)

This document explains how the dynamic form system works across the frontend (Flutter) and backend (Node.js + Prisma), including recent improvements such as **grading** and **return-to-draft** workflows.

---

## 🧠 Overview

The Forms system allows:

- **Admins** → create, manage, review, grade, and return submissions
- **Students** → fill, submit, and review forms

Forms are **fully dynamic**, meaning fields are created by admins and rendered by the frontend at runtime.

---

## 🔄 Full Flow

### 1. Admin Creates Form

Admin builds a form with:

- Title
- Description / Instructions
- Optional Year targeting
- Dynamic fields

Supported field types:

- `text`
- `textarea`
- `checkbox`
- `date`
- `year`
- `signature`

---

### 2. Form Stored in Database

Tables involved:

```
FormTemplate
FormField
```

---

### 3. Student Views Forms

```http
GET /student/forms
```

---

### 4. Student Opens Form

```http
GET /student/forms/:id
```

---

### 5. Dynamic UI Rendering

The frontend builds UI based on `form.fields`.

---

### 6. Student Fills Form

State stored in:

- TextEditingControllers
- Maps
- Signature image

---

### 7. Submit Form

```http
POST /student/forms/:id/submissions
```

Creates:

- `FormSubmission`
- `FormAnswer`

---

## 🧾 Submission Lifecycle

### Status Flow

A submission moves through these states:

```
draft → submitted → under_review → graded
             ↘
           returned (optional)
             ↘
            draft (editable again)
```

---

## 🧠 Grading System

### Fields Used

Stored in `FormSubmission`:

- `grade` (e.g., A, B+, Pass)
- `score` (numeric)
- `feedback` (text)
- `reviewedAt`
- `reviewedById`
- `status = graded`

---

### Grade Submission

```http
PATCH /admin/forms/submissions/:submissionId/grade
```

Behavior:

- sets grade, score, feedback
- automatically sets:

```
status = "graded"
```

---

### Admin UI Behavior

- Shows **Grade / Edit Grade button**
- Displays:
  - Grade
  - Score
  - Feedback

---

## 🔁 Return to Draft Feature

### Purpose

Allows admin to fix student mistakes when they submit incomplete forms.

---

### Endpoint

```http
PATCH /admin/forms/submissions/:submissionId/return-to-draft
```

---

### Behavior

- sets:

```
status = "draft"
```

- student can:
  - edit form again
  - resubmit later

---

### Admin UI

- "Return" button shown if submission is not draft
- optional feedback can be stored

---

## 👁 Student Review Mode

When reopening:

- if `status = draft`
  - form is editable

- if `status = submitted / graded`
  - form is read-only

---

## ✨ UX Improvements

### 1. Selectable Text

- Wrapped with `SelectionArea`
- Users can copy form content

---

### 2. Cleaner Form Builder

- Empty defaults
- Placeholder-based UX

---

### 3. Signature Handling

- Stored in Cloudinary
- Uses URL instead of raw data

---

### 4. Submission Management UI

Admin now has:

- View submissions
- Grade submissions
- Return submissions
- See graded status instantly

---

## ⚠️ Common Issues

### Submission not updating

Fix:
- ensure `_loadSubmission()` is called after actions

---

### Grade not showing

Fix:
- ensure API returns `grade`, `score`, `status`

---

### Student cannot edit after return

Fix:
- ensure status is actually `draft`

---

## 🎯 Summary

The form system now supports:

- Dynamic form rendering
- Submission storage
- Signature uploads
- Admin grading system
- Return-to-draft workflow
- Status-based UI behavior

This creates a full workflow similar to real LMS systems.