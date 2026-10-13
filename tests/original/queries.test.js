// The report's scenario queries, with only their identifiers renamed to the
// new schema (EMPLOYEE.Dno -> employee.dept_no, DEPENDENT.EID ->
// dependent.employee_id, and so on; see docs/schema.md). Their logic is kept
// exactly, so each test shows the original defect next to the fixed query in
// queries/. Where the report includes a result screenshot, the test checks
// that the reproduction gives the same wrong answer the report shows.

import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { loadScenarios, openSeededDatabase, withRollback } from '../../src/database.js';
import { ids, rejectsWith } from '../helpers.js';

let db;
let fixed;
before(async () => {
  db = await openSeededDatabase();
  const scenarios = await loadScenarios();
  fixed = (id) => db.query(scenarios.find((s) => s.id === id).sql);
});
after(() => db?.close());

const noDependents = async (employeeIds) =>
  ids(
    await db.query(
      `select employee_id from employee as e
       where employee_id = any($1) and not exists (select 1 from dependent as d where d.employee_id = e.employee_id)
       order by 1`,
      [employeeIds],
    ),
  );

test('Q1: the original ignores insurance, includes 2005, and only looks in Sour', () =>
  withRollback(db, async () => {
    const original = `
      select c.customer_id from customer c, customer_phone cpn, house h
      where h.owner_id = c.customer_id and h.year_built <= 2005
        and upper(h.city) = 'SOUR' and cpn.customer_id = c.customer_id`;
    // Matches the report's screenshot (p. 100): only Reem Daher.
    assert.deepEqual(ids(await db.query(original)), [202255]);

    // An uninsured house built in 2005 in Sour is picked up by the original.
    await db.query(`update house set year_built = 2005, insurance_id = null, coverage_pct = null, city = 'Sour'
                    where title_deed = '3212436'`);
    // (Kareem has two phones, so the original lists him twice.)
    assert.deepEqual([...new Set(ids(await db.query(original)))].sort(), [202213, 202255]);
    assert.ok(!ids(await fixed(1), 'customer_id').includes(202213));
  }));

test('Q2: two UPDATEs joined with AND is a syntax error', async () => {
  await rejectsWith(
    db.exec(`
      update employee set salary = 1.05 * salary
      where dept_no in (select dept_no from department where name = 'Health');
      and
      update employee set dept_no = 1
      where dept_no in (select dept_no from department where name = 'Health');`),
    '42601',
  );
});

test('Q4: three of the four UNION branches reference columns that do not exist', async () => {
  await rejectsWith(
    db.query(`select e.employee_id from employee e, department d
              where e.dept_no = d.number and d.dname = 'Finance' and e.gender = 'Male'`),
    '42703',
  );
  await rejectsWith(db.query('select e.employee_ids from employee e'), '42703');
});

test('Q5: the uncorrelated EXISTS raises employees who have no dependents', () =>
  withRollback(db, async () => {
    const raised = ids(
      await db.query(`
        update employee set salary = salary * 1.2
        where exists (select * from dependent dep, employee e where e.employee_id = dep.employee_id)
          and salary < (select avg(salary) from employee)
        returning employee_id`),
    );
    // Ola Makki (202108) and Farah Farhat (202123) have no dependents; the
    // report's own screenshot (p. 108) shows both of them getting the raise.
    const wronglyRaised = await noDependents(raised);
    assert.ok(wronglyRaised.includes(202108) && wronglyRaised.includes(202123));
  }));

test('Q5 fixed: nobody without dependents is raised', () =>
  withRollback(db, async () => {
    assert.deepEqual(await noDependents(ids(await fixed(5))), []);
  }));

test('Q6: the NOT EXISTS filter is a no-op, so customers with active insurance are included', () =>
  withRollback(db, async () => {
    const original = `
      select distinct c.customer_id from customer c, customer_phone cp, customer_address cl, insurance
      where satisfaction < 6 and c.customer_id = cl.customer_id and c.customer_id = cp.customer_id
        and not exists (select * from insurance, customer where customer_id = insurance_id)
      order by 1`;
    await db.query('update payment_policy set is_active = true where receipt_no = 8'); // Hassan, 202289
    assert.deepEqual(ids(await db.query(original)), [202255, 202289]);
    assert.deepEqual(ids(await fixed(6)), [202255]);
  }));

test('Q7: the uncorrelated EXISTS treats every female employee as a mother', async () => {
  const { rows } = await db.query(`
    select distinct e.employee_id from employee e, employee_phone ep
    where e.gender = 'Female' and e.employee_id = ep.employee_id
      and exists (select * from dependent d, employee em
                  where em.employee_id = d.employee_id
                    and (d.relationship = 'Son' or d.relationship = 'Daughter'))`);
  const flagged = ids(rows);
  // Asmaa Ballouz (202193) appears in the report's result (p. 110) but has no
  // dependents at all.
  assert.ok(flagged.includes(202193));
  assert.ok((await noDependents(flagged)).length > 0);

  const mothers = (await fixed(7)).rows.filter((r) => r.kind === 'Employee').map((r) => Number(r.person_id));
  assert.deepEqual(await noDependents(mothers), []);
});

test('Q10: an UPDATE nested in DELETE ... WHERE is a syntax error', async () => {
  await rejectsWith(
    db.exec(`
      delete from employee
      where (update department set name = name where name = 'Maintenance')
        and birth_date < '1962-01-01';`),
    '42601',
  );
});

test('Q10: the DELETE has no department filter, so it removes staff from every department', () =>
  withRollback(db, async () => {
    await db.query(`insert into employee
      (employee_id, first_name, middle_name, last_name, birth_date, gender, role, dept_no)
      values (300002, 'Old', 'O', 'Timer', '1950-01-01', 'Male', 'Advisor', 502)`);
    await db.exec('savepoint s');
    assert.deepEqual(
      ids(await db.query(`delete from employee where birth_date < '1962-01-01' returning employee_id`)),
      [300002],
    );
    await db.exec('rollback to savepoint s');
    assert.deepEqual(ids(await fixed(10)), []);
  }));
