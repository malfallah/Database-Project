-- Scenario 8: New fatal disease
-- Kind: read
--
-- A new disease is spreading. Email every customer under 50 whose health
-- coverage is below the company average and suggest a better plan.
--
-- Changed from the report: logic unchanged (it was correct). It read the
-- coverage from HEALTH.Percentage, one of two copies of that value in the
-- original (the other was COVERS1); there is now only one. Emails are
-- aggregated so each customer is one row.

select
    c.customer_id,
    concat_ws(' ', c.first_name, c.last_name) as customer,
    m.age_years,
    h.coverage_pct,
    (
        select string_agg(ce.email, ', ' order by ce.email)
        from customer_email as ce
        where ce.customer_id = c.customer_id
    ) as emails
from customer as c
inner join health_report as h on c.customer_id = h.customer_id
inner join medical_record as m on c.customer_id = m.customer_id
where
    h.coverage_pct < (select avg(hr.coverage_pct) from health_report as hr)
    and m.age_years < 50
order by h.coverage_pct, c.customer_id;
