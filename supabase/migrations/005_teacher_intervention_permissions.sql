-- EduCare v5: teachers may create and update interventions for students assigned to them.
-- Teachers cannot delete intervention records; Admin and Advisor retain full management.
drop policy if exists interventions_write on public.interventions;
drop policy if exists interventions_admin_advisor_write on public.interventions;
drop policy if exists interventions_teacher_insert on public.interventions;
drop policy if exists interventions_teacher_update on public.interventions;

create policy interventions_admin_advisor_write
on public.interventions for all to authenticated
using (
  public.is_approved()
  and public.current_user_role() in ('admin','advisor')
  and public.can_access_student(student_id)
)
with check (
  public.is_approved()
  and public.current_user_role() in ('admin','advisor')
  and public.can_access_student(student_id)
);

create policy interventions_teacher_insert
on public.interventions for insert to authenticated
with check (
  public.is_approved()
  and public.current_user_role() = 'teacher'
  and public.can_access_student(student_id)
);

create policy interventions_teacher_update
on public.interventions for update to authenticated
using (
  public.is_approved()
  and public.current_user_role() = 'teacher'
  and public.can_access_student(student_id)
)
with check (
  public.is_approved()
  and public.current_user_role() = 'teacher'
  and public.can_access_student(student_id)
);
