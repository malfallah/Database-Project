# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-10-14

The 2022 coursework rebuilt as a working, tested PostgreSQL project. Every defect found in the
original is listed in [docs/errata.md](docs/errata.md).

### Added

- PostgreSQL 18 schema as dbmate migrations (`db/migrations/`): 31 tables and 2 views covering
  every entity and relationship of the original ER diagram, with primary, foreign, unique and
  check constraints, explicit delete behaviour, and an index on every foreign key.
- Database comments on every table, view and column, including each one's original 2022 name;
  `docs/schema.md` and the README diagram are generated from them (`npm run docs`).
- Seed data (`db/seed.sql`) reconstructed from the report's INSERT listing and its screenshots
  of the live Oracle tables.
- The ten scenario queries as standalone files (`queries/`), each noting what changed.
- Test suite (`npm test`): constraint, catalog, migration, seed, scenario and documentation
  tests, plus reproductions of the original defects (`tests/original/`). Runs on PGlite with no
  setup, or on a PostgreSQL server via `DATABASE_URL`.
- `docker compose up`: PostgreSQL 18.3, migrations and seed in one command.
- `npm run scenario -- <n>`: run any scenario from the command line.
- In-browser demo (PGlite) deployed to GitHub Pages: run the scenarios, browse tables, use a SQL
  console, view the ER diagram.
- GitHub Actions: lint (Biome, SQLFluff, generated-docs check), tests on a PostgreSQL service
  container and on PGlite, a dbmate up/rollback check, a `docker compose` smoke test, and Pages
  deployment.
- Documentation: README, errata, design decisions, contributing guide, citation file, notice.

### Changed

- Target database moved from Oracle to PostgreSQL 18.
- Tables and columns renamed to consistent snake_case (`Title_dead` → `title_deed`,
  `CCOMPANIES_PHONE_NUMBER` → `contracted_company_phone`, ...).
- One-to-many relationships stored once, as foreign keys, instead of twice.
- Derived values (age, department head counts, amount due) computed by views and a generated
  column instead of stored by hand.
- Money stored as `numeric(12, 2)` instead of `FLOAT`.
- Email addresses in the data moved to `example.com`.
- The report moved to `docs/original/safe-hands-report-2022.pdf` (was `DataBase Project.pdf`),
  with its SQL transcribed to `docs/original/oracle/`.

### Fixed

- Syntax errors that stopped the original script from running (on PostgreSQL, 17 of 38
  tables could be created).
- Column-order mistakes in the data (insurance, expenses, payments, hospital stays).
- Orphaned, truncated and misattributed rows.
- Scenario queries that did not parse (2, 4, 10) or returned wrong results (1, 5, 6, 7).

### Removed

- The duplicate relationship tables `HAS1`-`HAS3` and `COVERS1`-`COVERS3`, and the stored
  department counters.

## [0.1.0] - 2023-02-06

### Added

- The original coursework report (December 2022) and the MIT license.

[Unreleased]: https://github.com/malfallah/Database-Project/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/malfallah/Database-Project/compare/9f67179...v1.0.0
[0.1.0]: https://github.com/malfallah/Database-Project/commit/9f67179
