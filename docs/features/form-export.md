

# 📄 Form Export (PDF) Feature

This document explains how the **Form Export system** works in CU PLUS, including both **blank form export** and **filled submission export**.

---

## 🧠 Overview

The Form Export feature allows users to download forms as **printable PDF documents**.

Supported exports:

- 📋 **Blank Form PDF** → for printing empty forms
- 📝 **Filled Submission PDF** → includes student answers, signature, and grading info

---

## 🔄 Export Types

### 1. Blank Form Export

Exports the form structure without any answers.

#### Endpoint

```http
GET /forms/:id/export-pdf
```

#### Use Cases
- Admin printing forms
- Students printing blank forms for manual submission
- Offline usage

---

### 2. Submission Export

Exports a completed submission with all answers.

#### Endpoint

```http
GET /forms/submissions/:submissionId/export-pdf
```

#### Includes
- Student name & email
- Submission status
- Answers for all fields
- Signature (image)
- Grade, score, and feedback (if available)

---

## 🔐 Access Control

### Admin
- Can export:
  - any form
  - any submission

### Student
- Can export:
  - forms available to their year
  - only their own submissions

---

## 🧱 Backend Architecture

### 📁 File Structure

```text
src/features/forms/
  ├── formPdf.services.js      // PDF generation logic
  ├── forms.export.routes.js   // API endpoints
```

---

### 🧩 PDF Service

File: `formPdf.services.js`

Provides:

- `generateBlankFormPdfBuffer(form)`
- `generateSubmissionPdfBuffer(form, submission)`
- `sendBlankFormPdf(res, form)`
- `sendSubmissionPdf(res, form, submission)`

---

### 📦 Library Used

```bash
npm install pdfkit
```

Used for:
- text layout
- drawing lines and boxes
- embedding images (signature)

---

## 🎨 PDF Layout Design

Inspired by traditional paper forms.

### Structure

#### Header
- Form title
- Optional instructions
- divider line

#### Metadata (submission only)
- Student name
- Email
- Status
- Submitted date
- Grade / Score / Reviewer

#### Fields

| Field Type | Rendered As |
|----------|------------|
| text | single-line text |
| textarea | paragraph block |
| checkbox | checkbox list |
| date | formatted date |
| year | text |
| signature | image + signature box |

---

### ✍️ Signature Handling

- Stored as **Cloudinary URL**
- Downloaded on backend
- Embedded into PDF

---

### 📊 Grading Section

If submission is graded, PDF includes:

- Grade (A, B, Pass, etc.)
- Score (numeric)
- Feedback
- Reviewed date
- Reviewer name

---

## 🌐 Frontend Integration

### API Calls

In `FormsApi`:

```dart
Future<void> exportFormPdf(String formId);
Future<void> exportSubmissionPdf(String submissionId);
```

---

### ApiClient Support

Uses:

```dart
downloadFile(String path)
```

Handles:
- file download
- filename extraction
- browser save (Flutter Web)

---

### Web Download Handling

#### `download_file_web.dart`

- creates Blob
- triggers browser download

#### `download_file_stub.dart`

- fallback for non-web platforms

---

## 🖥 UI Integration

### Admin Pages

- Form Preview Page  
  → **Print / Export PDF**

- Submission Detail Page  
  → **Print / Export PDF**

---

### Student Pages

- Form Fill Page (read-only)  
  → can export submission

---

## ⚠️ Common Issues

### 1. Download not working

Check:
- `download_file_web.dart` exists
- correct import in `api_client.dart`

---

### 2. PDF not generating

Check:
- `pdfkit` installed
- backend route properly registered

---

### 3. Permission denied

Check:
- `req.user.year` exists in auth middleware
- correct role logic in export route

---

### 4. Signature not showing

Check:
- valid Cloudinary URL
- backend can fetch image

---

## 🚀 Future Improvements

- 📎 Attachments in PDF
- 🧾 Custom PDF templates
- 🎨 Branding (logo, header styling)
- 📅 Scheduled export
- 📥 Bulk export (multiple submissions)

---

## 💯 Summary

The Form Export system provides:

- Clean printable PDFs
- Dynamic form rendering
- Submission + grading support
- Role-based access control
- Seamless frontend download

This feature bridges digital forms with traditional paper workflows.