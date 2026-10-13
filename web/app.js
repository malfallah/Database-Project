// Safe Hands DB demo: PostgreSQL 18 (PGlite) running in the browser, built
// from the same migration, seed and scenario files as the repository.

import { parseScenario } from './js/sql-files.js';
import { PGlite } from './vendor/pglite/index.js';

const MERMAID_URL = 'https://cdn.jsdelivr.net/npm/mermaid@11.17.2/dist/mermaid.esm.min.mjs';
const MAX_ROWS = 500;

const $ = (id) => document.getElementById(id);
const state = { db: null, snapshot: null, scenarios: [], current: null, busy: false };

// ---------------------------------------------------------------------------
// Rendering helpers (all text goes through textContent, never innerHTML)
// ---------------------------------------------------------------------------

function el(tag, props = {}, ...children) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(props)) {
    if (key === 'class') node.className = value;
    else if (key.startsWith('on')) node.addEventListener(key.slice(2), value);
    else if (value !== undefined && value !== null && value !== false) node.setAttribute(key, value);
  }
  for (const child of children.flat()) {
    if (child !== null && child !== undefined && child !== false) {
      node.append(child instanceof Node ? child : document.createTextNode(String(child)));
    }
  }
  return node;
}

function formatValue(value) {
  if (value === null || value === undefined) return { text: 'NULL', cls: 'null' };
  if (value instanceof Date) {
    const iso = value.toISOString();
    return { text: iso.endsWith('T00:00:00.000Z') ? iso.slice(0, 10) : iso.replace('T', ' ').replace('.000Z', 'Z') };
  }
  if (typeof value === 'number' || typeof value === 'bigint') return { text: String(value), cls: 'num' };
  if (typeof value === 'string' && /^-?\d+(\.\d+)?$/.test(value)) return { text: value, cls: 'num' };
  if (typeof value === 'object') return { text: JSON.stringify(value) };
  return { text: String(value) };
}

function resultTable(result) {
  const fields = result.fields ?? [];
  if (!fields.length) return null;
  const rows = result.rows.slice(0, MAX_ROWS);
  return el(
    'div',
    { class: 'table-scroll' },
    el(
      'table',
      {},
      el('thead', {}, el('tr', {}, ...fields.map((f) => el('th', { scope: 'col' }, f.name)))),
      el(
        'tbody',
        {},
        ...rows.map((row) =>
          el(
            'tr',
            {},
            ...fields.map((f) => {
              const { text, cls } = formatValue(row[f.name]);
              return el('td', { class: cls }, text);
            }),
          ),
        ),
      ),
    ),
  );
}

function renderResult(target, result, elapsedMs, note) {
  const count = result.rows?.length ?? 0;
  const parts = [];
  if (result.fields?.length) parts.push(`${count} row${count === 1 ? '' : 's'}`);
  if (!result.fields?.length && result.affectedRows !== undefined) parts.push(`${result.affectedRows} row(s) affected`);
  if (count > MAX_ROWS) parts.push(`showing the first ${MAX_ROWS}`);
  parts.push(`${elapsedMs.toFixed(0)} ms`);
  if (note) parts.push(note);
  target.replaceChildren(el('p', { class: 'result-meta' }, parts.join(' · ')), resultTable(result) ?? '');
}

function renderError(target, error) {
  target.replaceChildren(el('p', { class: 'error', role: 'alert' }, error.message ?? String(error)));
}

function setStatus(text, kind) {
  $('status-text').textContent = text;
  $('status').className = `status ${kind ?? ''}`;
}

function setReady(ready) {
  state.busy = !ready;
  for (const button of document.querySelectorAll('[data-needs-db]')) button.disabled = !ready;
  $('reset').disabled = !ready;
  $('sql-run').disabled = !ready;
}

// ---------------------------------------------------------------------------
// Database lifecycle
// ---------------------------------------------------------------------------

async function fetchText(path) {
  const response = await fetch(path);
  if (!response.ok) throw new Error(`Could not load ${path} (${response.status})`);
  return response.text();
}

