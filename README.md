# EduCare — Student Academic Risk & Early Intervention Management System

EduCare is a lightweight school portal for student profiles, attendance monitoring, rule-based risk assessment and early intervention tracking.

## Current modules
- **Student Profiles:** student identity, guardian contact, linked student login and assigned teacher.
- **Attendance:** daily Present, Absent, Late and Excused records.
- **Risk Assessment:** Low / Medium / High attendance risk screening, manual review and next review dates.
- **Interventions:** support plans, action steps, staff assignment, follow-up dates, status and outcomes.
- **Role-based access:** Admin, Teacher, Advisor and Student.

Academic classes as a separate management module, subjects and marks/results are intentionally not included in the current scope. Grade/section are retained as student profile identifiers.

## Technology
- React + TypeScript + Vite
- Supabase Authentication + PostgreSQL + Row Level Security
- Lucide icons

## Local development

```bash
npm install
cp .env.example .env
npm run dev
```

Set the following in `.env`:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY` (or legacy anon public key)

Never use a Supabase service-role/secret key in browser code.

## Production build

```bash
npm run build
npm run preview
```

## Deployment
See [docs/DEPLOY.md](docs/DEPLOY.md) for Vercel and Supabase deployment instructions.

## Database migrations\n\nApply the SQL files in `supabase/migrations/` in filename order. Migration `005_teacher_intervention_permissions.sql` allows assigned teachers to create and update intervention records while only Admin and Advisor can delete them.\n\n## Risk screening rules
- Low: attendance >= 90%
- Medium: attendance >= 75% and < 90%
- High: attendance < 75%

Excused attendance is excluded from the denominator. Risk screening is intended to support staff review, not replace professional judgement.
