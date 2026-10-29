# Hostel Complaint Tracker — HostelCare

A responsive full-stack application for hostel residents to report maintenance and facility issues and follow their resolution. Hostel staff can review all reports, update status, and leave a note for the student.

## Problem statement and objectives
Hostel complaints are often reported informally and residents may not know whether an issue is being handled. HostelCare provides one place to submit structured reports and track progress. Objectives: make complaint submission clear, give students visibility into status, and help hostel administrators triage and update reports.

## Roles and features
- **Student:** create an account, sign in, submit complaints with category and priority, view only their own reports, filter by status/category, delete reports while still Submitted, and read office notes.
- **Administrator:** view all reports and reporter details, filter reports, update status (Submitted, In Progress, Resolved, Rejected), add an optional update note, and delete reports.
- Secure password hashing, JWT-based API authentication, input validation, rate limiting, security headers, responsive layout, and persistent Supabase PostgreSQL storage.

## Technology stack
HTML5, CSS3, Vanilla JavaScript, Node.js, Express, Supabase PostgreSQL, and npm packages for database access, password hashing, JWTs, security headers, and rate limiting. No frontend framework is used.

## Folder structure
```text
hostel-complaint-tracker/
├── frontend/
│   ├── index.html
│   ├── styles.css
│   └── app.js
├── backend/
│   ├── middleware/auth.js
│   ├── routes/auth.js
│   ├── routes/complaints.js
│   ├── supabase.js
│   ├── server.js
│   ├── package.json
│   ├── .env.example
│   └── .gitignore
├── database/schema.sql
├── .gitignore
└── README.md
```

