# Design decisions

Why the project is built the way it is. Each section states the decision, the reasoning, and
what it costs. For the defects that prompted many of these, see [errata.md](errata.md).

## Scope: same project, rebuilt properly

The 2022 coursework designed a database for "Safe Hands", a fictional Lebanese insurance
company: 12 entity types, 18 relationships, 10 business scenarios. All of that is kept: every
entity, relationship and scenario from the ER diagram is still here, with the same data. What
changed is how it is built (migrations, constraints, tests), and what was wrong.

Deliberately **not** added: an application server, an ORM, authentication, or new business
features. The original was a database design, so this is a database project.

## PostgreSQL instead of Oracle

The report targets Oracle (APEX). The port uses PostgreSQL 18 because:

- it is free and open source, and runs anywhere from a laptop to CI service containers;
- it can run **inside a browser** through [PGlite](https://pglite.dev) (PostgreSQL compiled to
  WebAssembly), which makes a free, server-less live demo possible;
- the same migration files then run unchanged in three places: Docker, CI and the browser.

Cost: Oracle-specific syntax had to be translated (`Reg#` identifiers, `FLOAT`, the spaced
`DATE'...'` literals), and the project no longer demonstrates Oracle specifically.

## One PostgreSQL version everywhere

PGlite 0.5.8 embeds PostgreSQL 18.3, so Docker and CI use `postgres:18.3-alpine`. The test
suite runs on both PGlite and a real server in CI. This already caught one real difference:
PGlite sorts text with the `C` collation while the server uses a locale collation (`'HR'`
sorts before `'Health'` in one and after it in the other). The scenarios therefore never rely on
text ordering for their results.

## Migrations with dbmate

