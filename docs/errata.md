# Errata: defects found in the 2022 design and how they were fixed

This is the review log for the original coursework
([report](original/safe-hands-report-2022.pdf), transcribed in [original/oracle/](original/oracle/)).
Every entry says what was wrong, how we know, what changed, and which test pins it.
Tests prefixed `original/` reproduce the defect against the original SQL; the others
show the fix. Run them with `npm test`.

**How the evidence was gathered.** The report's DDL, INSERTs and queries were transcribed
verbatim (only line breaks the PDF introduced were re-joined). The DDL was run statement by
statement against PostgreSQL 18; the INSERT listing was loaded into permissive staging tables
(all text, no constraints) so its contents could be audited; and the report's own screenshots
of the live Oracle database (pp. 50-99) and query results (pp. 100-115) were used as a second
source. Where a defect is visible in those screenshots, the entry says so: that is direct
evidence the problem affected the real database, not just the printed script.

Severity: **High** breaks the script or produces wrong answers; **Medium** lets bad data in
or loses data; **Low** style, clarity or robustness.

## Summary

| Area | High | Medium | Low | Total |
|---|---:|---:|---:|---:|
| A. Running the script as printed | 6 | 0 | 1 | 7 |
| B. Schema design | 4 | 10 | 4 | 18 |
| C. Data | 5 | 7 | 2 | 14 |
| D. Scenario queries | 7 | 1 | 1 | 9 |
| E. Privacy and security | 0 | 1 | 0 | 1 |
| **Total** | **22** | **19** | **8** | **49** |

What "running it as-is" looks like on PostgreSQL 18: of 38 `CREATE TABLE` statements, **17
succeed**. On Oracle one more would (`CALLS_FOR_EMERGENCY`, whose only problem in PostgreSQL is
the `#` in a column name); this is inferred from the errors, as no Oracle server was used. 4 of
the 505 `INSERT`s are not valid SQL in any dialect, and 4 of the 10 scenario queries do not parse
or reference columns that do not exist. Tests: `original/script.test.js`, `original/queries.test.js`.

---

## A. Running the script as printed

**A1. String literals use typographic quotes. High.**
`DEFAULT ‘6000’`, `IN (‘Male’,’Female’,NULL)`, `LIKE ‘%@%.%’`, ... in 12 of 38 tables.
`‘ ’` (U+2018/U+2019) are not SQL quote characters, so every one of these statements fails
(Oracle and PostgreSQL alike). Word's autocorrect is the usual cause.
*Fix:* plain `'`. *Test:* `original/script.test.js › curly quotes are not string delimiters`.

**A2. Trailing commas before `)`. High.**
`INSURANCE`, `EXPENSE`, `CONTRACTING_COMPANY`, `EMPLOYEE_LOCATION`, `CUSTOMER_LOCATION`.
*Test:* `original/script.test.js › trailing commas before the closing parenthesis`.

**A3. A `;` inside `CREATE TABLE`. High.**
`DEPARTMENT` (`Manager_Start_Date DATE NOT NULL;`) and `HOUSE_LOCATION`
(`CHECK(HAPARTMENT_NUMBER>0);`): the statement ends early and the rest is a syntax error.
*Test:* `› a semicolon inside CREATE TABLE cuts the statement in two`.

**A4. Tables referenced before they exist. High.**
`CUSTOMER` (2nd) has foreign keys to `VEHICLE` (6th) and `HOUSE` (5th); creation order makes
the script fail even with every syntax error fixed. Failures also cascade: `HOUSE` cannot
reference the `INSURANCE` table that failed, `MEDICAL_RECORD` the `CUSTOMER` table that failed.
*Fix:* migrations create parents first; the one genuine cycle (department ↔ manager) uses a
deferred constraint. *Test:* `› tables referenced before they are created`.

**A5. `Date` as a column name (`EXPENSE.Date`). High (Oracle).**
`DATE` is a reserved word in Oracle, so the column must be quoted. The DESC screenshot (p. 52)
shows it in mixed case, which only happens when it was quoted, so the real database was not
built from this DDL. *Fix:* `expense.spent_on`.

**A6. The printed DDL is not what built the database. High.**
The screenshots show a different schema: `EMPLOYEE.DNO` exists (p. 50) but is absent from the
DDL, `PAYMENT` and `EXPENSE` have a different column order (p. 52), `HEALTH.CID` is `NUMBER` not
`CHAR(9)` (p. 53), `ECITY` is `NOT NULL` (p. 55). Anyone re-running the report gets a different
database from the one its results came from. *Fix:* the schema now lives only in versioned
migrations, and `docs/schema.md` is generated from the database (`tests/docs.test.js`).

