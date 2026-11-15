-- Edu v2: tighten staff writes and allow students to view their own support plans.
-- Teachers may only change attendance for students in their assigned classes.
drop policy if exists attendance_staff_write on public.attendance;
create policy attendance_staff_write on public.attendance
for all to authenticated
using (
  public.is_approved()
  and public.current_user_role() in ('admin','teacher')
  and public.can_access_student(student_id)
)
with check (
  public.is_approved()
  and public.current_user_role() in ('admin','teacher')
  and public.can_access_student(student_id)
);

-- Students can read their own support plans; only admins/advisors can create or edit them.
drop policy if exists interventions_read on public.interventions;
create policy interventions_read on public.interventions
for select to authenticated
using (
  public.is_approved()
  and (
    (public.current_user_role() = 'student' and public.can_access_student(student_id))
    or (
      public.current_user_role() in ('admin','advisor','teacher')
      and public.can_access_student(student_id)
    )
  )
);

-- Prevent a teacher from changing an assessment for a class they are not assigned to.
drop policy if exists records_staff_write on public.academic_records;
create policy records_staff_write on public.academic_records
for all to authenticated
using (
  public.is_approved()
  and public.current_user_role() in ('admin','teacher')
  and public.can_access_student(student_id)
)
with check (
  public.is_approved()
  and public.current_user_role() in ('admin','teacher')
  and public.can_access_student(student_id)
);
