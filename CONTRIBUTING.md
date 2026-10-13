# Contributing

Thanks for taking a look. Issues and pull requests are welcome: bug reports, clearer docs,
better queries, or new scenarios that fit the Safe Hands domain.

## Set up

You need Node.js 22 or newer. Docker and Python are optional.

```sh
npm ci            # install pinned dependencies
npm test          # run the whole suite on an in-process PostgreSQL (PGlite)
```

To run the tests against a real PostgreSQL server as well (CI does both):

```sh
docker compose up -d db
DATABASE_URL=postgres://safehands:safehands-local@localhost:5432/safe_hands npm test
```

The tests create and drop their own throwaway database on that server; they never touch the
data in `safe_hands` itself.

## Making changes

**Schema.** Never edit a migration that has been released. Add a new file in `db/migrations/`
named `YYYYMMDDHHMMSS_what_it_does.sql` with both sections:

```sql
-- migrate:up
alter table customer add column birth_date date;
comment on column customer.birth_date is 'Date of birth. New.';

-- migrate:down
alter table customer drop column birth_date;
```

Every new table and column needs a `comment` (a test checks this). Then regenerate the docs:

```sh
npm run docs
```

**Scenarios.** Add `queries/NN_short_name.sql` with the header the existing files use
(`-- Scenario N: Title`, `-- Kind: read|write`, a story paragraph, and a
`Changed from the report:` paragraph or a note that the scenario is new), and add a test for
its result in `tests/scenarios.test.js`. It will show up in the demo automatically.

**Seed data.** Keep it fictional. Use `example.com` for email addresses.

## Before opening a pull request

```sh
npm test
npm run lint          # Biome + SQLFluff (pip install -r requirements-dev.txt for SQLFluff)
npm run docs:check
```

CI runs the same checks, plus the tests on PostgreSQL 18.3 and a `docker compose up` smoke
test.

## Style

- SQL: lowercase keywords and identifiers, snake_case, explicit `join`s, explicit column lists
  in `insert`. SQLFluff enforces the layout (`.sqlfluff`).
- JavaScript: ES modules, no build step, formatted by Biome (`npm run format`).
- Commit messages: imperative mood, one logical change per commit.
