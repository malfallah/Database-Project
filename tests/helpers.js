import assert from 'node:assert/strict';

/**
 * Assert that a statement fails with the given SQLSTATE.
 * 23502 not_null_violation, 23503 foreign_key_violation, 23505 unique_violation,
 * 23514 check_violation, 42601 syntax_error, 42703 undefined_column.
 * @param {Promise<unknown>} promise
 * @param {string} sqlstate
 */
export async function rejectsWith(promise, sqlstate) {
  await assert.rejects(promise, (error) => {
    assert.equal(error.code, sqlstate, `expected SQLSTATE ${sqlstate}, got ${error.code}: ${error.message}`);
    return true;
  });
}

/** First column (or the named column) of every row, as numbers. Accepts a result or its rows. */
export function ids(resultOrRows, column) {
  const rows = Array.isArray(resultOrRows) ? resultOrRows : resultOrRows.rows;
  return rows.map((row) => Number(row[column ?? Object.keys(row)[0]]));
}

/** Single scalar from a one-row, one-column result, as a number. */
export function scalar(result) {
  return Number(Object.values(result.rows[0])[0]);
}
