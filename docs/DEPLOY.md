# EduCare Deployment Guide

EduCare is a Vite + React + TypeScript frontend backed by Supabase Auth and PostgreSQL.

## 1. Deploy the frontend on Vercel

1. Push the latest `main` branch to GitHub.
2. Open https://vercel.com/new and sign in with GitHub.
3. Import the repository `Adi1ba/Edu`.
4. Keep the detected Vite settings:
   - Framework: Vite
   - Build command: `npm run build`
   - Output directory: `dist`
   - Install command: `npm install`
5. In Project → Settings → Environment Variables, add:
   - `VITE_SUPABASE_URL` = Supabase Project URL
   - `VITE_SUPABASE_PUBLISHABLE_KEY` = Supabase publishable key (or legacy anon public key)
6. Add variables to Production, Preview and Development environments as appropriate.
7. Click Deploy. Future pushes to `main` will trigger production deployments.

Do not add the Supabase service-role/secret key to Vercel frontend environment variables.

## 2. Configure Supabase

1. Open Supabase Dashboard → SQL Editor.
2. Run migrations in order, once each:
   - `supabase/migrations/001_initial_schema.sql`
   - `supabase/migrations/002_role_permissions.sql`
   - `supabase/migrations/003_educare_scope.sql`
   - `supabase/migrations/004_attendance_risk_rules.sql`
3. In Authentication → URL Configuration:
   - Set Site URL to your deployed Vercel URL.
   - Add the Vercel URL to Redirect URLs.
4. In Authentication → Providers → Email, decide whether email confirmation is required. If enabled, users must verify their email before signing in.

If migrations 001–003 were already run on this Supabase project, do not rerun them; run only the migrations that have not yet been applied.

## 3. Create the first administrator

After the first user signs up and appears in Authentication → Users / public.profiles, run this in Supabase SQL Editor, replacing the email:

```sql
update public.profiles
set role = 'admin',
    account_status = 'Approved'
where email = 'YOUR_ADMIN_EMAIL';
```

Then sign out and sign in again.

## 4. First-time setup inside EduCare

1. Admin approves staff accounts and assigns their roles (Teacher / Advisor).
2. Admin creates student profiles and links each profile to the student's login account.
3. Admin assigns each student to a teacher.
4. Teachers record daily attendance.
5. Admin or Advisor runs the attendance risk scan.
6. Admin or Advisor creates intervention plans and follow-up records.

## 5. Risk thresholds

- Low: attendance >= 90%
- Medium: attendance >= 75% and < 90%
- High: attendance < 75%

Attendance percentage = (Present + Late) / (Present + Absent + Late) × 100. Excused days are excluded. This is a screening signal, not a diagnosis or an automatic decision about a student.

## 6. Before public launch

- Test each role with separate accounts.
- Confirm that a student can only view their own attendance.
- Confirm that teachers can access only students assigned to them.
- Confirm that students cannot view risk assessments or intervention records.
- Use realistic test records first; avoid uploading sensitive student data until school authorization, privacy notices, backups and access policies are reviewed.
- Never commit `.env` or expose a service-role key.
