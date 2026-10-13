-- Scenario 5: Tragedy is happening, and we are here to help
-- Kind: write
--
-- During the economic crisis, employees who earn less than the company
-- average AND support at least one dependent get a 20% raise.
--
-- Changed from the report: the original EXISTS subquery declared its own
-- EMPLOYEE alias instead of referring to the row being updated, so it was
-- true for everyone as soon as any dependent existed. Every below-average
-- employee got the raise, including those with no dependents (visible in the
-- report's own screenshot on p. 108).

update employee as e
set salary = round(e.salary * 1.20, 2)
where
    exists (
        select 1
        from dependent as d
        where d.employee_id = e.employee_id
    )
    and e.salary < (select avg(a.salary) from employee as a)
returning
    e.employee_id,
    e.first_name,
    e.last_name,
    old.salary as old_salary,
    new.salary as new_salary;
