// Parsing helpers for the repository's SQL files. No Node or browser APIs are
// used here, so the test suite and the web demo share exactly this code.

const UP_MARKER = /^--\s*migrate:up\b.*$/m;
const DOWN_MARKER = /^--\s*migrate:down\b.*$/m;

/**
 * Split a dbmate migration file into its `up` and `down` sections.
 * @param {string} source
 * @returns {{ up: string, down: string }}
 */
export function splitMigration(source) {
  const up = UP_MARKER.exec(source);
  if (!up) {
    throw new Error('migration has no "-- migrate:up" section');
  }
  const afterUp = source.slice(up.index + up[0].length);
  const down = DOWN_MARKER.exec(afterUp);
  return {
    up: (down ? afterUp.slice(0, down.index) : afterUp).trim(),
    down: down ? afterUp.slice(down.index + down[0].length).trim() : '',
  };
}

/**
 * The dbmate version of a migration file name, e.g. "20261014000001".
 * @param {string} fileName
 */
export function migrationVersion(fileName) {
  const match = /^(\d+)_/.exec(fileName);
  if (!match) {
    throw new Error(`migration file name must start with a version: ${fileName}`);
  }
  return match[1];
}

/**
 * Parse a scenario file from queries/. The leading comment block holds the
 * metadata:
 *
 *   -- Scenario 4: Robbery in the Finance department
 *   -- Kind: read
 *   --
 *   -- Story paragraph(s)...
 *   --
 *   -- Changed from the report: ...
 *
 * @param {string} fileName
 * @param {string} source
 */
export function parseScenario(fileName, source) {
  const lines = source.replace(/\r\n/g, '\n').split('\n');
  const header = [];
  let i = 0;
  for (; i < lines.length && lines[i].startsWith('--'); i++) {
    header.push(lines[i].replace(/^--\s?/, ''));
  }
  const sql = lines.slice(i).join('\n').trim();

  const title = /^Scenario (\d+): (.+)$/.exec(header[0] ?? '');
  const kind = /^Kind: (read|write)$/.exec(header[1] ?? '');
  if (!title || !kind || !sql) {
    throw new Error(`${fileName}: expected "Scenario N: title", "Kind: read|write" and a statement`);
  }

  const paragraphs = header
    .slice(2)
    .join('\n')
    .split(/\n\s*\n/)
    .map((p) => p.replace(/\s*\n\s*/g, ' ').trim())
    .filter(Boolean);
  const changePrefix = 'Changed from the report:';
  const changes = paragraphs.find((p) => p.startsWith(changePrefix));
  const changeText = changes ? changes.slice(changePrefix.length).trim() : '';

  return {
    id: Number(title[1]),
    file: fileName,
    title: title[2],
    kind: kind[1],
    story: paragraphs.filter((p) => p !== changes).join('\n\n'),
    changes: changeText.charAt(0).toUpperCase() + changeText.slice(1),
    sql,
  };
}
