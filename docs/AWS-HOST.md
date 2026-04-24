

# AWS Hosting Documentation (CU Plus)

## Overview
This document explains how the CU Plus application is hosted on AWS, including both the frontend and backend. It also provides guidance for future developers on deployment, environment variables, and who to contact for support.

---

## Architecture

- Frontend: Flutter Web
- Backend: Node.js (Express)
- Database: PostgreSQL (Prisma ORM)
- Hosting:
  - Frontend → AWS S3 + CloudFront
  - Backend → AWS Elastic Beanstalk

---

## Backend Hosting (Elastic Beanstalk)

### Deployment
- Backend is deployed using:
  - GitHub Actions (automated)
  - OR manual `.zip` upload via AWS Console

### Important Notes
- The deployment zip MUST contain `package.json` at the root
- Entry point is:
  ```
  src/index.js
  ```
- Start script in `package.json`:
  ```json
  "start": "node src/index.js"
  ```

### Required Environment Variables (Elastic Beanstalk)
Configure in:

> Elastic Beanstalk → Configuration → Environment Properties

Required:
- DATABASE_URL
- FRONTEND_URL
- CLOUDINARY_CLOUD_NAME
- CLOUDINARY_API_KEY
- CLOUDINARY_API_SECRET

### Health Check
- Endpoint:
  ```
  /health
  ```
- Used by AWS Load Balancer to determine app health

---

## Frontend Hosting (S3 + CloudFront)

### Deployment
- Flutter Web build:
  ```bash
  flutter build web
  ```
- Upload `/build/web` contents to S3 bucket

### CloudFront
- Used for CDN + HTTPS
- Alternate domain configured:
  ```
  cuplusapptest.com
  ```

### Important
- Always invalidate cache after deployment:
  - CloudFront → Invalidations → Create Invalidation → `/*`

---

## Authentication System

- Uses cookie-based session authentication (NOT JWT)
- Cookie name:
  ```
  session_id
  ```

### Backend Requirements
- CORS must allow credentials
- Cookie settings:
  ```js
  {
    httpOnly: true,
    secure: true,
    sameSite: "None"
  }
  ```

### Frontend Requirements
- Must send credentials with requests
- Flutter Web must use `BrowserClient`:
  ```dart
  final client = BrowserClient();
  client.withCredentials = true;
  ```

---

## Common Issues

### 1. Deployment fails (Beanstalk)
- Cause: Wrong zip structure
- Fix: Ensure `package.json` is at root of zip

### 2. 401 Unauthorized
- Cause: Cookie not sent
- Fix:
  - Check `withCredentials = true`
  - Check cookie settings (`SameSite=None`, `Secure=true`)

### 3. Backend not updating
- Cause: Wrong version or failed deploy
- Fix:
  - Check Beanstalk Events
  - Redeploy with new version label

### 4. Frontend not updating
- Cause: CloudFront cache
- Fix:
  - Invalidate cache (`/*`)

---

## Deployment Commands

### Zip backend (correct way)
```bash
zip -r backend.zip . \
  -x "node_modules/*" \
     ".git/*" \
     ".env" \
     "*.log" \
     ".DS_Store"
```

---

## Contact

If anything breaks or needs updates:

**Primary Contact:**  
Vorahpong Mean (Pong) (Repo Owner + AWS Host Owner) 
Computer Science Student, Cameron University  

GitHub: https://github.com/vorahpongmean  

---

## Notes

- Do NOT commit `.env` files
- Always verify environment variables in AWS
- Always test `/health` after deployment
- Keep deployments consistent between frontend and backend domains

---

_End of document_