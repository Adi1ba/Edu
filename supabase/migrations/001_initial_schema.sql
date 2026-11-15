-- Edu school management system: initial schema
create extension if not exists pgcrypto;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 email text unique not null,
 full_name text not null default '',
 role text not null default 'student' check(role in ('admin','teacher','advisor','student')),
 account_status text not null default 'Pending' check(account_status in ('Pending','Approved','Rejected')),
 created_at timestamptz not null default now()
);
create table if not exists public.school_classes (
 id uuid primary key default gen_random_uuid(),
 class_level text not null, section text not null, academic_year integer not null,
 created_at timestamptz not null default now(),
 unique(class_level,section,academic_year)
);
create table if not exists public.students (
 id uuid primary key default gen_random_uuid(),
 profile_id uuid unique references public.profiles(id) on delete set null,
 full_name text not null, roll_number text not null,
 class_id uuid references public.school_classes(id) on delete set null,
 class_level text not null, section text not null, academic_year integer not null,
 guardian_name text, guardian_phone text,
 status text not null default 'Active' check(status in ('Active','Inactive','Transferred')),
 created_at timestamptz not null default now(),
 unique(roll_number,class_level,section,academic_year)
);
create table if not exists public.teacher_class_assignments (
 id uuid primary key default gen_random_uuid(),
 teacher_id uuid not null references public.profiles(id) on delete cascade,
 class_id uuid not null references public.school_classes(id) on delete cascade,
 unique(teacher_id,class_id)
);
create table if not exists public.subjects (
 id uuid primary key default gen_random_uuid(), name text not null, subject_code text,
 class_id uuid references public.school_classes(id) on delete cascade,
 teacher_id uuid references public.profiles(id) on delete set null,
 unique(name,class_id)
);
create table if not exists public.academic_records (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.students(id) on delete cascade,
 subject_id uuid not null references public.subjects(id) on delete cascade,
 assessment_name text not null,
 marks_obtained numeric(7,2) not null check(marks_obtained>=0),
 total_marks numeric(7,2) not null check(total_marks>0 and marks_obtained<=total_marks),
 grade text, recorded_by uuid references public.profiles(id) on delete set null,
 assessment_date date not null default current_date, created_at timestamptz not null default now()
);
create table if not exists public.attendance (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.students(id) on delete cascade,
 attendance_date date not null default current_date,
 status text not null check(status in ('Present','Absent','Late','Excused')),
 marked_by uuid references public.profiles(id) on delete set null, remarks text,
 created_at timestamptz not null default now(), unique(student_id,attendance_date)
);
create table if not exists public.risk_assessments (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.students(id) on delete cascade,
 risk_level text not null check(risk_level in ('Low','Medium','High')),
 reason text not null, reviewed_by uuid references public.profiles(id) on delete set null,
 review_date date not null default current_date, next_review_date date,
 created_at timestamptz not null default now()
);
create table if not exists public.interventions (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.students(id) on delete cascade,
 title text not null, description text, action_plan text,
 assigned_to uuid references public.profiles(id) on delete set null,
 status text not null default 'Planned' check(status in ('Planned','In Progress','Completed','Cancelled')),
 start_date date not null default current_date, due_date date, outcome text,
 created_by uuid references public.profiles(id) on delete set null, created_at timestamptz not null default now()
);

create index if not exists students_class_idx on public.students(class_level,section,academic_year);
create index if not exists records_student_idx on public.academic_records(student_id,assessment_date desc);
create index if not exists attendance_student_idx on public.attendance(student_id,attendance_date desc);
create index if not exists risk_student_idx on public.risk_assessments(student_id,review_date desc);
create index if not exists interventions_student_idx on public.interventions(student_id,status);

create or replace function public.current_user_role() returns text
language sql stable security definer set search_path=public
as $$ select role from public.profiles where id=auth.uid() $$;
create or replace function public.is_approved() returns boolean
language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles where id=auth.uid() and account_status='Approved') $$;
create or replace function public.can_access_student(target_student uuid) returns boolean
language sql stable security definer set search_path=public
as $$
 select exists(select 1 from public.students s where s.id=target_student and (
  s.profile_id=auth.uid() or public.current_user_role() in ('admin','advisor') or
  (public.current_user_role()='teacher' and exists(
   select 1 from public.teacher_class_assignments a join public.school_classes c on c.id=a.class_id
   where a.teacher_id=auth.uid() and c.class_level=s.class_level and c.section=s.section and c.academic_year=s.academic_year
  ))
 ))
$$;

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path=public
as $$
begin
 insert into public.profiles(id,email,full_name,role,account_status)
 values(new.id,new.email,coalesce(new.raw_user_meta_data->>'full_name','Student'),'student','Pending')
 on conflict(id) do nothing;
 return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.school_classes enable row level security;