async function boot() {
  const manifest = await (await fetch('sql/manifest.json')).json();
  const repo = manifest.repository;
  if (repo) {
    $('repo-link').href = repo;
    $('schema-doc-link').href = `${repo}/blob/main/docs/schema.md`;
  }

  const started = performance.now();
  // The data directory was built from db/migrations and db/seed.sql by
  // scripts/build-site.js; loading it skips initdb, which is slow in WASM.
  const snapshotRequest = fetch('data/safe-hands.tar.gz').then(async (response) => {
    if (!response.ok) throw new Error(`Could not load the database (${response.status})`);
    return new Blob([await response.arrayBuffer()], { type: 'application/x-gzip' });
  });

  const scenarioSources = await Promise.all(
    manifest.queries.map(async (file) => [file, await fetchText(`sql/queries/${file}`)]),
  );
  state.scenarios = scenarioSources.map(([file, source]) => parseScenario(file, source)).sort((a, b) => a.id - b.id);
  renderScenarioList();
  selectScenario(state.scenarios[0].id);

  state.snapshot = await snapshotRequest;
  state.db = await PGlite.create({ loadDataDir: state.snapshot });

  await populateTableSelect();
  setStatus(`Ready in ${((performance.now() - started) / 1000).toFixed(1)} s · seeded`, 'ready');
  setReady(true);
}

async function resetDatabase() {
  setReady(false);
  setStatus('Resetting…');
  await state.db.close();
  state.db = await PGlite.create({ loadDataDir: state.snapshot });
  setStatus('Ready · data reset to the seed', 'ready');
  setReady(true);
  for (const id of ['scenario-result', 'sql-result']) $(id)?.replaceChildren();
  await showTable($('table-select').value);
}

async function timed(fn) {
  const started = performance.now();
  const result = await fn();
  return [result, performance.now() - started];
}

// ---------------------------------------------------------------------------
// Scenarios
// ---------------------------------------------------------------------------

function renderScenarioList() {
  $('scenario-list').replaceChildren(
    ...state.scenarios.map((s) =>
      el(
        'li',
        {},
        el(
          'button',
          { type: 'button', 'data-id': s.id, onclick: () => selectScenario(s.id) },
          el('span', { class: 'num' }, s.id),
          el('span', {}, s.title),
          el('span', { class: `badge ${s.kind}` }, s.kind),
        ),
      ),
    ),
  );
}

function selectScenario(id) {
  const s = state.scenarios.find((x) => x.id === id);
  state.current = s;
  for (const button of $('scenario-list').querySelectorAll('button')) {
    button.setAttribute('aria-current', String(Number(button.dataset.id) === id));
  }
  const runLabel = s.kind === 'write' ? 'Run (changes stay until you reset)' : 'Run';
  $('scenario').replaceChildren(
    el('p', {}, el('span', { class: `badge ${s.kind}` }, s.kind === 'write' ? 'writes data' : 'read only')),
    el('h2', {}, `${s.id}. ${s.title}`),
    el('p', { class: 'story' }, s.story),
    el('div', { class: 'callout' }, el('strong', {}, 'What changed from the 2022 report'), s.changes),
    el('pre', { class: 'code' }, el('code', {}, s.sql)),
    el(
      'div',
      { class: 'actions' },
      el(
        'button',
        {
          type: 'button',
          class: 'button',
          'data-needs-db': '',
          disabled: !state.db || state.busy,
          onclick: runScenario,
        },
        runLabel,
      ),
    ),
    el('div', { id: 'scenario-result' }),
  );
}

async function runScenario() {
  const target = $('scenario-result');
  try {
    const [result, ms] = await timed(() => state.db.query(state.current.sql));
    const note = state.current.kind === 'write' ? 'rows returned show each change' : '';
    renderResult(target, result, ms, note);
  } catch (error) {
    renderError(target, error);
  }
}

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

async function populateTableSelect() {
  const { rows } = await state.db.query(`
    select c.relname as name, c.relkind as kind
    from pg_class as c join pg_namespace as n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r', 'v') and c.relname <> 'schema_migrations'
    order by c.relkind, c.relname`);
  $('table-select').replaceChildren(
    el('optgroup', { label: 'Tables' }, ...rows.filter((r) => r.kind === 'r').map((r) => el('option', {}, r.name))),
    el('optgroup', { label: 'Views' }, ...rows.filter((r) => r.kind === 'v').map((r) => el('option', {}, r.name))),
  );
  $('table-select').value = 'employee';
  await showTable('employee');
}