**A7. Table numbering skips 16. Low.** Cosmetic; noted because it made cross-checking harder.

Not counted as defects: `Reg#` and `EmergencyPhoneNo#` are legal Oracle identifiers that
PostgreSQL rejects, and `DATE'2000 - 03 - 25'` (spaces inside the literal) is rejected by
PostgreSQL but was accepted by Oracle (the `PAYMENT_DATE` screenshot, p. 95, shows those rows).
Both are dialect differences, handled by the port.

## B. Schema design

**B1. Most relationships have no foreign key. High.**
Only 9 of 38 tables declare any foreign key. `SERVES`, `PAYS`, `TRANSACTS`, `DEALS_WITH`,
`IS_ACTIVE`, `CALLS_FOR_EMERGENCY`, all multivalued-attribute tables and all `HAS`/`COVERS`
tables accept any value, and the data shows it (see C7-C9). *Fix:* every relationship column is
a foreign key with an explicit `on delete` rule. *Test:* `schema.test.js › FOREIGN KEY constraints`.

**B2. One-to-many relationships stored twice, and the copies disagree. High.**
`HAS` (customer → vehicle/house/payment) is both `CUSTOMER.VSN`/`HTitle` + `PAYMENT.CID` *and*
the tables `HAS1`/`HAS2`/`HAS3`; `COVERS` (insurance → vehicle/house/health) is both
`IID`/`Percentage` columns *and* `COVERS1`/`COVERS2`/`COVERS3`. With two sources of truth they
drift: all 8 `HAS3` rows disagree with `CUSTOMER.VSN`, and `COVERS3` says vehicle 400000 is
covered by policy 26 while `VEHICLE.IID` says 665.
*Fix:* each 1:N relationship is one foreign key on the N side (`vehicle.owner_id`,
`vehicle.insurance_id`, ...); the six duplicate tables are gone.
*Test:* `original/script.test.js › relationships stored twice disagree with each other`.

**B3. A customer can own only one vehicle and one house. High.**
`CUSTOMER.VSN` and `CUSTOMER.HTitle` are single columns, contradicting the 1:N `HAS` in the ER
diagram. *Fix:* the foreign key moved to the vehicle/house (`owner_id`).

**B4. `EMPLOYEE` has no department column. High.**
`WORKS_FOR` is mapped to `DNo` in the report's step 4 but the DDL never creates it; scenarios 2,
4, 9 and 10 depend on it. *Fix:* `employee.dept_no not null` (total participation), values taken
from the EMPLOYEE screenshot (pp. 77-78).

**B5. Stored counters that drift. Medium.**
`DEPARTMENT.Number_of_employees`/`Number_of_customers` are maintained by hand. In the original
data the employee counts add up to 39 for 31 employees, and the customer counts (11, 8, 8, ...)
bear no relation to `DEALS_WITH`, which has one customer per department.
*Fix:* computed by the `department_summary` view. *Test:* `original/script.test.js › stored
department counts do not add up`, `seed.test.js › department head counts are derived`.

**B6. Floating-point money. Medium.**
`Salary`, `Bill`, `Paid`, `Price`, `Value` are `FLOAT`/`REAL`. Binary floating point cannot
represent most decimal amounts exactly, and nothing rounds to cents (the report's own result on
p. 102 shows a salary of 8473.6827). *Fix:* `numeric(12, 2)`; scenarios round explicitly.
*Test:* `schema.test.js › no floating-point columns`.

**B7. Address tables allow one address per person. Medium.**
`EMPLOYEE_LOCATION` and `CUSTOMER_LOCATION` use the owner id alone as primary key, although the
ER diagram makes Location multivalued. The data has second addresses for customers 202213 and
202299; the CUSTOMER_LOCATION screenshot (p. 91) shows only one row for each, so the second
addresses were rejected. *Fix:* surrogate `address_id` plus
`unique nulls not distinct (owner, district, city, street, apartment_no)`.
*Test:* `schema.test.js › rejects a duplicate address even when street is NULL`.

**B8. Foreign-key type mismatches. Medium.**
`HEALTH.CID CHAR(9)` → `CUSTOMER.Customer_ID INT`; `HAS1.ReceiptNo VARCHAR(10)` → `PAYMENT`
`INT`; `COVERS1.ReportNo VARCHAR(10)` → `HEALTH INT`. Oracle refuses the first (ORA-02267) and
the others compare strings to numbers. *Fix:* matching types everywhere.

