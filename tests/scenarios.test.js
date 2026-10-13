// The ten business scenarios from the report, run against the seed data.
// Write scenarios run inside a transaction that is rolled back afterwards.

import assert from 'node:assert/strict';
import { after, before, describe, test } from 'node:test';
import { loadScenarios, openSeededDatabase, withRollback } from '../src/database.js';
import { ids, rejectsWith, scalar } from './helpers.js';

let db;
/** @type {Map<number, Awaited<ReturnType<typeof loadScenarios>>[number]>} */
let scenarios;

before(async () => {
  db = await openSeededDatabase();
  scenarios = new Map((await loadScenarios()).map((s) => [s.id, s]));
});
after(() => db?.close());

const run = (id) => db.query(scenarios.get(id).sql);

test('there are ten scenarios, each with a story and a note on what changed', () => {
  assert.deepEqual([...scenarios.keys()], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  for (const s of scenarios.values()) {
    assert.ok(s.story.length > 40, `${s.file} story`);
    assert.ok(s.changes.length > 20, `${s.file} change note`);
    assert.equal(/^(update|delete|insert)\b/i.test(s.sql), s.kind === 'write', `${s.file} kind`);
  }
});

describe('read scenarios', () => {
  test('1. insured houses built before 2005, with owner phones', async () => {
    const { rows } = await run(1);
    assert.deepEqual(
      rows.map((r) => [r.title_deed, Number(r.year_built), Number(r.customer_id)]),
      [
        ['1167466', 1990, 202251],
        ['3463636', 2000, 202219],
        ['4287653', 2000, 202266],
        ['9075567', 2001, 202255],
        ['4478863', 2004, 202204],
      ],
    );
    assert.equal(rows.find((r) => r.title_deed === '3463636').phones, '03659872, 78330912');
  });

  test('1. a house built in 2005 or an uninsured one does not qualify', () =>
    withRollback(db, async () => {
      await db.query(`update house set year_built = 2005 where title_deed = '4478863'`);
      await db.query(`update house set insurance_id = null, coverage_pct = null where title_deed = '1167466'`);
      assert.deepEqual(
        (await run(1)).rows.map((r) => r.title_deed),
        ['3463636', '4287653', '9075567'],
      );
    }));

  test('4. male Finance staff other than the Finance manager', async () => {
    // Matches the result screenshot in the report (p. 107).
    assert.deepEqual(ids(await run(4)), [202147, 202183]);
  });

  test('6. unhappy customers with no active insurance', async () => {
    assert.deepEqual(ids(await run(6)), [202289, 202255]);
  });

  test('6. an unhappy customer who still has an active policy is left alone', () =>
    withRollback(db, async () => {
      await db.query('update payment_policy set is_active = true where receipt_no = 8');
      assert.deepEqual(ids(await run(6)), [202255]);
    }));

  test('7. mothers: female employees with a child, and female customers', async () => {
    const { rows } = await run(7);
    const of = (kind) => rows.filter((r) => r.kind === kind).map((r) => Number(r.person_id));
    assert.deepEqual(of('Employee'), [202100, 202126]);
    assert.deepEqual(of('Customer'), [202204, 202219, 202244, 202255, 202266, 202271]);
  });

  test('8. customers under 50 with below-average health coverage', async () => {
    // Same people as the report's result screenshot (p. 112).
    assert.deepEqual(ids(await run(8)).sort(), [202204, 202213, 202244, 202271, 202289]);
  });

  test('9. Executive staff plus every manager and the CEO, one row each', async () => {
    const { rows } = await run(9);
    assert.equal(rows.length, 12);
    assert.equal(new Set(rows.map((r) => r.employee_id)).size, 12);
    assert.equal(rows.find((r) => Number(r.employee_id) === 202104).emails.split(', ').length, 2);
  });
});

describe('write scenarios', () => {
  test('2. Health staff move to HR with a 5% raise, in one statement', () =>
    withRollback(db, async () => {
      const { rows } = await run(2);
      assert.deepEqual(ids(rows).sort(), [202126, 202148, 202177, 202182]);
      for (const r of rows) {
        assert.equal(Number(r.new_salary), Math.round(Number(r.old_salary) * 105) / 100);
      }
      // Ordered by number: PGlite sorts text with the C collation and a
      // server with a locale collation, so "order by name" differs between them.
      const counts = await db.query(
        `select name, employee_count::int as n from department_summary where name in ('HR', 'Health') order by dept_no`,
      );
      assert.deepEqual(
        counts.rows.map((r) => [r.name, r.n]),
        [
          ['HR', 5],
          ['Health', 0],
        ],
      );
    }));

  test('3. everyone who served Wael Kfoury takes a 13% cut', () =>
    withRollback(db, async () => {
      const { rows } = await run(3);
      assert.deepEqual(rows.map((r) => [Number(r.employee_id), Number(r.new_salary)]).sort(), [
        [202159, 5481],
        [202182, 6525],
      ]);
    }));

  test('3. a cut below the 5000 minimum fails as a whole, changing nobody', () =>
    withRollback(db, async () => {
      await db.query('update employee set salary = 5700 where employee_id = 202159');
      await db.exec('savepoint before_cut');
      await rejectsWith(run(3), '23514');
      await db.exec('rollback to savepoint before_cut');
      assert.equal(scalar(await db.query('select salary from employee where employee_id = 202182')), 7500);
    }));

  test('5. the raise goes only to below-average earners who have dependents', () =>
    withRollback(db, async () => {
      const raised = ids(await run(5)).sort();
      assert.deepEqual(raised, [202126, 202148, 202166, 202182]);
      // Ola Makki (202108) earns below average but has no dependents.
      assert.equal(scalar(await db.query('select salary from employee where employee_id = 202108')), 6777);
    }));

  test('10. nobody in the seed data is 60 or older, so nobody is removed', () =>
    withRollback(db, async () => {
      assert.equal((await run(10)).rows.length, 0);
    }));

  test('10. only Maintenance staff aged 60+ are removed, with their dependent rows', () =>
    withRollback(db, async () => {
      const add = `insert into employee
        (employee_id, first_name, middle_name, last_name, birth_date, gender, role, supervisor_id, dept_no)
        values ($1, 'Old', 'O', 'Timer', current_date - interval '61 years', 'Male', 'Trainer', 202109, $2)`;
      await db.query(add, [300001, 544]); // Maintenance
      await db.query(add, [300002, 502]); // IT: same age, different department
      await db.query(`insert into dependent values (300001, 'Kid', 'Male', '1990-01-01', 'Son')`);
      await db.query(`insert into employee_phone values (300001, '70000000')`);
      await db.query('update employee set supervisor_id = 300001 where employee_id = 202115');

      assert.deepEqual(ids(await run(10)), [300001]);
      assert.equal(scalar(await db.query('select count(*) from employee where employee_id = 300002')), 1);
      assert.equal(scalar(await db.query('select count(*) from dependent where employee_id = 300001')), 0);
      assert.equal(scalar(await db.query('select count(*) from employee_phone where employee_id = 300001')), 0);
      assert.equal(
        (await db.query('select supervisor_id from employee where employee_id = 202115')).rows[0].supervisor_id,
        null,
      );
      assert.equal(
        scalar(await db.query(`select employee_count from department_summary where name = 'Maintenance'`)),
        3,
      );
    }));

  test('10. removing a department manager is refused until someone replaces them', () =>
    withRollback(db, async () => {
      await db.query(`update employee set birth_date = '1950-01-01' where employee_id = 202109`);
      assert.deepEqual(ids(await run(10)), [202109]);
      await rejectsWith(db.exec('set constraints all immediate'), '23503');
    }));
});