async function showTable(name) {
  if (!name || !state.db) return;
  const target = $('table-result');
  try {
    // The name comes from the catalog query above, but quote it anyway.
    const identifier = `"${name.replaceAll('"', '""')}"`;
    const comment = await state.db.query(`select obj_description($1::regclass, 'pg_class') as comment`, [identifier]);
    $('table-comment').textContent = comment.rows[0]?.comment ?? '';
    const [result, ms] = await timed(() => state.db.query(`select * from ${identifier} limit ${MAX_ROWS + 1}`));
    renderResult(target, result, ms);
  } catch (error) {
    renderError(target, error);
  }
}

// ---------------------------------------------------------------------------
// SQL console
// ---------------------------------------------------------------------------

async function runConsole() {
  const sql = $('sql-input').value.trim();
  if (!sql || !state.db) return;
  const target = $('sql-result');
  try {
    const [results, ms] = await timed(() => state.db.exec(sql));
    const last = results.at(-1) ?? { rows: [], fields: [] };
    const note = results.length > 1 ? `${results.length} statements, showing the last` : '';
    renderResult(target, last, ms, note);
  } catch (error) {
    renderError(target, error);
  }
}

// ---------------------------------------------------------------------------
// Schema diagram (Mermaid, loaded on first use)
// ---------------------------------------------------------------------------

let mermaidPromise;
function loadMermaid() {
  if (!mermaidPromise) {
    mermaidPromise = import(MERMAID_URL).then((m) => {
      const dark = matchMedia('(prefers-color-scheme: dark)').matches;
      m.default.initialize({
        startOnLoad: false,
        theme: dark ? 'dark' : 'neutral',
        securityLevel: 'strict',
        er: { useMaxWidth: true },
      });
      return m.default;
    });
  }
  return mermaidPromise;
}

async function renderDiagram() {
  const target = $('diagram');
  try {
    const file = $('schema-columns').checked ? 'er/full.mmd' : 'er/core.mmd';
    const [source, mermaid] = await Promise.all([fetchText(file), loadMermaid()]);
    // Laid out left to right, the core diagram is about as wide as the page
    // and readable at full size; top to bottom it is five times wider than
    // tall and its labels shrink to a third when fitted.
    const leftToRight = source.replace(/^erDiagram$/m, 'erDiagram\n    direction LR');
    const { svg } = await mermaid.render(`er-${Date.now()}`, leftToRight);
    const doc = new DOMParser().parseFromString(svg, 'image/svg+xml');
    target.replaceChildren(document.importNode(doc.documentElement, true));
  } catch (error) {
    renderError(target, error);
  }
}

// ---------------------------------------------------------------------------
// Navigation and wiring
// ---------------------------------------------------------------------------

function showView(name) {
  for (const tab of document.querySelectorAll('.tab'))
    tab.setAttribute('aria-pressed', String(tab.dataset.view === name));
  for (const view of document.querySelectorAll('.view')) view.hidden = view.id !== `view-${name}`;
  if (name === 'schema' && !$('diagram').querySelector('svg')) renderDiagram();
  if (location.hash !== `#${name}`) history.replaceState(null, '', `#${name}`);
}

for (const tab of document.querySelectorAll('.tab')) tab.addEventListener('click', () => showView(tab.dataset.view));
$('reset').addEventListener('click', resetDatabase);
$('sql-run').addEventListener('click', runConsole);
$('sql-input').addEventListener('keydown', (event) => {
  if (event.key === 'Enter' && (event.ctrlKey || event.metaKey)) {
    event.preventDefault();
    runConsole();
  }
});
$('table-select').addEventListener('change', (event) => showTable(event.target.value));
$('schema-columns').addEventListener('change', renderDiagram);

const initial = location.hash.slice(1);
if (['scenarios', 'tables', 'sql', 'schema'].includes(initial)) showView(initial);

boot().catch((error) => {
  console.error(error);
  setStatus('Could not start the database', 'failed');
  renderError($('scenario-result') ?? $('scenario'), error);
});
