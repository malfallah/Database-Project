-- Scenario 1: Rami is in search of an old house
-- Kind: read
--
-- Rami, a real-estate engineer who loves vintage property, asks Safe Hands
-- for every customer who owns an insured house built before 2005, with
-- their full name and phone number so he can make an offer.
--
-- Changed from the report: the original joined through CUSTOMER.HTitle (one
-- house per customer), used <= 2005 for "before 2005", filtered on the city
-- 'SOUR' although the story asks for every insured old house, and never
-- checked that the house was insured.

select
    h.title_deed,
    h.year_built,
    h.city,
    c.customer_id,
    concat_ws(' ', c.first_name, c.middle_name, c.last_name) as customer,
    (
        select string_agg(p.phone, ', ' order by p.phone)
        from customer_phone as p
        where p.customer_id = c.customer_id
    ) as phones
from house as h
inner join customer as c on h.owner_id = c.customer_id
where
    h.year_built < 2005
    and h.insurance_id is not null
order by h.year_built, h.title_deed;