alter table public.students enable row level security;
alter table public.teacher_class_assignments enable row level security;
alter table public.subjects enable row level security;
alter table public.academic_records enable row level security;
alter table public.attendance enable row level security;
alter table public.risk_assessments enable row level security;
alter table public.interventions enable row level security;

drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated
using(id=auth.uid() or (public.is_approved() and public.current_user_role() in ('admin','teacher','advisor')));
drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles for update to authenticated
using(public.current_user_role()='admin') with check(public.current_user_role()='admin');

drop policy if exists classes_read on public.school_classes;
create policy classes_read on public.school_classes for select to authenticated using(public.is_approved());
drop policy if exists classes_admin_all on public.school_classes;
create policy classes_admin_all on public.school_classes for all to authenticated
using(public.current_user_role()='admin') with check(public.current_user_role()='admin');

drop policy if exists assignments_read on public.teacher_class_assignments;
create policy assignments_read on public.teacher_class_assignments for select to authenticated
using(public.is_approved() and (teacher_id=auth.uid() or public.current_user_role() in ('admin','advisor')));
drop policy if exists assignments_admin_all on public.teacher_class_assignments;
create policy assignments_admin_all on public.teacher_class_assignments for all to authenticated
using(public.current_user_role()='admin') with check(public.current_user_role()='admin');

drop policy if exists students_read on public.students;
create policy students_read on public.students for select to authenticated using(
 public.is_approved() and (profile_id=auth.uid() or public.current_user_role() in ('admin','advisor') or
 (public.current_user_role()='teacher' and exists(select 1 from public.teacher_class_assignments a join public.school_classes c on c.id=a.class_id
 where a.teacher_id=auth.uid() and c.class_level=students.class_level and c.section=students.section and c.academic_year=students.academic_year)))
);
drop policy if exists students_admin_insert on public.students;
create policy students_admin_insert on public.students for insert to authenticated with check(public.current_user_role()='admin');
drop policy if exists students_admin_update on public.students;
create policy students_admin_update on public.students for update to authenticated using(public.current_user_role()='admin') with check(public.current_user_role()='admin');
drop policy if exists students_admin_delete on public.students;
create policy students_admin_delete on public.students for delete to authenticated using(public.current_user_role()='admin');

drop policy if exists subjects_read on public.subjects;
create policy subjects_read on public.subjects for select to authenticated using(public.is_approved());
drop policy if exists subjects_staff_write on public.subjects;
create policy subjects_staff_write on public.subjects for all to authenticated
using(public.is_approved() and (public.current_user_role()='admin' or teacher_id=auth.uid()))
with check(public.is_approved() and (public.current_user_role()='admin' or teacher_id=auth.uid()));

drop policy if exists records_read on public.academic_records;
create policy records_read on public.academic_records for select to authenticated using(public.is_approved() and public.can_access_student(student_id));
drop policy if exists records_staff_write on public.academic_records;
create policy records_staff_write on public.academic_records for all to authenticated
using(public.is_approved() and public.current_user_role() in ('admin','teacher') and public.can_access_student(student_id))
with check(public.is_approved() and public.current_user_role() in ('admin','teacher') and public.can_access_student(student_id));

drop policy if exists attendance_read on public.attendance;
create policy attendance_read on public.attendance for select to authenticated using(public.is_approved() and public.can_access_student(student_id));
drop policy if exists attendance_staff_write on public.attendance;
create policy attendance_staff_write on public.attendance for all to authenticated
using(public.is_approved() and public.current_user_role() in ('admin','teacher'))
with check(public.is_approved() and public.current_user_role() in ('admin','teacher'));

drop policy if exists risk_read on public.risk_assessments;
create policy risk_read on public.risk_assessments for select to authenticated
using(public.is_approved() and public.current_user_role() in ('admin','advisor','teacher') and public.can_access_student(student_id));
drop policy if exists risk_write on public.risk_assessments;
create policy risk_write on public.risk_assessments for all to authenticated
using(public.is_approved() and public.current_user_role() in ('admin','advisor'))
with check(public.is_approved() and public.current_user_role() in ('admin','advisor'));

drop policy if exists interventions_read on public.interventions;
create policy interventions_read on public.interventions for select to authenticated
using(public.is_approved() and public.current_user_role() in ('admin','advisor','teacher') and public.can_access_student(student_id));
drop policy if exists interventions_write on public.interventions;
create policy interventions_write on public.interventions for all to authenticated
using(public.is_approved() and public.current_user_role() in ('admin','advisor'))
with check(public.is_approved() and public.current_user_role() in ('admin','advisor'));
