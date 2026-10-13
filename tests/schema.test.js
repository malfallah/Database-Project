// The constraints must actually reject bad data. Each case runs in a
// transaction that is rolled back, against the seeded database.

import assert from 'node:assert/strict';
import { after, before, describe, test } from 'node:test';
import { openSeededDatabase, withRollback } from '../src/database.js';
import { rejectsWith, scalar } from './helpers.js';

let db;
before(async () => {
  db = await openSeededDatabase();
});
after(() => db?.close());

const NEW_EMPLOYEE = `insert into employee
  (employee_id, first_name, middle_name, last_name, salary, birth_date, gender, role, supervisor_id, dept_no)
  values ($1, 'Test', 'T', 'Person', $2, '1990-01-01', $3, $4, $5, $6)`;
const employee = ({ id = 300001, salary = 6000, gender = 'Male', role = 'Advisor', supervisor = null, dept = 502 }) => [
  id,
  salary,
  gender,
  role,
  supervisor,
  dept,
];

describe('CHECK constraints', () => {
  const cases = [
    ['salary at or below the 5000 minimum', NEW_EMPLOYEE, employee({ salary: 5000 })],
    ['unknown gender', NEW_EMPLOYEE, employee({ gender: 'X' })],
    ['unknown role', NEW_EMPLOYEE, employee({ role: 'Intern' })],
    ['employee as their own supervisor', NEW_EMPLOYEE, employee({ id: 300001, supervisor: 300001 })],
    ['satisfaction outside 0-10', `insert into customer values (300001, 'A', 'B', 'C', 11, 'Female')`, []],
    ['payment where paid exceeds the bill', `update payment set paid = bill + 1 where receipt_no = 22`, []],
    ['negative payment', `update payment set paid = -1 where receipt_no = 22`, []],
    ['unknown payment type', `update payment set payment_type = 'LUNP SUM' where receipt_no = 22`, []],
    [
      'hospital discharge before admission',
      `update health_report set discharged_on = admitted_on - 1 where report_no = 53`,
      [],
    ],
    ['coverage below 30%', `update vehicle set coverage_pct = 20 where serial_no = 100000`, []],
    [
      'insured vehicle without a coverage percentage',
      `update vehicle set coverage_pct = null where serial_no = 100000`,
      [],
    ],
    ['house value at or below 5000', `update house set market_value = 5000 where title_deed = '3925632'`, []],
    [
      'customer engagement ending before it starts',
      `update deals_with set end_date = start_date - 1 where customer_id = 202200`,
      [],
    ],
    ['malformed phone number', `insert into customer_phone values (202200, '12-34-56')`, []],
    ['malformed email address', `insert into customer_email values (202200, 'not-an-email')`, []],
    ['unknown blood type', `update medical_record set blood_type = 'C+' where customer_id = 202204`, []],
    ['unknown currency', `insert into payment_currency values (22, 'Bitcoin')`, []],
    ['lowercase plate letter', `update vehicle set plate_letter = 'b' where serial_no = 100000`, []],
  ];
  for (const [name, sql, params] of cases) {
    test(`rejects ${name}`, () => withRollback(db, () => rejectsWith(db.query(sql, params), '23514')));
  }
});

describe('NOT NULL, UNIQUE and PRIMARY KEY constraints', () => {
  test('rejects a customer without a gender', () =>
    withRollback(db, () =>
      rejectsWith(db.query(`insert into customer values (300001, 'A', 'B', 'C', 5, null)`), '23502'),
    ));

  test('rejects an employee without a department (WORKS_FOR is total)', () =>
    withRollback(db, () =>
      rejectsWith(
        db.query(`insert into employee (employee_id, first_name, middle_name, last_name, role)
                  values (300001, 'A', 'B', 'C', 'Advisor')`),
        '23502',
      ),
    ));

  const cases = [
    ['duplicate department name', `insert into department values (999, 'Finance', 202155, current_date)`],
    ['one employee managing two departments', `insert into department values (999, 'Legal', 202155, current_date)`],
    [
      'a second health report for the same customer (CHECKS is 1:1)',
      `insert into health_report values (999, 202200, 'AUB', '2024-01-01', '2024-01-02', false, 39, 50)`,
    ],
    [
      'a second medical record for the same customer (PROVIDES is 1:1)',
      `insert into medical_record (customer_id, record_no, weight_kg, height_cm, age_years)
       values (202204, 99, 60, 160, 30)`,
    ],
    [
      'two vehicles with the same plate',
      `update vehicle set plate_letter = 'B', registration_no = 1234
       where serial_no = 200000`,
    ],
    [
      'a duplicate address even when street is NULL',
      `insert into customer_address (customer_id, district, city, street, apartment_no)
       values (202213, 'Jnoub', 'Blat', null, null)`,
    ],
    ['a duplicate phone for the same employee', `insert into employee_phone values (202104, '71214707')`],
  ];
  for (const [name, sql] of cases) {
    test(`rejects ${name}`, () => withRollback(db, () => rejectsWith(db.query(sql), '23505')));
  }
});

