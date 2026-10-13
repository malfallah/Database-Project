-- Scenario 9: Happy anniversary
-- Kind: read
--
-- Invite every employee of the Executive department and every manager
-- (including the CEO) to the company anniversary, by email.
--
-- Changed from the report: the original joined on EMPLOYEE.DNo, a column its
-- DDL never created. A single WHERE with OR replaces the UNION, and each
-- person is one row with their emails aggregated.

select
    e.employee_id,
    concat_ws(' ', e.first_name, e.last_name) as name,
    e.role,
    d.name as department,
    (
        select string_agg(em.email, ', ' order by em.email)
        from employee_email as em
        where em.employee_id = e.employee_id
    ) as emails
from employee as e
inner join department as d on e.dept_no = d.dept_no
where
    d.name = 'Executive'
    or e.role in ('Manager', 'CEO')
order by e.employee_id;
