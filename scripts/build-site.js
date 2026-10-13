#!/usr/bin/env node
// Build the static demo into _site/ for GitHub Pages (or `npm run serve:site`).
// The database the page loads is built here from db/migrations and
// db/seed.sql, and the scenarios are the files in queries/, so the demo always
// runs exactly what is in the repository.

import { cp, mkdir, readdir, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { migrate, openDatabase, seed } from '../src/database.js';
import { erDiagram, readCatalog } from './docs.js';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const OUT = path.join(ROOT, '_site');
const PGLITE = path.join(ROOT, 'node_modules', '@electric-sql', 'pglite', 'dist');

const sqlFiles = async (dir) => (await readdir(dir)).filter((f) => f.endsWith('.sql')).sort();

await rm(OUT, { recursive: true, force: true });
await mkdir(OUT, { recursive: true });

// Page, styles and the shared SQL-file parser (the page parses scenario files).
await cp(path.join(ROOT, 'web'), OUT, { recursive: true });
await cp(path.join(ROOT, 'src', 'sql-files.js'), path.join(OUT, 'js', 'sql-files.js'));

// Scenario files plus a manifest the page reads at start-up.
const queries = await sqlFiles(path.join(ROOT, 'queries'));
await cp(path.join(ROOT, 'queries'), path.join(OUT, 'sql', 'queries'), { recursive: true });
const repository = process.env.GITHUB_REPOSITORY
  ? `${process.env.GITHUB_SERVER_URL ?? 'https://github.com'}/${process.env.GITHUB_REPOSITORY}`
  : 'https://github.com/malfallah/Database-Project';
await writeFile(path.join(OUT, 'sql', 'manifest.json'), JSON.stringify({ repository, queries }, null, 2));

// PGlite's browser build: the ES modules, the file-system shims it imports
// lazily, and the WebAssembly/data files. Extensions are not needed.
const vendor = path.join(OUT, 'vendor', 'pglite');
await mkdir(vendor, { recursive: true });
for (const file of await readdir(PGLITE)) {
  if (/\.(js|wasm|data)$/.test(file)) await cp(path.join(PGLITE, file), path.join(vendor, file));
}
// PGlite is Apache-2.0 licensed; its licence travels with the redistributed files.
await cp(path.join(PGLITE, '..', 'LICENSE'), path.join(vendor, 'LICENSE'));
await cp(path.join(PGLITE, 'fs'), path.join(vendor, 'fs'), {
  recursive: true,
  filter: (src) => !/\.(map|d\.ts|d\.cts|cjs)$/.test(src),
});

// Build the database once, here, with the same PGlite version the page uses:
// apply the migrations, load the seed, and ship the resulting data directory.
// Running initdb in the browser takes 10-20 s; loading this takes about one.
// The ER diagrams come from the same catalog, as in docs/schema.md.
const db = await openDatabase({ url: '' });
try {
  await migrate(db);
  const catalog = await readCatalog(db);
  await mkdir(path.join(OUT, 'er'), { recursive: true });
  await writeFile(path.join(OUT, 'er', 'core.mmd'), erDiagram(catalog, { core: true }));
  await writeFile(path.join(OUT, 'er', 'full.mmd'), erDiagram(catalog, { attributes: true }));

  await seed(db);
  await db.exec('vacuum analyze');
  const snapshot = await db.pglite.dumpDataDir('gzip');
  await mkdir(path.join(OUT, 'data'), { recursive: true });
  await writeFile(path.join(OUT, 'data', 'safe-hands.tar.gz'), Buffer.from(await snapshot.arrayBuffer()));
} finally {
  await db.close();
}

// GitHub Pages: serve files as-is (no Jekyll processing).
await writeFile(path.join(OUT, '.nojekyll'), '');

console.log(`Built ${path.relative(ROOT, OUT)}/ (${queries.length} scenarios).`);