Schema changes are plain SQL files in `db/migrations/` with `-- migrate:up` / `-- migrate:down`
sections, applied by [dbmate](https://github.com/amacneil/dbmate).

- Plain SQL keeps the schema readable and reviewable; no ORM DSL to learn.
- dbmate is a single binary with a Docker image and an npm package, so it works in Compose, in
  CI and locally without installing a language runtime.
- The test harness and the demo build apply the same files with a 20-line runner
  (`src/database.js`) that writes the same `schema_migrations` table, so either tool can take
  over a database.
- Every `down` section is tested: `tests/migrations.test.js` rolls everything back to an empty
  database and re-applies it, and CI does the same with the real dbmate binary.

## Each relationship stored once

The original mapped every 1:N relationship twice: as foreign-key columns *and* as separate
tables (`HAS1-3`, `COVERS1-3`). With two copies they disagreed. Now each 1:N relationship is a
single foreign key on the N side, which is the standard mapping and the one the report's own
step 4 describes:

| Relationship | Original | Now |
|---|---|---|
| customer HAS vehicle / house / payment | `CUSTOMER.VSN`, `CUSTOMER.HTitle`, `PAYMENT.CID` + `HAS1`, `HAS2`, `HAS3` | `vehicle.owner_id`, `house.owner_id`, `payment.customer_id` |
| insurance COVERS vehicle / house / health | `IID`, `Percentage` columns + `COVERS1`, `COVERS2`, `COVERS3` | `insurance_id`, `coverage_pct` on `vehicle`, `house`, `health_report` |

The report also called `HAS` and `COVERS` "N-ary relationships". They are three separate binary
relationships that share a name in the diagram; no fact involves all four entities at once.

## Derived values are computed, not stored

| Derived attribute | Original | Now |
|---|---|---|
| employee Age | (not stored) | `employee_profile.age` (view) |
| department Number_of_employees / customers | stored columns, updated by hand | `department_summary` (view) |
| payment Left (= Bill - Paid) | (not stored) | `payment.amount_due`, a stored generated column |

A view or generated column cannot drift. The cost is a `count(*)` per department on read, which
is negligible at any realistic size for this domain (and indexed).

## Constraints carry the business rules

Rules live in the schema, not in application code, so every client gets them:

- `CHECK` for value rules (`salary > 5000`, `paid <= bill`, `discharged_on >= admitted_on`,
  `coverage_pct between 30 and 100`, enumerations such as `role` and `payment_type`);
- `UNIQUE` for the 1:1 relationships (`MANAGES`, `CHECKS`, `PROVIDES`) and natural keys
  (department name, vehicle plate);
- `NOT NULL` where the ER diagram has total participation (every employee works for a
  department, every department has a manager, every vehicle and house has an owner).

Short enumerations are `CHECK ... IN (...)` rather than lookup tables. That keeps the schema
close to the original and the values visible in `\d`; a lookup table would be the better choice
if users needed to add values at run time.

## The department-manager cycle uses a deferred constraint

`employee.dept_no` references `department`, and `department.manager_id` references `employee`,
and both are `NOT NULL`. Neither row can be inserted first. The manager foreign key is
`DEFERRABLE INITIALLY DEFERRED`, so a department and its manager can be created in one
transaction and the check happens at commit. The seed runs as a single transaction for this
reason. Tested in `schema.test.js` (both the allowed case and the rejected one).

## Delete behaviour is explicit

| On deleting... | Rows that... | Action | Why |
|---|---|---|---|
| an employee | are their dependents, phones, emails, addresses, service assignments | `cascade` | owned by the employee (weak entity / multivalued attribute) |
| an employee | they supervise | `set null` | the subordinate still exists |
| an employee | is a department they manage | `restrict` (at commit) | a department must have a manager; appoint one first |
| a customer | own vehicles, houses, payments, health reports | `restrict` | business records must not vanish silently |
| an insurance policy | still covers assets or payments | `restrict` | same |
| a contracted company | (rename) | `on update cascade` | its name is the key |

## Keys

Natural keys from the original are kept (employee and customer numbers, title deeds, vehicle
serial numbers, company names): they are stable identifiers in this domain and keep the data
recognisable. The exception is addresses, which had no usable key (the original's key allowed
one address per person); they get a surrogate `address_id` plus a uniqueness constraint over
the address itself, using `NULLS NOT DISTINCT` so two identical addresses with no street still
count as duplicates.

## Types

- Money: `numeric(12, 2)`. Never `float`, which cannot store most decimal amounts exactly.
- Measurements: `numeric` with explicit scale (`weight_kg numeric(5, 1)`).
- Short codes keep their original fixed widths (`char(8)` phone numbers, validated by pattern).

## Indexes

Every foreign key has an index on its leading columns (enforced by a test). That serves the
scenario joins and keeps `ON DELETE` checks from scanning child tables. With about 30 rows per
table the planner will still choose sequential scans today; these indexes are for correctness
of intent and growth, not a measured speed-up, and no other indexes were added without a query
that needs them.

## Documentation lives in the database

Every table, view and column has a `COMMENT` (migration `...003_document_schema.sql`) that also
records its original 2022 name. `docs/schema.md` and the diagram in the README are generated
from the catalog by `npm run docs`, and CI fails if they are stale. The documentation therefore
cannot describe a schema that no longer exists, which is what happened to the report (errata A6).

## Seed data reconstruction

The report contains two versions of the data: the INSERT listing and screenshots of the live
Oracle tables. Rules used:

1. Where they disagree, the screenshot wins: it shows what was actually stored.
2. Column-order mistakes are undone where the evidence is unambiguous (see errata C1-C4).
3. Typos in keys are corrected only when another table proves the intended value (202260 →
   202266, `HHL` → `HHI`); otherwise the row is dropped and listed in the errata.
4. Assumptions are labelled: six unowned vehicles and houses were assigned owners to satisfy the
   ER diagram's total participation. This is the only invented data, and the seed file says so.
5. Email domains are replaced with `example.com`.

## Modelling choices kept from the original

Some choices are debatable but are the original authors' design, so they are kept and noted:

- `CHECKS` is 1:1, so a customer has at most one hospital stay on record. A real system would
  make this 1:N.
- Scenario 7 treats every female customer as a mother, because customers have no dependents
  table. The scenario says so.
- `medical_record.age_years` is the age when the record was taken; customers have no birth date
  to derive it from.
- `WORKS_FOR` had a multivalued `Time` attribute in the ER diagram that the report never mapped
  to a table; it is still not modelled.

## Live demo: static site with a prebuilt database

The demo is a static page on GitHub Pages: PGlite in the browser, no server, no database
hosting, no cost, nothing for visitors to break (each tab has its own copy, and "Reset data"
restores the seed).

`initdb` in WebAssembly takes 10-20 s, so the build (`scripts/build-site.js`) runs the
migrations and seed once with PGlite in Node and ships the resulting data directory
(about 5 MB gzipped). Once downloaded, it starts in a few seconds (2-4 s in local testing,
against 10-20 s for initdb). The scenarios shown on the page are
the files from `queries/`, parsed by the same code the tests use.

Costs: a first visit downloads about 10 MB (compressed) of WebAssembly and data; there is no
shared or persistent state; and it is not a substitute for a real server if the project ever
needed concurrent users. For a portfolio demo of a database design, those are the right
trade-offs. Alternatives considered: a free managed Postgres (Neon, Supabase) plus a small API
would show a "real" deployment but adds a server, credentials, cold starts and an API surface to
secure, for no benefit to someone reading the schema; SQLite compiled to WASM (sql.js) would
have meant maintaining a second SQL dialect.

## Testing strategy

- **Schema tests** insert bad data and assert the specific SQLSTATE (check, unique, foreign key,
  not null) for each rule, plus catalog checks (every table has a primary key, every foreign key
  is indexed, no floating-point columns, every object documented).
- **Scenario tests** assert the exact result of each of the ten scenarios on the seed data, plus
  edge cases (a 2005 house, a pay cut below the minimum, a manager reaching retirement age).
  Write scenarios run in transactions that are rolled back.
- **Reproduction tests** (`tests/original/`) run the original SQL, or its logic with only the
  identifiers renamed, and assert that it misbehaves the way the errata describes. Where the
  report has a result screenshot, they check that the reproduction matches it.
- The suite runs against PGlite (no setup) and against a real PostgreSQL server in CI; Docker
  Compose is smoke-tested end to end in CI too.
