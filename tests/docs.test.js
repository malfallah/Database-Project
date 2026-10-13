import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, test } from 'node:test';
import { generatedFiles, readableCheck } from '../scripts/docs.js';
import { migrate, openDatabase } from '../src/database.js';

let db;
before(async () => {
  db = await openDatabase();
  await migrate(db);
});
after(() => db?.close());

test('every table, view and column is documented with a comment', async () => {
  const { rows } = await db.query(`
    with relation as (
      select c.oid, c.relname, c.relkind
      from pg_class as c join pg_namespace as n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind in ('r', 'v') and c.relname <> 'schema_migrations'
    )
    select relname as object from relation
    where obj_description(oid, 'pg_class') is null
    union all
    select r.relname || '.' || a.attname
    from relation as r join pg_attribute as a on a.attrelid = r.oid
    where r.relkind = 'r' and a.attnum > 0 and not a.attisdropped and col_description(r.oid, a.attnum) is null
    order by 1`);
  assert.deepEqual(
    rows.map((r) => r.object),
    [],
  );
});

test('docs/schema.md and the README diagram match the migrations', async () => {
  for (const [file, expected] of await generatedFiles()) {
    assert.equal(await readFile(file, 'utf8'), expected, `${file} is stale: run "npm run docs"`);
  }
});

test('CHECK definitions are rendered readably', () => {
  assert.equal(
    readableCheck(
      "CHECK (((role)::text = ANY ((ARRAY['CEO'::character varying, 'Manager'::character varying])::text[])))",
    ),
    "role IN ('CEO', 'Manager')",
  );
  assert.equal(readableCheck('CHECK ((salary > (5000)::numeric))'), 'salary > 5000');
  assert.equal(
    readableCheck('CHECK (((satisfaction >= 0) AND (satisfaction <= 10)))'),
    '(satisfaction >= 0) AND (satisfaction <= 10)',
  );
});
