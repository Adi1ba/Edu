# Setup

Install Node.js 20+, run npm install, copy .env.example to .env, add your Supabase project URL and publishable key, then run npm run dev.

Run supabase/migrations/001_initial_schema.sql in the Supabase SQL Editor before using the app. Never place a service-role key in frontend environment variables.

## First administrator
Register a normal account, then run this SQL in Supabase after replacing the email:

    update public.profiles set role='admin', account_status='Approved' where email='admin@your-school.edu';

Keep this bootstrap step private. Student self-registration creates a pending profile; an administrator must approve it and create/link the student record.

The school data model uses class, section, roll number and academic year—not department or semester.