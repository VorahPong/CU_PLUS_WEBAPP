

# 📝 Forms Flow (CU Plus Web App)

This document explains how the dynamic form system works across the frontend (Flutter) and backend (Node.js + Prisma).

---

## 🧠 Overview

The Forms system allows:

- Admins → create and manage forms
- Students → fill, submit, and review forms

Forms are **fully dynamic**, meaning fields are created by admins and rendered by the frontend at runtime.

---

## 🔄 Full Flow

### 1. Admin Creates Form

Admin builds a form with:

- Title
- Description / Instructions
- Optional Year targeting
- Dynamic fields

Field types:

- text (short input)
- textarea (long input)
- checkbox (multiple options)
- date
- year
- signature

---

### 2. Form Stored in Database

Tables involved:

```text
FormTemplate
FormField
```

Each field includes:

- label
- type
- required
- sortOrder
- configJson (for options like checkbox)

---

### 3. Student Views Forms

Frontend calls:

```http
GET /student/forms
```

Student sees:
- available forms
- forms filtered by year (UI may gray out unavailable ones)

---

### 4. Student Opens Form

```http
GET /student/forms/:id
```

Response includes:

```json
{
  "form": { ... },
  "submission": { ... } | null
}
```

---

### 5. Frontend Builds UI Dynamically

Based on `form.fields`, the app renders:

| Type       | UI Component                |
|------------|---------------------------|
| text       | single-line input         |
| textarea   | multi-line input          |
| checkbox   | multiple checkboxes       |
| date       | date picker               |
| year       | numeric input (YYYY)      |
| signature  | signature pad / image     |

---

### 6. Student Fills Form

State is stored in:

- TextEditingControllers
- Maps (checkbox, date, year)
- Signature pad (image capture)

---

### 7. Signature Upload Flow

When submitting:

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

- creates FormSubmission
- stores answers in FormAnswer

---

## 🧾 Submission Storage

Tables:

```text
FormSubmission
FormAnswer
```

Each answer stores:

- valueText
- valueDate
- valueBoolean
- valueSignatureUrl

---

## 🔒 Submission Rules

- One submission per student per form
- If already submitted:
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

## 🧑‍💼 Admin Review (Future / Optional)

Admin can:

- view student submissions
- grade submissions
- add feedback

Stored in:

- score
- grade
- feedback

---

## ⚠️ Common Issues

### 1. Submission Not Showing

Possible causes:
- frontend not reading `submission`
- forms_api returning only `form`

---

### 2. Signature Not Displaying

Possible causes:
- using signature pad instead of Image.network
- URL not stored correctly

---

### 3. Checkbox Wrong Behavior

Fix:
- use Set<String> instead of bool

---

## 🎯 Summary

- Forms are dynamic (driven by backend)
- Frontend renders UI based on field types
- Submission stored in normalized tables
- Signature handled via Cloudinary
- Read-only mode prevents editing after submit

---

This system allows flexible, scalable form creation similar to Google Forms.

---