**B9. Missing rules the domain needs. Medium.**
Nothing stopped a payment exceeding its bill, a hospital discharge before admission, a service
period ending before it starts, an insured asset without a coverage percentage, two vehicles
with the same plate, or two departments with the same name (which scenarios look up by name).
*Fix:* `paid <= bill`, `discharged_on >= admitted_on`, `end_date >= start_date`,
`(insurance_id is null) = (coverage_pct is null)`, `unique (plate_letter, registration_no)`,
`unique (name)`. *Test:* `schema.test.js › CHECK constraints`, `› NOT NULL, UNIQUE ...`.

**B10. One-to-one relationships not enforced. Medium.**
`MANAGES`, `CHECKS` and `PROVIDES` are 1:1 in the ER diagram, but nothing prevented one employee
managing two departments, or a customer having two health reports or medical records; and the
department manager column was nullable despite total participation. *Fix:* `unique` on
`department.manager_id`, `health_report.customer_id`, `medical_record.customer_id`;
`manager_id not null`. *Test:* `schema.test.js › rejects one employee managing two departments`, ...

**B11. `HOUSE_LOCATION` is a separate table for a single-valued attribute. Medium.**
Keyed by the title deed alone, it can hold one location per house, so it is a 1:1 split that
only adds a join (and its keys did not even match `HOUSE`, see C8). *Fix:* folded into `house`.

**B12. `MEDICAL_RECORD.Sex` duplicates `CUSTOMER.Gender`. Medium.**
Two copies that can disagree. *Fix:* dropped; use `customer.gender`. `Age` is kept as
`age_years`, documented as the age when the record was taken (customers have no birth date).

**B13. No defined delete behaviour. Medium.**
Deleting an employee with dependents, supervisees or phone numbers was either blocked or (with
no FKs) left orphans. *Fix:* `cascade` for owned rows (dependents, contact details, assignments),
`set null` for supervisees, `restrict` where deleting would lose business records (owners of
vehicles, policies in use, department managers).
*Test:* `schema.test.js › referential actions`.

**B14. No indexes on foreign-key columns. Medium.**
Oracle and PostgreSQL do not index foreign keys automatically; joins and parent deletes then
scan the child table. *Fix:* an index for every foreign key not already covered by a primary
key. *Test:* `schema.test.js › every foreign key is backed by an index` (verified to fail when
an index is dropped).

**B15. Misleading `NULL` in `IN` lists. Low.**
`CHECK (GENDER IN ('Male','Female',NULL))`: a `NULL` in the list never matches anything. It is
redundant on nullable columns and contradictory on `CUSTOMER.Gender NOT NULL`. *Fix:* removed.

**B16. Invented defaults. Low.**
`BDate DEFAULT '1950-01-01'` records a birth date nobody provided, and `DEFAULT '6000'` is a
string default for a numeric column. *Fix:* unknown birth dates are `NULL`; numeric default.

**B17. Weak email check and cryptic names. Low.**
`LIKE '%@%.%'` accepts spaces and multiple `@`; names such as `Title_dead`, `CCOMPANIES_*`,
`HAS1`, `IBoolean` are hard to read. *Fix:* a stricter pattern, descriptive snake_case names,
and the original name of every table and column recorded in its database comment
(see [schema.md](schema.md)).

**B18. The normalization chapter misses the real redundancy. Low.**
Each relation is analysed on its own and declared BCNF, which is fair for most of them in
isolation; but the redundancy that actually caused trouble is *between* tables (B2, B5, B12).
Not a code change; covered in [design-decisions.md](design-decisions.md).

## C. Data

**C1. `INSURANCE` values in the wrong column order. High.**
Values are `(id, type, coverage)`; the table is `(IID, Coverage, Type_of_Insurance)`, so
`'Other'` goes into an `INT` column and every row fails. The screenshot (p. 79) shows the
intended values. *Test:* `original/script.test.js › INSURANCE values are in (id, type, coverage) order`.

**C2. `EXPENSE` values in the wrong column order. High.**
Values start with the receipt number; the table starts with `Item`. Every row fails.
*Test:* `› EXPENSE values are in (number, item, price, ...) order`.

