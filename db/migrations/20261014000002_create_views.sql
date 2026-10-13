-- migrate:up

-- Derived attributes from the ER diagram, computed on read so they cannot
-- drift: employee Age, and the department's employee and customer counts that
-- the original stored as Number_of_employees / Number_of_customers.

create view employee_profile as
select
    e.employee_id,
    e.first_name,
    e.middle_name,
    e.last_name,
    e.gender,
    e.birth_date,
    extract(year from age(current_date, e.birth_date))::integer as age,
    e.role,
    e.salary,
    e.dept_no,
    d.name as department,
    e.supervisor_id
from employee as e
inner join department as d on e.dept_no = d.dept_no;

create view department_summary as
select
    d.dept_no,
    d.name,
    d.manager_id,
    d.manager_start_date,
    (
        select count(*) from employee as e
        where e.dept_no = d.dept_no
    ) as employee_count,
    (
        select count(*) from deals_with as w
        where w.dept_no = d.dept_no
    ) as customer_count
from department as d;

-- migrate:down

drop view department_summary;
drop view employee_profile;
