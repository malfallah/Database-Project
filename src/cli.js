#!/usr/bin/env node
// Run a scenario from queries/ and print the result.
//
//   npm run scenario -- list        list the scenarios
//   npm run scenario -- 4           run scenario 4
//   npm run scenario -- 2 --commit  run a write scenario and keep its changes
//
// Without DATABASE_URL it runs against a fresh, seeded in-process database
// (PGlite). With DATABASE_URL it runs against that database; write scenarios
// are rolled back unless --commit is given.

import { inTransaction, loadScenarios, openDatabase, openSeededDatabase, withRollback } from './database.js';

const args = process.argv.slice(2);
const commit = args.includes('--commit');
const target = args.find((a) => !a.startsWith('--'));

const scenarios = await loadScenarios();

if (!target || target === 'list') {
  for (const s of scenarios) console.log(`${String(s.id).padStart(2)}  ${`[${s.kind}]`.padEnd(7)}  ${s.title}`);
  if (!target) console.log('\nUsage: npm run scenario -- <number> [--commit]');
  process.exit(0);
}

const scenario = scenarios.find((s) => s.id === Number(target));
if (!scenario) {
  console.error(`No scenario ${target}. Run "npm run scenario -- list".`);
  process.exit(1);
}

const external = Boolean(process.env.DATABASE_URL);
const db = external ? await openDatabase({ throwaway: false }) : await openSeededDatabase();
try {
  console.log(`Scenario ${scenario.id}: ${scenario.title}\n\n${scenario.story}\n`);
  const run = () => db.query(scenario.sql);
  const keep = scenario.kind === 'write' && commit && external;
  const { rows } = await (keep ? inTransaction(db, run) : withRollback(db, run));
  console.table(rows);
  console.log(`${rows.length} row(s).`);
  if (scenario.kind === 'write') {
    console.log(
      keep ? 'Changes committed.' : 'Changes rolled back (pass --commit with DATABASE_URL set to keep them).',
    );
  }
} finally {
  await db.close();
}
