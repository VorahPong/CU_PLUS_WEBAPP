# CU_PLUS_WEBAPP

## Table of Contents
- [Recommended Tools](#recommended-tools)
- [Install Flutter (macOS)](#install-flutter-macos)
- [Install Flutter (Windows)](#install-flutter-windows)
- [Repository Setup](#repository-setup)
- [Running the App](#running-the-app)
- [Naming Rules](#naming-rules)
- [Troubleshooting](#troubleshooting)
- [Folder Structure](#frontend-structure)
- [How to create add your own features](#frontend-structure)
- [Adding more images or other assets](#quick-tips)


## Overview
This repository hosts only the Flutter frontend. Backend setup and API docs now live in `CU_PLUS_WEBAPP_BACKEND/README.md`.

## Recommended Tools

- **Visual Studio Code** — recommended extensions: Prettier, GitHub Copilot, Indent Rainbow
- **Git & GitHub** — CLI or GUI
- **JIRA** — task tracking and sprint planning
- **ChatGPT** — debugging, explanations, and learning support

## Install Flutter (macOS)

1. Install Homebrew if missing:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Install Flutter via `brew`:
   ```bash
   brew install --cask flutter
   ```

3. Add Flutter to PATH (Apple Silicon default):
   ```bash
   echo 'export PATH="$PATH:/opt/homebrew/Caskroom/flutter/latest/flutter/bin"' >> ~/.zshrc
   source ~/.zshrc
   ```

4. Run Flutter Doctor:
   ```bash
   flutter doctor
   ```

Follow doctor’s guidance for missing Xcode/iOS/Android tooling.

## Install Flutter (Windows)

1. Download the Windows Flutter SDK (zip) from [flutter.dev](https://docs.flutter.dev/get-started/install/windows) and extract to `C:\src\flutter`.
2. Add `C:\src\flutter\bin` to your PATH:
   - Start → “Edit the system environment variables” → Environment Variables → Path → New → `C:\src\flutter\bin`
3. Enable execution policy if needed (PowerShell as Admin):
   ```powershell
   Set-ExecutionPolicy RemoteSigned
   ```
4. Run Flutter Doctor:
   ```powershell
   flutter doctor
   ```

## Repository Setup

⚠️ **IMPORTANT:**  
Clone BOTH repositories into the **same parent folder**.

Example:

```bash
mkdir CU_PROJECT
cd CU_PROJECT

git clone https://github.com/TBoggs05/CU_PLUS_WEBAPP.git
git clone https://github.com/TBoggs05/CU_PLUS_WEBAPP_BACKEND.git
```

Expected layout:

```
CU_PROJECT/
├── CU_PLUS_WEBAPP
└── CU_PLUS_WEBAPP_BACKEND
```

## Running the App

```bash
flutter run -d chrome --web-port 3000
```

⚠️ **Important (Web Port Requirement)**  
The frontend **must run on port 3000** when using Flutter Web.

The backend is configured to allow requests only from:
http://localhost:3000

If you run Flutter without specifying the port, it will use a random port and your API calls will fail due to CORS restrictions.

## Naming Rules

- Follow existing file and folder naming conventions
- Do NOT rename files or folders without team discussion
- Dart files: snake_case
- Class names: PascalCase

## Troubleshooting

- Run `flutter doctor -v` and resolve outstanding issues.
- Delete `pubspec.lock` and rerun `flutter pub get` if dependencies glitch.
- `flutter clean && flutter pub get` can resolve caching issues.
- For platform-specific build errors, open the platform project (`ios/Runner.xcworkspace` or `android/`) in the native IDE and check logs.

## Frontend Structure

```
CU_PLUS_WEBAPP/
├── lib/
│   ├── core/
│   │   ├── config/            # Global constants (API base URLs, themes, etc.)
│   │   └── network/           # ApiClient and shared HTTP helpers
│   │
│   ├── features/
│   │   ├── auth/              # Authentication feature
│   │   │   ├── api/           # Auth API wrappers (auth_api.dart)
│   │   │   └── ui/            # LoginPage, FirstPage, etc.
│   │   │
│   │   ├── dashboard/         # Dashboard shell & layout
│   │   │   ├── ui/
│   │   │   │   ├── dashboard_shell.dart
│   │   │   │   └── widgets/   # Sidebar, top bar, etc.
│   │   │
│   │   ├── admin/             # Admin-specific features
│   │   │   ├── api/
│   │   │   ├── ui/
│   │   │   │   ├── manage_students_view.dart
│   │   │   │   ├── register_student_view.dart
│   │   │   │   └── announcements_view.dart
│   │   │   └── widgets/
│   │   │       └── announcement_feed.dart   # reusable announcements UI
│   │   │
│   │   └── students/          # Student-specific features
│   │       ├── api/
│   │       └── ui/
│   │           ├── course_content_view.dart
│   │           ├── message_view.dart
│   │           ├── calendar_view.dart
│   │           └── announcements_view.dart   # student announcements feed
│   │
│   │   ├── forms/             # Forms feature
│   │   │   ├── api/
│   │   │   │   └── forms_api.dart
│   │   │   └── ui/
│   │   │       ├── student/
│   │   │       │   ├── student_forms_view.dart
│   │   │       │   └── student_form_fill_view.dart
│   │   │       └── admin/
│   │   │           ├── admin_forms_view.dart
│   │   │           ├── create_form_view.dart
│   │   │           └── edit_form_view.dart
│
│   └── main.dart              # App entry point + router setup
│
├── assets/                    # Images, icons, fonts
├── pubspec.yaml               # Dependencies and asset declarations
└── README.md
```


## 🧩 Architecture Overview

This project follows a **feature-based architecture**:

- Each feature is self-contained.
- API logic lives inside `api/`.
- UI screens live inside `ui/`.
- Shared utilities live inside `core/`.

This structure ensures:
- Scalability
- Maintainability
- Clean separation of concerns
- Easier onboarding for contributors

---

## 🔐 Authentication & Session Management

Authentication is handled via **JWT + Provider + persistent session restore**.

### Key Concepts
- `AuthController` holds the current user + session state
- `ApiClient` stores the JWT token and attaches it to every request
- Session is **persisted locally** and restored on app start

### Login Flow
1. User logs in via `/auth/login`
2. Backend returns `{ user, token }`
3. Frontend stores:
   - `user` → in `AuthController`
   - `token` → in `ApiClient`
   - both are also saved locally (e.g. `SharedPreferences`)
4. User is redirected to `/dashboard`

### Session Restore (IMPORTANT)
- On app startup, `AuthController.loadSession()` runs automatically
- It restores:
  - user
  - token
- Prevents logout on refresh (especially for web)

### Logout
- Clears local storage
- Clears token from `ApiClient`
- Redirects user to `/login`

---

## 🧠 Global State (Provider)

We use `MultiProvider` in `main.dart`:

```dart
MultiProvider(
  providers: [
    Provider<ApiClient>(
      create: (_) => ApiClient(),
    ),

    ProxyProvider<ApiClient, AuthApi>(
      update: (_, client, __) => AuthApi(client),
    ),

    ChangeNotifierProxyProvider<AuthApi, AuthController>(
      create: (context) => AuthController(context.read<AuthApi>()),
      update: (_, authApi, authController) =>
          authController ?? AuthController(authApi),
    ),
  ],
)
```

### Why this matters
- `ApiClient` is shared globally → keeps token consistent
- `AuthController` notifies UI when login/logout changes
- Ensures a **single shared ApiClient instance** (keeps token in sync)
- Allows AuthController to call backend APIs cleanly

---

## 🌐 API Configuration

All API URLs are centralized in:

```
lib/core/config/api_config.dart
```

```dart
class ApiConfig {
  static const String baseUrl = "http://localhost:4000";
}
```

### Important Rule
- NEVER hardcode full URLs in API files
- Always use **paths only**:

```dart
postJson("/auth/login", body);
```

The `ApiClient` automatically prepends the base URL.

---

## 🔌 ApiClient Usage

### 🔐 Token Handling
- Token is set after login via `apiClient.setToken(token)`
- Automatically included in headers:

```
Authorization: Bearer <token>
```

Located at:

```
lib/core/network/api_client.dart
```

### Responsibilities
- Attach authentication token
- Handle headers
- Handle JSON parsing
- Provide helper methods:
  - `postJson`
  - `getJson`
  - `deleteJson`

### Example

```dart
final client = context.read<ApiClient>();
await client.postJson("/admin/students", {...});
```

---

## 🔒 Route Protection (GoRouter)

Routing is protected using `redirect` logic + `AuthController`.

### Behavior
- Not logged in → redirected to `/login`
- Logged in → cannot go back to `/login`
- Non-admin → blocked from `/dashboard/admin/*`

### Extra Protection
- `refreshListenable: auth` ensures UI reacts instantly to login/logout
- Prevents flickering using `auth.isLoading`

---

## 🛡 Role-Based Access Control

### Backend
Protected routes use:

```js
requireAuth, requireAdmin
```

### Frontend
- UI hides admin-only features for students
- Pages double-check access using `AuthController`

### Example

```dart
final auth = context.auth;

if (!auth.isAdmin) {
  return Center(child: Text("Access denied"));
}
```

---

## 📢 Announcements Feature

The app uses a shared announcements UI with role-based behavior.

### Admin
- Route: `/dashboard/admin/announcements`
- Can:
  - View all announcements
  - Create announcements
  - Edit announcements
  - Delete announcements

### Student
- Route: `/dashboard/student/announcements`
- Can:
  - View announcements filtered by:
    - `everyone = true`
    - OR their academic year

### Shared UI
- `announcement_feed.dart` is reused by both admin and student views
- Admin passes `onEdit` and `onDelete`
- Student does NOT pass these → actions are hidden automatically

### Sidebar Behavior
- Only ONE "Announcements" button exists
- Routing is determined by role:

```dart
if (isAdmin) {
  context.go('/dashboard/admin/announcements');
} else {
  context.go('/dashboard/student/announcements');
}
```

## 📝 Forms Feature

The application includes a dynamic form system for student submissions.

### Admin
- Create forms with custom fields:
  - Text
  - Text Area
  - Checkbox (multiple options)
  - Date
  - Year
  - Signature
- Edit and manage forms

### Student
- View available forms
- Fill and submit forms
- Cannot resubmit after submission
- Can review submitted forms in read-only mode

### Signature Support
- Students can draw signatures
- Signatures are uploaded to Cloudinary
- Stored as image URLs and displayed on review

## 🖊 Signature Upload Flow

1. Student draws signature using signature pad
2. App converts drawing to image (base64)
3. Sends to backend `/student/forms/signature`
4. Backend uploads to Cloudinary
5. URL is returned and stored in form submission
6. Signature is displayed via `Image.network()`

## 🔌 Forms API Usage

Located in:
`lib/features/forms/api/forms_api.dart`

### Methods
- `getStudentForms()`
- `getStudentFormById(id)`
- `submitForm(id, answers)`
- `uploadSignature(dataUrl)`

Always accessed via:
```dart
final api = FormsApi(context.read<ApiClient>());
```

---

## 🌐 Routing (GoRouter)

The app uses `go_router` for:

- Nested routing
- Web URL support
- Deep linking
- Dashboard shell wrapping

### Example Routes
- /login
- /dashboard
- /dashboard/admin/students
- /dashboard/admin/students/register

### Form Routes

- /dashboard/student/forms
- /dashboard/student/forms/:id
- /dashboard/admin/forms
- /dashboard/admin/forms/create
- /dashboard/admin/forms/:id/edit

### Quick Tips
- Register new features by importing them in `main.dart` or the relevant coordinator widget.
- Update `assets/` and `pubspec.yaml` when you add images or fonts.
- Keep each feature self-contained: `data` → API, `models` → payloads, `ui` → screens.

### Adding New Features (e.g., Dashboard)

Create a new folder under `lib/features/` for each feature. For a dashboard, use `lib/features/dashboard/` with its own `api/`, and `ui/` subdirectories. Keep authentication-specific screens in `features/auth/` and place dashboard pages in `features/dashboard/ui/`. This keeps APIs, models, and widgets scoped to their feature and makes future maintenance much easier.


---

## 📌 Form Behavior Rules

- Forms become read-only after submission
- Students cannot edit submitted forms
- Fields are dynamically rendered based on backend config
- Signature fields display uploaded images in review mode

---

## ⚠️ Common Pitfalls

### 1. Getting logged out on refresh
- Make sure `loadSession()` is called in `AuthController` constructor

### 2. API not authenticated
- Ensure `ApiClient` has token set after login
- Always use `context.read<ApiClient>()` (never create new instance)

### 3. Backend not reachable
- Check `ApiConfig.baseUrl`
- Ensure backend is running on correct port

### 4. Port keeps changing (Flutter Web)
- This is normal (`flutter run -d chrome` uses random ports)
- Backend should always stay on fixed port (e.g. 4000)

### 5. Sidebar button not working (Provider error)
- Do NOT use `context.watch()` inside click handlers
- Use `context.read()` or `authRead` instead
- Example fix:
  ```dart
  final isAdmin = context.authRead.isAdmin;
  ```
---