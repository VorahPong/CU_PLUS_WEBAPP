# 📅 Calendar Feature Documentation

This document describes how the **Calendar Feature** works in CU PLUS, including data flow, backend usage, and frontend behavior.

---

## 🧠 Overview

The calendar feature allows students and admins to visualize **form due dates** in a calendar view.

- Students see only forms assigned to their year
- Admins see all forms across all years

This feature improves visibility of deadlines and helps users stay organized.

---

## 🏗️ Design Decision

### ❌ No Separate Calendar Database

Instead of creating a new `CalendarEvent` table, the system uses existing **Form data**.

### ✅ Why?

- Forms already contain:
  - `dueDate`
  - `year`
- Avoids duplicate data
- Reduces backend complexity
- Easier to maintain

---

## 📦 Data Source

Calendar events are derived from:

### Student
```
GET /student/forms
```

### Admin
```
GET /admin/forms
```

Only forms with a valid `dueDate` are displayed.

---

## 🔄 Data Flow

### 1. Fetch Forms

Frontend calls:

```dart
final forms = isAdmin
    ? await api.getAdminForms()
    : await api.getStudentForms();
```

---

### 2. Filter Forms

```dart
form['dueDate'] != null
```

---

### 3. Parse Dates

```dart
DateTime.tryParse(form['dueDate'])
```

---

### 4. Map to Calendar Days

Each form is assigned to a calendar day based on its `dueDate`.

---

## 🎨 Frontend UI

### Calendar Grid

- Monthly view
- Displays days in a grid (Sun → Sat)
- Highlights:
  - Today
  - Days with tasks

### Day Cell

Each day shows:
- Date number
- Up to 2 form titles
- `+X more` if additional forms exist

---

### Tasks Panel (Right Side)

Displays all forms for the selected month:

- Title
- Due date
- Clickable card

---

## 🔀 Role-Based Behavior

### Student Mode

- Sees only available forms
- Click → opens form to fill

```
/dashboard/student/forms/:id
```

---

### Admin Mode

- Sees all forms
- Displays additional info:
  - Year
- Click → opens form editor

```
/dashboard/admin/forms/:id/edit
```

---

## 🧭 Navigation

Calendar is accessible via sidebar:

```
/dashboard/calendar
```

Sidebar highlights based on route matching.

---

## ⚠️ Important Notes

- Only forms with `dueDate` are shown
- Invalid date formats will not render
- Timezone differences may shift display by one day

---

## 🚀 Future Improvements

- 🔴 Highlight overdue forms
- 🟢 Show completed/submitted status
- 🎨 Color coding by year
- 📆 Weekly / daily view
- 🔔 Calendar reminders
- 📌 Add non-form events (future DB if needed)

---

## 💯 Summary

The calendar feature is a lightweight, efficient way to visualize deadlines by reusing existing form data.

It supports both student and admin roles while avoiding unnecessary database complexity.
