-- Scenario 4: Robbery in the Finance department
-- Kind: read
--
-- The Finance department was robbed at night. Only Finance staff had a key,
-- the department's manager has an alibi, and the camera shows the thief is
-- male. List the suspects.
--
-- Changed from the report: the original was four copies of the same query
-- (one per role) joined with UNION, three of which referenced columns that do
-- not exist (D.Number, D.Name, E.Employee_IDs). "Not the manager" now means
-- the employee who manages Finance, rather than "role is not Manager".

select
    e.employee_id,
    e.first_name,
    e.last_name,
    e.role
from employee as e
inner join department as d on e.dept_no = d.dept_no
where
    d.name = 'Finance'
    and e.gender = 'Male'
    and e.employee_id <> d.manager_id
order by e.employee_id;
