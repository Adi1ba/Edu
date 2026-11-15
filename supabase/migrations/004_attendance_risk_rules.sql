-- EduCare v4: automatic attendance-based risk assessment support.
-- Risk bands: Low >= 90%, Medium >= 75% and < 90%, High < 75%.
-- Excused attendance days are excluded from the denominator.
-- Academic marks are intentionally outside the current EduCare application scope.
alter table public.students
  add column if not exists assigned_teacher_id uuid references public.profiles(id) on delete set null;
create index if not exists students_assigned_teacher_idx on public.students(assigned_teacher_id);

create or replace function public.can_access_student(target_student uuid)
returns boolean language sql stable security definer set search_path=public
as $$
 select exists(select 1 from public.students s where s.id=target_student and (
  s.profile_id=auth.uid()
  or public.current_user_role() in ('admin','advisor')
  or (public.current_user_role()='teacher' and s.assigned_teacher_id=auth.uid())
 ))
$$;

drop policy if exists students_read on public.students;
create policy students_read on public.students for select to authenticated
using(public.is_approved() and (
 profile_id=auth.uid() or public.current_user_role() in ('admin','advisor')
 or (public.current_user_role()='teacher' and assigned_teacher_id=auth.uid())
));

drop policy if exists attendance_read on public.attendance;
create policy attendance_read on public.attendance for select to authenticated
using(public.is_approved() and public.can_access_student(student_id));
drop policy if exists attendance_staff_write on public.attendance;
create policy attendance_staff_write on public.attendance for all to authenticated
using(public.is_approved() and public.current_user_role() in ('admin','teacher') and public.can_access_student(student_id))
with check(public.is_approved() and public.current_user_role() in ('admin','teacher') and public.can_access_student(student_id));

drop policy if exists risk_read on public.risk_assessments;
create policy risk_read on public.risk_assessments for select to authenticated
using(public.is_approved() and public.current_user_role() in ('admin','advisor','teacher') and public.can_access_student(student_id));
drop policy if exists risk_write on public.risk_assessments;
create policy risk_write on public.risk_assessments for all to authenticated
using(public.is_approved() and public.current_user_role() in ('admin','advisor') and public.can_access_student(student_id))
with check(public.is_approved() and public.current_user_role() in ('admin','advisor') and public.can_access_student(student_id));

drop policy if exists interventions_read on public.interventions;
create policy interventions_read on public.interventions for select to authenticated
using(public.is_approved() and public.current_user_role() in ('admin','advisor','teacher') and public.can_access_student(student_id));
drop policy if exists interventions_write on public.interventions;
create policy interventions_write on public.interventions for all to authenticated
using(public.is_approved() and public.current_user_role() in ('admin','advisor') and public.can_access_student(student_id))
with check(public.is_approved() and public.current_user_role() in ('admin','advisor') and public.can_access_student(student_id));
