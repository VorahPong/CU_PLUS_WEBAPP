📁 Course Content Flow

This document describes how Course Content (Folders + Forms) works in the CU PLUS system for both Admin and Student roles.

⸻

🧠 Overview

Course Content is structured as a tree system:
	•	Folders can contain:
	•	Subfolders
	•	Forms
	•	Forms belong to only one location:
	•	Inside a folder (folderId)
	•	Or at root (folderId = null)

Everything is ordered using:
	•	sortOrder

⸻

🏗️ Data Model

📁 CourseFolder
{
  id: string
  title: string
  parentId: string | null
  sortOrder: number
}

📄 FormTemplate
{
  id: string
  title: string
  folderId: string | null
  sortOrder: number
}

🔄 Backend Flow

1. Get Course Content Tree

GET /course-content/tree

Returns:
{
  "folders": [...],
  "rootForms": [...]
}

Each folder contains:
{
  "id": "...",
  "title": "...",
  "children": [...],
  "forms": [...]
}

Student-specific addition:
	•	isSubmitted (boolean)
	•	submission (object)

⸻

👨‍💼 Admin Flow

Create Content
	•	Create Folder: POST /course-content/admin/folders

    •	Create Subfolder: POST /course-content/admin/folders/:id/subfolders

    •	Create Form: POST /admin/forms


⸻

Move Content
	•	Move Form: PATCH /course-content/admin/forms/:formId/move
    •	Move Folder: PATCH /course-content/admin/folders/:id/move


⸻

Reorder (Drag & Drop)

PATCH /course-content/admin/reorder
{
  "parentFolderId": null,
  "items": [
    { "type": "folder", "id": "f1", "sortOrder": 0 },
    { "type": "form", "id": "fm1", "sortOrder": 1 }
  ]
}

⸻

Delete
	•	Delete Folder: DELETE /course-content/admin/folders/:id
	•	Delete Form: DELETE /admin/forms/:id

⸻

🎓 Student Flow

View Content

Student uses: GET /course-content/tree
They see:
	•	Folder structure
	•	Forms
	•	Submission status (✔)

⸻

Submission Status

Each form includes:
{
  "isSubmitted": true | false
}

UI behavior:
	•	✅ Green check → submitted
	•	⚪ Gray check → not submitted

⸻

Open Form

On click: /dashboard/student/forms/:formId

⸻

Submit Form 
POST /student/forms/:id/submissions
Body:
{
  "submitNow": true,
  "answers": [...]
}


⸻

Draft Support
	•	submitNow: false → saves draft
	•	submitNow: true → final submission

⸻

🎨 Frontend Behavior

Shared Page (Admin + Student)

Same component:
course_content_view.dart


⸻

Admin Mode
	•	Can edit folders
	•	Can create content
	•	Can drag & reorder
	•	Can delete
	•	Can view submissions count

⸻

Student Mode
	•	Read-only
	•	No edit controls
	•	No drag
	•	No delete
	•	Shows submission status ✔

⸻

🧩 Key Features Implemented
	•	✅ Nested folders
	•	✅ Forms inside folders
	•	✅ Root-level forms
	•	✅ Drag & drop ordering
	•	✅ Move form between folders
	•	✅ Remove form from folder → goes to root
	•	✅ Submission tracking per student
	•	✅ Draft saving
	•	✅ Signature upload support

⸻

⚠️ Important Notes

1. Forms belong to ONE folder only

No more attach/detach logic.

⸻

2. Ordering is shared

Both folders and forms use:
sortOrder


⸻

3. Submission state is per-student

Handled via:
formSubmission


⸻

4. Tree endpoint drives UI

Frontend depends entirely on:
/course-content/tree