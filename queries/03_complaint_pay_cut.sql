-- Scenario 3: Punishment
-- Kind: write
--
-- Wael Emil Kfoury complains about the service he received. Every employee
-- who served him takes a 13% pay cut. The salary > 5000 check still applies,
-- so a cut that would go below the minimum fails instead of saving.
--
-- Changed from the report: logic unchanged (it was correct); rewritten with
-- an explicit join and RETURNING so the effect is visible.

update employee as e
set salary = round(e.salary * 0.87, 2)
where
    e.employee_id in (
        select s.employee_id
        from serves as s
        inner join customer as c on s.customer_id = c.customer_id
        where
            c.first_name = 'Wael'
            and c.middle_name = 'Emil'
            and c.last_name = 'Kfoury'
    )
returning
    e.employee_id,
    e.first_name,
    e.last_name,
    old.salary as old_salary,
    new.salary as new_salary;