**C3. `PAYMENT`: receipt number and amount paid swapped. High.**
As declared, `(Paid, Type, Bill, Mechanism, ReceiptNo, CID)`. But all 12 `HAS1`
`(customer, receipt)` pairs match only if the first value is the receipt number, and so do every
`PAYMENT_CURRENCY`, `PAYMENT_DATE` and `IS_ACTIVE` row; as declared, customer 202204 has paid 54
on a bill of 38.5. The screenshot (p. 81) shows the swapped version was what Oracle stored.
*Fix:* columns named in every INSERT. *Test:* `› PAYMENT: ReceiptNo and Paid are swapped`.

**C4. `HEALTH`: admission and discharge dates swapped. High.**
The table declares `Exit_Date` before `Enter_Date` and the INSERTs fill them in the opposite
order, so all 10 patients leave hospital before arriving.
*Test:* `› HEALTH: every patient is discharged before being admitted`; now prevented by
`health_report_stay_check`.

**C5. Four INSERTs are not valid SQL. High.**
`INSERT INTO INSURANCE VALUES 11, ...` (missing parenthesis) and three `EMPLOYEE_LOCATION` rows
missing a comma (202199, 202147, 202191). The EMPLOYEE_LOCATION screenshot (p. 88) shows exactly
those three employees without an address. *Test:* `› four INSERT statements are not valid SQL`.

**C6. A duplicate key and misattributed contact details. Medium.**
`EMPLOYEE_LOCATION` has two rows for 202182 (rejected by the PK; the screenshot shows only one),
and 202182 also has a second phone and the email `Elias.charbel@...`, while 202183, Elias
Charbel Shehab, has no contact details at all. *Fix:* moved to 202183.
*Test:* `› EMPLOYEE_LOCATION repeats a primary key`, `seed.test.js › every employee and customer can be contacted`.

**C7. Rows that point at nothing. Medium.**
`CALLS_FOR_EMERGENCY` has customer 202260 (does not exist; every other row repeats the
`DEALS_WITH` pairs, which give 202266); `TRANSACTS` has company `'HHL'` (the company is `'HHI'`);
`IS_ACTIVE` has policies 75 and 26 (do not exist). *Fix:* first two corrected with the evidence
above; the two `IS_ACTIVE` rows dropped since there is no way to tell what was meant.
*Test:* `› rows that point at things that do not exist`.

**C8. Truncated keys. Medium.**
`HOUSE_LOCATION` and `COVERS2` use `'392'`, `'840'`, `'42'`, ... where houses are `'3925632'`,
`'8408742'`, `'4287653'`: none of the 10 rows matches a house. The HOUSE_LOCATION screenshot
(p. 94) has the full numbers. *Fix:* full title deeds from the screenshot.
*Test:* `› whole tables whose keys match nothing they reference`.

**C9. Tables filled with unrelated values. Medium.**
`HAS2` titles (`'1234'`, `'2980'`, ...) and `HAS3` serial numbers (`397864`, ...) match no house or
vehicle, and the `CCOMPANIES_PHONE_NUMBER` listing is a copy of `CUSTOMER_PHONE` with customer ids
in the company-name column. *Fix:* `HAS`/`COVERS` tables removed (B2); company phones taken from
the screenshot (p. 93).

**C10. A house missing from the listing. Medium.**
`CUSTOMER` 202200 owns house `'3925632'`, which is not in the HOUSE INSERTs but is in the HOUSE
screenshot (p. 80). *Fix:* restored from the screenshot.

**C11. No department for any employee. Medium.**
Follows from B4. *Fix:* `dept_no` from the screenshot; with it, scenario 4 returns exactly the
two suspects the report shows (p. 107).

**C12. Assets with no owner. Medium.**
Vehicles 400004 and 600006 and houses 3212436, 8486765, 1167466, 4478863 belong to nobody, while
the ER diagram says every vehicle and house is owned by a customer. *Fix:* assigned to customers
who had none of that kind, and flagged in `db/seed.sql` as an assumption, not recovered data.

**C13. Typos in values. Low.**
`'LUNP SUM'`, `'Derham'`, `'San Goerge'`, trailing spaces in `'Volkswagen '` and `'Rent '`,
`'gamil.com'`. *Fix:* corrected; the `payment_type` and `currency` checks now reject the
misspellings.

**C14. Listing and screenshots disagree. Low.**
E.g. Rent 200000 vs 20000, `'White Board'` vs `'White Boards'`. *Rule used:* the screenshot wins,
since it shows what was in the database.

## D. Scenario queries

The original text of each query is in [original/oracle/03_scenarios.sql](original/oracle/03_scenarios.sql);
the fixed versions are in [`queries/`](../queries/), each with a "Changed from the report" note.

