-- Scenario 7: Mother's Day
-- Kind: read
--
-- Send a gift to every mother: female employees with a son or daughter on
-- record, and (as the report assumes, since customers have no dependents
-- table) every female customer.
--
-- Changed from the report: the original EXISTS subquery was not correlated
-- with the outer employee, so every female employee qualified as soon as
-- anyone in the company had a child on record.

select
    'Employee' as kind,
    e.employee_id as person_id,
    concat_ws(' ', e.first_name, e.last_name) as name,
    (
        select string_agg(p.phone, ', ' order by p.phone)
        from employee_phone as p
        where p.employee_id = e.employee_id
    ) as phones
from employee as e
where
    e.gender = 'Female'
    and exists (
        select 1
        from dependent as d
        where
            d.employee_id = e.employee_id
            and d.relationship in ('Son', 'Daughter')
    )
union all
select
    'Customer' as kind,
    c.customer_id as person_id,
    concat_ws(' ', c.first_name, c.last_name) as name,
    (
        select string_agg(p.phone, ', ' order by p.phone)
        from customer_phone as p
        where p.customer_id = c.customer_id
    ) as phones
from customer as c
where c.gender = 'Female'
order by kind desc, person_id asc;
