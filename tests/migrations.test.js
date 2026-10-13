import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { migrate, migrationFiles, openDatabase, rollback, seed } from '../src/database.js';
import { scalar } from './helpers.js';

const TABLE_COUNT = 31;

const countTables = (db) =>
  db.query(`
    select count(*) from information_schema.tables
    where table_schema = 'public' and table_type = 'BASE TABLE' and table_name <> 'schema_migrations'
  `);

let db;
before(async () => {
  db = await openDatabase();
});
after(() => db?.close());

test('migrations apply in order and are recorded like dbmate does', async () => {
  await migrate(db);
  const versions = (await db.query('select version from schema_migrations order by version')).rows.map(
    (r) => r.version,
  );
  assert.deepEqual(
    versions,
    (await migrationFiles()).map((m) => m.version),
  );
  assert.equal(scalar(await countTables(db)), TABLE_COUNT);
});

test('migrate is idempotent', async () => {
  await migrate(db);
  assert.equal(scalar(await countTables(db)), TABLE_COUNT);
});

test('every migration rolls back cleanly and re-applies', async () => {
  const total = (await migrationFiles()).length;
  for (let i = 0; i < total; i++) await rollback(db);
  assert.equal(scalar(await countTables(db)), 0);
  assert.equal(scalar(await db.query('select count(*) from schema_migrations')), 0);

  await migrate(db);
  await seed(db);
  assert.equal(scalar(await db.query('select count(*) from employee')), 31);
});
