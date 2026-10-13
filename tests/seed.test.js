import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { openSeededDatabase } from '../src/database.js';
import { scalar } from './helpers.js';

let db;
before(async () => {
  db = await openSeededDatabase();
});
after(() => db?.close());

test('seed loads the expected number of rows into every table', async () => {
  const expected = {
    department: 10,
    employee: 31,
    department_location: 10,
    dependent: 10,
    employee_address: 31,
    employee_phone: 32,
    employee_email: 32,
    customer: 12,
    customer_address: 14,
    customer_phone: 15,
    customer_email: 15,
    serves: 20,
    deals_with: 10,
    calls_for_emergency: 10,
    medical_record: 11,
    insurance: 10,
    vehicle: 10,
    vehicle_color: 13,
    house: 10,
    health_report: 10,
    payment: 12,
    payment_currency: 12,
    payment_date: 12,
    payment_policy: 8,
    expense: 10,
    pays: 16,
    contracted_company: 10,
    contracted_company_location: 10,
    contracted_company_phone: 10,
    contracted_company_email: 10,
    transacts: 10,
  };
  const actual = {};
  for (const table of Object.keys(expected)) {
    actual[table] = scalar(await db.query(`select count(*) from ${table}`));
  }
  assert.deepEqual(actual, expected);
});

test('every employee and customer can be contacted', async () => {
  for (const [people, key, phones, emails] of [
    ['employee', 'employee_id', 'employee_phone', 'employee_email'],
    ['customer', 'customer_id', 'customer_phone', 'customer_email'],
  ]) {
    const { rows } = await db.query(`
      select p.${key} from ${people} as p
      where not exists (select 1 from ${phones} as x where x.${key} = p.${key})
         or not exists (select 1 from ${emails} as x where x.${key} = p.${key})`);
    assert.deepEqual(rows, [], `${people} without a phone or email`);
  }
});

test('no real-looking email domains are published', async () => {
  const { rows } = await db.query(`
    select email from (
      select email from employee_email
      union all select email from customer_email
      union all select email from contracted_company_email) as e
    where email not like '%@example.com'`);
  assert.deepEqual(rows, []);
});

test('department head counts are derived, not stored', async () => {
  const { rows } = await db.query(
    'select name, employee_count::int as employees, customer_count::int as customers from department_summary order by dept_no',
  );
  const total = rows.reduce((sum, r) => sum + r.employees, 0);
  assert.equal(total, 31);
  assert.deepEqual(
    rows.find((r) => r.name === 'Finance'),
    { name: 'Finance', employees: 5, customers: 1 },
  );
});

test('every manager runs exactly one department', async () => {
  assert.equal(scalar(await db.query('select count(distinct manager_id) from department')), 10);
});