describe('FOREIGN KEY constraints', () => {
  const cases = [
    ['an employee in a department that does not exist', NEW_EMPLOYEE, employee({ dept: 999 })],
    ['a supervisor who does not exist', NEW_EMPLOYEE, employee({ supervisor: 999999 })],
    ['a vehicle owned by an unknown customer', `update vehicle set owner_id = 999999 where serial_no = 100000`, []],
    ['a payment linked to an unknown policy', `insert into payment_policy values (45, 75, true)`, []],
    ['an emergency call from an unknown customer', `insert into calls_for_emergency values (577, 202260, '116')`, []],
    ['a contract with an unknown company', `insert into transacts values (544, 'HHL', 6)`, []],
    ['service by an unknown employee', `insert into serves values (202200, 999999)`, []],
    ['deleting an insurance policy that still covers assets', `delete from insurance where insurance_id = 39`, []],
    ['deleting a customer who still owns a vehicle', `delete from customer where customer_id = 202200`, []],
  ];
  for (const [name, sql, params] of cases) {
    test(`rejects ${name}`, () => withRollback(db, () => rejectsWith(db.query(sql, params), '23503')));
  }

  test('a department manager must exist, checked at commit (deferred)', async () => {
    await db.exec('begin');
    try {
      await db.query(`insert into department values (999, 'Legal', 999999, current_date)`);
      await rejectsWith(db.exec('commit'), '23503');
    } finally {
      await db.exec('rollback').catch(() => {});
    }
    assert.equal(scalar(await db.query('select count(*) from department where dept_no = 999')), 0);
  });

  test('a department and its new manager can be created in one transaction', () =>
    withRollback(db, async () => {
      await db.query(`insert into department values (999, 'Legal', 300001, current_date)`);
      await db.query(NEW_EMPLOYEE, employee({ dept: 999 }));
      await db.exec('set constraints all immediate');
      assert.equal(scalar(await db.query('select employee_count from department_summary where dept_no = 999')), 1);
    }));
});

describe('referential actions', () => {
  test('deleting an employee removes dependents, contacts and assignments, and orphans supervisees', () =>
    withRollback(db, async () => {
      // 202100 supervises four people and has a dependent; hand over the
      // department she manages first.
      await db.query('update department set manager_id = 202103 where manager_id = 202100');
      await db.query('delete from employee where employee_id = 202100');
      await db.exec('set constraints all immediate');
      for (const table of ['dependent', 'employee_phone', 'employee_email', 'employee_address', 'serves']) {
        assert.equal(scalar(await db.query(`select count(*) from ${table} where employee_id = 202100`)), 0, table);
      }
      assert.equal(scalar(await db.query('select count(*) from employee where supervisor_id = 202100')), 0);
      assert.equal(
        scalar(await db.query('select count(*) from employee where employee_id in (202103, 202147, 202154, 202187)')),
        4,
      );
    }));

  test('deleting a department manager fails until the department gets a new one', () =>
    withRollback(db, async () => {
      await db.query('delete from employee where employee_id = 202109');
      await rejectsWith(db.exec('set constraints all immediate'), '23503');
    }));

  test('renaming a contracted company cascades to its contact details and contracts', () =>
    withRollback(db, async () => {
      await db.query(`update contracted_company set name = 'HHI Health' where name = 'HHI'`);
      for (const table of [
        'contracted_company_phone',
        'contracted_company_email',
        'contracted_company_location',
        'transacts',
      ]) {
        assert.equal(
          scalar(await db.query(`select count(*) from ${table} where company_name = 'HHI Health'`)),
          1,
          table,
        );
      }
    }));

  test('amount_due is derived from bill and paid and cannot be written directly', () =>
    withRollback(db, async () => {
      await db.query('update payment set paid = 500 where receipt_no = 22');
      assert.equal(scalar(await db.query('select amount_due from payment where receipt_no = 22')), 300);
      await rejectsWith(db.query('update payment set amount_due = 0 where receipt_no = 22'), '428C9');
    }));
});

describe('catalog checks', () => {
  test('every table has a primary key', async () => {
    const { rows } = await db.query(`
      select t.table_name from information_schema.tables as t
      where t.table_schema = 'public' and t.table_type = 'BASE TABLE'
        and not exists (
          select 1 from information_schema.table_constraints as c
          where c.table_schema = t.table_schema and c.table_name = t.table_name
            and c.constraint_type = 'PRIMARY KEY')`);
    assert.deepEqual(rows, []);
  });

  test('every foreign key is backed by an index on its leading columns', async () => {
    const { rows } = await db.query(`
      select c.conrelid::regclass::text as table_name, c.conname
      from pg_constraint as c
      where c.contype = 'f'
        and not exists (
          select 1 from pg_index as i
          where i.indrelid = c.conrelid
            and (i.indkey::int2[])[0:array_length(c.conkey, 1) - 1] @> c.conkey
            and (i.indkey::int2[])[0:array_length(c.conkey, 1) - 1] <@ c.conkey)
      order by 1, 2`);
    assert.deepEqual(rows, [], `unindexed foreign keys: ${rows.map((r) => r.conname).join(', ')}`);
  });

  test('no floating-point columns (money and measurements are numeric)', async () => {
    const { rows } = await db.query(`
      select table_name, column_name from information_schema.columns
      where table_schema = 'public' and data_type in ('real', 'double precision')`);
    assert.deepEqual(rows, []);
  });
});