## Prerequisites and installation links
- [Node.js LTS](https://nodejs.org/) (npm is included)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/downloads)
- A free [Supabase](https://supabase.com/) account

## Setup on Windows
1. Install the software above. Open VS Code and choose **File → Open Folder**; open the extracted `hostel-complaint-tracker` folder.
2. In VS Code choose **Terminal → New Terminal**. Confirm you are in the root folder (the path ends with `hostel-complaint-tracker`). Check versions:
   ```powershell
   node --version
   npm --version
   git --version
   ```
   Each should print a version. If a command is not found, install that tool and restart VS Code.
3. Create a Supabase project at https://supabase.com/dashboard. Choose a project name and database password, then wait for provisioning to finish.
4. In Supabase open **SQL Editor → New query**. Open `database/schema.sql`, copy the entire file into the editor, and click **Run**. In **Table Editor**, verify `users` and `complaints` exist.
5. In Supabase open **Project Settings → API** (or **API Keys** depending on the dashboard version). Copy the project URL and the **service_role/secret server key**. This key is highly privileged and must only be placed in `backend/.env`, never in browser code or GitHub.
6. In VS Code's Explorer, make a copy of `backend/.env.example` named `backend/.env`. Fill it with your own values:
   ```dotenv
   PORT=3000
   NODE_ENV=development
   SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVER_ONLY_SERVICE_ROLE_KEY
   JWT_SECRET=replace_with_a_long_random_secret
   JWT_EXPIRES_IN=8h
   ```
   To generate a strong JWT secret, run `node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"` in a terminal and paste the output as `JWT_SECRET`. Do not include quote marks unless needed. `.env.example` contains placeholders for sharing; `.env` contains your private local settings and is ignored by Git.
7. In the terminal, install backend dependencies:
   ```powershell
   cd backend
   npm install
   npm run check
   ```
   `npm install` creates `node_modules/` and `package-lock.json`. The check command should finish without syntax errors.
8. Start the server from the `backend` directory:
   ```powershell
   npm start
   ```
   Expected output: `Hostel Complaint Tracker running at http://localhost:3000`. Keep this terminal open.
9. Open **http://localhost:3000** in your browser. Register a student account and submit a test complaint. Refresh the page to verify the complaint is stored in Supabase.
10. To stop the server, focus its terminal and press `Ctrl+C`. Restart it later with `npm start` from `backend/`.

### Create an administrator
First register the account normally in the app. In Supabase **SQL Editor**, run the following query with the email address used to register (replace the example email):
```sql
update public.users set role = 'admin' where email = 'admin@example.com';
```
Sign out and sign back in so the new role is included in the login token. Never add a public role-change endpoint or allow users to choose `admin` in registration. For a real deployment, protect the Supabase dashboard and use a carefully controlled admin provisioning process.

## How it works
The browser serves static HTML/CSS/JavaScript from `frontend/` and uses `fetch()` to call Express `/api/...` routes. Express validates requests, verifies signed JWTs, checks user ownership or administrator role, then accesses Supabase PostgreSQL with the server-only service-role key. The database stores users and complaints permanently. RLS is enabled as defence-in-depth; because server-side service-role access bypasses RLS, authorization checks in the backend are essential. Never expose the service-role key to the browser.

## API reference
All responses are JSON. Protected routes require `Authorization: Bearer <token>`.

| Method | Path | Purpose | Access |
|---|---|---|---|
| GET | `/api/health` | Check server is running | Public |
| POST | `/api/auth/register` | Create student account | Public; role always student |
| POST | `/api/auth/login` | Sign in and receive token | Public, rate-limited |
| GET | `/api/auth/me` | Get current account | Signed-in user |
| GET | `/api/complaints` | List reports; optional `status` and `category` filters | Student sees own; admin sees all |
| POST | `/api/complaints` | Submit report (`title`, `description`, `category`, `priority`) | Signed-in student/admin |
| PATCH | `/api/complaints/:id/status` | Update status and optional `admin_note` | Admin only |
| DELETE | `/api/complaints/:id` | Delete a report | Admin; student only their Submitted report |

Typical success responses: registration/login returns `{ "token": "...", "user": { ... } }`; complaint list returns `{ "complaints": [] }`; create/update returns `{ "complaint": { ... } }`. Common errors use `{ "error": "Readable explanation" }` with HTTP 400, 401, 403, 404, 409, 429, or 500.

## Testing checklist
- [ ] `GET http://localhost:3000/api/health` returns JSON with `status: "ok"`.
- [ ] Register with valid details; user appears in Supabase `users` without a plaintext password.
- [ ] Duplicate email registration returns 409.
- [ ] Login with correct password succeeds; incorrect password returns 401.
- [ ] Submit a complaint; it appears in the list and `complaints` table after refresh.
- [ ] Empty/short title, short description, invalid category or invalid priority are rejected.
- [ ] A student cannot see another student's reports or update status.
- [ ] A student can delete their own Submitted report but not an In Progress report.
- [ ] Promote a test account using the admin SQL above, sign in again, and verify it can view all reports and change status.
- [ ] Verify an unauthenticated request to `/api/complaints` returns 401.
- [ ] Try filters and resize the browser to mobile width.
- [ ] If the database is unavailable, the UI displays an error rather than silently pretending data was saved.

## Troubleshooting
- **`npm` or `node` not recognized:** install Node.js LTS and restart your terminal.
- **Missing environment variable:** confirm the file is named exactly `backend/.env` and values are filled in.
- **Invalid API key / fetch error:** confirm `SUPABASE_URL` and the server-only key are copied from the same Supabase project.
- **Relation/table not found:** rerun `database/schema.sql` in the correct project's SQL Editor.
- **Port already in use:** change `PORT` in `backend/.env` to `3001`, restart, and visit `http://localhost:3001`.
- **Admin still sees student view:** sign out and sign in again after changing the database role.
- **401 after a while:** tokens expire according to `JWT_EXPIRES_IN`; sign in again.
- **Complaints not loading:** check the backend terminal for an error and confirm the Supabase project is active.

## GitHub upload
Create an empty repository on [GitHub](https://github.com/new) (do not add a README there if this project already has one). From the project root terminal:
```bash
git init
git status
git add .
git status
git commit -m "Build Hostel Complaint Tracker"
git branch -M main
git remote add origin YOUR_GITHUB_REPOSITORY_URL
git push -u origin main
```
Replace the remote placeholder with your repository's HTTPS or SSH URL. Before `git add .`, confirm `backend/.env` and `node_modules/` are ignored; `.env.example` should be included. If Git says there is nothing to commit, check `git status`. If `origin` already exists, use `git remote set-url origin YOUR_GITHUB_REPOSITORY_URL`. If you accidentally publish a secret, rotate it immediately; `.gitignore` does not remove a secret from existing Git history.

## Security notes and limitations
This is a beginner-friendly academic MVP. It uses JWTs stored in `localStorage`, so an XSS vulnerability could expose a session token; do not use this unchanged for sensitive production deployments. Use HTTPS in deployment, a stricter production CORS policy, and consider server-managed secure HttpOnly cookies, monitoring, backups, and a more formal admin provisioning process. The server logs error messages for debugging but returns generic server errors to clients. There is no email notification, file upload, or automatic assignment workflow in this version.

## Manual verification status
The source includes a `npm run check` syntax-check command. Run it locally after installation. The Supabase connection and browser workflow require your own Supabase credentials and have not been remotely verified as part of this archive.