**D1. Q2 is two statements joined with `AND`. High.**
`UPDATE ...; AND UPDATE ...` is a syntax error; run as two statements the raise and the transfer
would not be atomic; and HR is hard-coded as department 1. *Fix:* one `UPDATE` that does both.
*Test:* `original/queries.test.js › Q2`, `scenarios.test.js › 2.`.

**D2. Q4 references columns that do not exist. High.**
Three of four `UNION` branches use `D.Number`, `D.Name` (the columns are `DNumber`, `DName`) and
one selects `E.Employee_IDs`. The four branches differ only in `Role`, so the `UNION` was
unnecessary. "Not the manager" was approximated by role. *Fix:* one query excluding
`department.manager_id`. *Test:* `original/queries.test.js › Q4`.

**D3. Q5 raises the wrong people. High.**
`WHERE EXISTS (SELECT * FROM DEPENDENT DEP, EMPLOYEE E WHERE E.Employee_ID = DEP.EID)` declares
its own `E`, so it is not correlated with the row being updated and is true for everyone. The
report's own screenshot (p. 108) shows the result: Ola Makki (202108) and Farah Farhat (202123),
who have no dependents, got the raise. *Fix:* `where d.employee_id = e.employee_id`.
*Test:* `original/queries.test.js › Q5: the uncorrelated EXISTS raises employees who have no dependents`.

**D4. Q6's filter does nothing. High.**
`NOT EXISTS (SELECT * FROM INSURANCE, CUSTOMER WHERE Customer_ID = IID)` compares customer ids
(202200+) with policy ids (5-876) and is not correlated, so it is always true; customers who
still hold active insurance are included. `INSURANCE` is also cross-joined into the outer query
and `DISTINCT` hides the duplicates. *Fix:* correlated `not exists` over the customer's active
policies. *Test:* `original/queries.test.js › Q6`.

**D5. Q7 treats every female employee as a mother. High.**
Same uncorrelated-`EXISTS` mistake as Q5. Asmaa Ballouz, who has no dependents, is in the
report's result (p. 110). *Fix:* correlated subquery. *Test:* `original/queries.test.js › Q7`.

**D6. Q10 is not valid SQL, and its intent would delete too much. High.**
An `UPDATE` nested in `DELETE ... WHERE` does not parse. The `DELETE` itself has no department
filter, so it would remove every employee over 60, not just Maintenance staff; `BDate < '01-01-1962'`
hard-codes "60 years ago" and relies on implicit date formatting. *Fix:* `delete ... using
department` filtered by name and `current_date - interval '60 years'`; the head count is a view.
*Test:* `original/queries.test.js › Q10` (both), `scenarios.test.js › 10.` (three cases).

**D7. Q9 and Q2/Q4/Q10 depend on the missing `DNo` column. High.**
See B4. Fixed by the schema change.

**D8. Q1 does not answer the question asked. Medium.**
The story asks for insured houses built *before* 2005 from any customer; the query uses
`<= 2005`, never checks insurance, adds a city filter (`'SOUR'`) the story does not mention, and
joins through `CUSTOMER.HTitle`, so customers with more than one house are missed.
*Fix:* `< 2005`, `insurance_id is not null`, no city filter, city shown in the output.
*Test:* `original/queries.test.js › Q1`, `scenarios.test.js › 1.` (two cases).

**D9. Implicit joins and one row per phone/email. Low.**
Comma joins with conditions in `WHERE` make missing join conditions easy to miss (as in D4), and
selecting one phone per row repeats a person once per phone. *Fix:* explicit `JOIN`s; phones,
emails and addresses aggregated per person.

Q3 and Q8 were logically correct; they were only restyled.

## E. Privacy and security

**E1. Real-looking personal email addresses published. Medium.**
The seed data used `@gmail.com`/`@hotmail.com` addresses, several built from the authors' own
names. Even for coursework, publishing addresses that may belong to real people invites spam.
*Fix:* all addresses use `example.com` (reserved for documentation, RFC 2606).
*Test:* `seed.test.js › no real-looking email domains are published`.

The original project had no application code, so the usual application-level checks (SQL
injection, password storage, secrets in configuration) had nothing to apply to. For the code
added here: the test and CLI code passes values as bind parameters; the one interpolated
identifier (the throwaway test-database name) is generated, not taken from input; the demo's SQL
console runs only inside the visitor's own browser; and no credentials are committed (Docker
uses a local-only default bound to 127.0.0.1, overridable through `.env`, which is git-ignored).
