-- Scenario 2: Explosion in the Health department
-- Kind: write
--
-- An explosion closes the Health department. Nobody was hurt and nobody is
-- let go: everyone in Health moves to HR with a 5% raise.
--
-- Changed from the report: the original was two UPDATE statements glued
-- together with AND (a syntax error), referenced EMPLOYEE.Dno, which its DDL
-- never created, and hard-coded HR as department 1. Run separately, the two
-- updates were also not atomic. This is one statement, so it is.

update employee as e
set
    salary = round(e.salary * 1.05, 2),
    dept_no = (
        select hr.dept_no from department as hr
        where hr.name = 'HR'
    )
from department as d
where
    e.dept_no = d.dept_no
    and d.name = 'Health'
returning
    e.employee_id,
    e.first_name,
    e.last_name,
    old.dept_no as old_dept_no,
    new.dept_no as new_dept_no,
    old.salary as old_salary,
    new.salary as new_salary;
