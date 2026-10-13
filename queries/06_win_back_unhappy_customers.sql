-- Scenario 6: All customers should be satisfied
-- Kind: read
--
-- Find customers with a satisfaction score below 6 who no longer hold any
-- active insurance, with their phone numbers and addresses, so an agent can
-- visit them.
--
-- Changed from the report: the original NOT EXISTS compared Customer_ID with
-- an insurance IID and was not correlated with the outer customer, so it
-- filtered nothing. It also cross-joined INSURANCE into the outer query and
-- used DISTINCT to hide the duplicates. Phones and addresses are aggregated so
-- a customer with two of each is one row, not four.

select
    c.customer_id,
    concat_ws(' ', c.first_name, c.last_name) as customer,
    c.satisfaction,
    (
        select string_agg(p.phone, ', ' order by p.phone)
        from customer_phone as p
        where p.customer_id = c.customer_id
    ) as phones,
    (
        select
            string_agg(
                concat_ws(', ', a.street, a.city, a.district)
                || coalesce(' (apt ' || a.apartment_no || ')', ''),
                ' | ' order by a.address_id
            )
        from customer_address as a
        where a.customer_id = c.customer_id
    ) as addresses
from customer as c
where
    c.satisfaction < 6
    and not exists (
        select 1
        from payment as p
        inner join payment_policy as pp on p.receipt_no = pp.receipt_no
        where
            p.customer_id = c.customer_id
            and pp.is_active
    )
order by c.satisfaction, c.customer_id;
