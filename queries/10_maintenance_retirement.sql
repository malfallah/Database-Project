-- Scenario 10: New policy
-- Kind: write
--
-- A new regulation says maintenance staff retire at 60. Remove every
-- Maintenance employee aged 60 or over. Their dependents, phones, emails,
-- addresses and customer assignments go with them (ON DELETE CASCADE); anyone
-- they supervised is left without a supervisor (ON DELETE SET NULL). If one
-- of them manages a department, the transaction fails until a new manager is
-- appointed.
--
-- Changed from the report: the original nested an UPDATE inside DELETE ...
-- WHERE (not valid SQL), compared BDate with a string in an implicit format,
-- hard-coded 1962 as "60 years ago", and its DELETE did not filter by
-- department, so it would have removed every employee over 60 in the company.
-- The per-department head count is now a view (department_summary), so there
-- is no counter to update.

delete from employee as e
using department as d
where
    e.dept_no = d.dept_no
    and d.name = 'Maintenance'
    and e.birth_date <= current_date - interval '60 years'
returning
    e.employee_id,
    e.first_name,
    e.last_name,
    e.birth_date;
