// Load the report's original data into a permissive "original" schema so its
// defects can be measured. Column names and order come from the original DDL
// (docs/original/oracle/01_schema.sql); every column is text and there are no
// constraints, so whatever the INSERT listing contains ends up visible here.
//
// The only rewrite applied to the INSERTs is turning DATE'2000 - 03 - 25'
// into DATE '2000-03-25': PostgreSQL rejects the spaced form but the report's
// PAYMENT_DATE screenshot shows Oracle accepted it, so it is a dialect
// difference, not a defect.

import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ORIGINAL = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../docs/original/oracle');

export const readOriginal = (file) => readFile(path.join(ORIGINAL, file), 'utf8');

/** Column lists per table, in DDL order, parsed from the original script. */
export async function originalColumns() {
  const ddl = await readOriginal('01_schema.sql');
  const tables = new Map();
  let current = null;
  for (const line of ddl.split('\n')) {
    const create = /^CREATE TABLE (\w+)/i.exec(line);
    if (create) {
      current = create[1].toLowerCase();
      tables.set(current, []);
      continue;
    }
    const column = /^([A-Za-z_#]+)\s+(INT|VARCHAR|FLOAT|DATE|CHAR|REAL)\b/i.exec(line.trim());
    if (current && column) {
      tables.get(current).push(column[1].toLowerCase().replace('#', '_no'));
    }
  }
  return tables;
}

/** Each INSERT statement of the original listing, with its table. */
export async function originalInserts() {
  const data = await readOriginal('02_data.sql');
  return data
    .split('\n')
    .filter((line) => line.startsWith('INSERT'))
    .map((statement) => ({ table: /^INSERT INTO (\w+)/i.exec(statement)[1].toLowerCase(), statement }));
}

/**
 * Create schema "original" and load every INSERT that parses.
 * @returns {Promise<{ table: string, statement: string, error: string }[]>} the statements that failed
 */
export async function loadOriginalData(db) {
  const columns = await originalColumns();
  await db.exec('create schema original');
  for (const [table, cols] of columns) {
    await db.exec(`create table original.${table} (${cols.map((c) => `${c} text`).join(', ')})`);
  }

  const failures = [];
  for (const { table, statement } of await originalInserts()) {
    const sql = statement
      .replace(/^INSERT INTO (\w+)/i, (_, t) => `insert into original.${t.toLowerCase()}`)
      .replace(/DATE\s*'(\d{4}) - (\d{2}) - (\d{2})'/g, "DATE '$1-$2-$3'");
    try {
      await db.exec(sql);
    } catch (error) {
      failures.push({ table, statement, error: error.message });
    }
  }
  return failures;
}
