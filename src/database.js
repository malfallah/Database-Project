// Node-side database access used by the tests and the CLI.
//
// With DATABASE_URL set, it talks to a real PostgreSQL server (Docker or the
// CI service container); tests work in a throwaway database there that is
// dropped on close. Without it, it runs PostgreSQL in-process through PGlite,
// so the tests need no server at all. Both paths apply the same migration
// files.

import { randomBytes } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { migrationVersion, parseScenario, splitMigration } from './sql-files.js';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const MIGRATIONS_DIR = path.join(ROOT, 'db', 'migrations');
export const SEED_FILE = path.join(ROOT, 'db', 'seed.sql');
export const QUERIES_DIR = path.join(ROOT, 'queries');

/**
 * @typedef {{ rows: Record<string, unknown>[], fields: { name: string }[], affectedRows?: number }} Result
 * @typedef {{
 *   kind: 'postgres' | 'pglite',
 *   pglite?: import('@electric-sql/pglite').PGlite,
 *   query: (text: string, params?: unknown[]) => Promise<Result>,
 *   exec: (text: string) => Promise<void>,
 *   close: () => Promise<void>,
 * }} Database
 */

/**
 * Open a database. By default it is a new, empty one: an in-process PGlite
 * instance, or a throwaway database on the DATABASE_URL server that is
 * dropped on close. With `throwaway: false`, connect to DATABASE_URL itself.
 * @param {{ url?: string, throwaway?: boolean }} [options]
 * @returns {Promise<Database>}
 */
export async function openDatabase({ url = process.env.DATABASE_URL, throwaway = true } = {}) {
  if (!url) return openPGlite();
  return throwaway ? openThrowawayPostgres(url) : openPostgres(url);
}

async function openPGlite() {
  const { PGlite } = await import('@electric-sql/pglite');
  const db = await PGlite.create();
  return {
    kind: 'pglite',
    pglite: db,
    query: (text, params) => db.query(text, params),
    exec: async (text) => {
      await db.exec(text);
    },
    close: () => db.close(),
  };
}

async function openPostgres(url) {
  const { default: pg } = await import('pg');
  const client = new pg.Client({ connectionString: url });
  await client.connect();
  return {
    kind: 'postgres',
    query: async (text, params) => {
      const result = await client.query(text, params);
      return { rows: result.rows, fields: result.fields, affectedRows: result.rowCount ?? undefined };
    },
    exec: async (text) => {
      await client.query(text);
    },
    close: () => client.end(),
  };
}

async function openThrowawayPostgres(url) {
  const admin = await openPostgres(url);
  // The name is generated here, never taken from input, so interpolating it
  // is safe; CREATE DATABASE cannot take a bind parameter.
  const name = `safe_hands_test_${randomBytes(6).toString('hex')}`;
  await admin.exec(`create database ${name}`);

  const target = new URL(url);
  target.pathname = `/${name}`;
  const db = await openPostgres(target.toString());
  return {
    ...db,
    close: async () => {
      await db.close();
      await admin.exec(`drop database if exists ${name} with (force)`);
      await admin.close();
    },
  };
}

/** Migration files in version order. */
export async function migrationFiles() {
  const names = (await readdir(MIGRATIONS_DIR)).filter((f) => f.endsWith('.sql')).sort();
  return Promise.all(
    names.map(async (file) => {
      const source = await readFile(path.join(MIGRATIONS_DIR, file), 'utf8');
      return { file, version: migrationVersion(file), ...splitMigration(source) };
    }),
  );
}

/**
 * Apply pending migrations, one transaction each, recording them in the same
 * schema_migrations table dbmate uses so either tool can take over.
 * @param {Database} db
 */
export async function migrate(db) {
  await db.exec('create table if not exists schema_migrations (version varchar(128) primary key)');
  const applied = new Set((await db.query('select version from schema_migrations')).rows.map((r) => r.version));
  for (const migration of await migrationFiles()) {
    if (applied.has(migration.version)) continue;
    await inTransaction(db, async () => {
      await db.exec(migration.up);
      await db.query('insert into schema_migrations (version) values ($1)', [migration.version]);
    });
  }
}

/**
 * Roll back the most recent migration.
 * @param {Database} db
 */
export async function rollback(db) {
  const { rows } = await db.query('select max(version) as version from schema_migrations');
  const version = rows[0]?.version;
  if (!version) return;
  const migration = (await migrationFiles()).find((m) => m.version === version);
  if (!migration) throw new Error(`no migration file for applied version ${version}`);
  await inTransaction(db, async () => {
    await db.exec(migration.down);
    await db.query('delete from schema_migrations where version = $1', [version]);
  });
}

/** @param {Database} db */
export async function seed(db) {
  await db.exec(await readFile(SEED_FILE, 'utf8'));
}

/** An empty database with the schema applied and the seed data loaded. */
export async function openSeededDatabase(options) {
  const db = await openDatabase(options);
  try {
    await migrate(db);
    await seed(db);
    return db;
  } catch (error) {
    await db.close();
    throw error;
  }
}

/** All scenarios from queries/, ordered by number. */
export async function loadScenarios() {
  const names = (await readdir(QUERIES_DIR)).filter((f) => f.endsWith('.sql')).sort();
  const scenarios = await Promise.all(
    names.map(async (file) => parseScenario(file, await readFile(path.join(QUERIES_DIR, file), 'utf8'))),
  );
  return scenarios.sort((a, b) => a.id - b.id);
}

/**
 * Run fn inside a transaction; commit if it resolves, roll back if it throws.
 * @template T
 * @param {Database} db
 * @param {() => Promise<T>} fn
 * @returns {Promise<T>}
 */
export async function inTransaction(db, fn) {
  await db.exec('begin');
  try {
    const result = await fn();
    await db.exec('commit');
    return result;
  } catch (error) {
    await db.exec('rollback');
    throw error;
  }
}

/**
 * Run fn inside a transaction that is always rolled back, so tests can
 * mutate seeded data without affecting each other.
 * @template T
 * @param {Database} db
 * @param {() => Promise<T>} fn
 * @returns {Promise<T>}
 */
export async function withRollback(db, fn) {
  await db.exec('begin');
  try {
    return await fn();
  } finally {
    await db.exec('rollback');
  }
}
