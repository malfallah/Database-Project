// Reproduces what happens when the report's original script is run as-is.
// Each assertion pins a defect listed in docs/errata.md; the tests in
// tests/*.test.js show the corresponding fix.

import assert from 'node:assert/strict';
import { after, before, describe, test } from 'node:test';
import { openDatabase } from '../../src/database.js';
import { scalar } from '../helpers.js';
import { loadOriginalData, readOriginal } from './staging.js';

describe('original DDL (report section VIII), run unmodified', () => {
  let db;
  let outcome;
  before(async () => {
    db = await openDatabase();
    const ddl = (await readOriginal('01_schema.sql')).replace(/^--.*$/gm, '');
    outcome = [];
    for (const statement of ddl
      .split(/;\s*\n/)
      .map((s) => s.trim())
      .filter(Boolean)) {
      const table = /CREATE TABLE (\w+)/i.exec(statement)?.[1] ?? statement.slice(0, 20);
      try {
        await db.exec(statement);
        outcome.push({ table, ok: true });
      } catch (error) {
        outcome.push({ table, ok: false, error: error.message });
      }
    }
  });
  after(() => db?.close());

  const failed = (table) => outcome.find((o) => o.table === table && !o.ok);

  test('only 17 of the 38 tables get created', () => {
    const created = outcome.filter((o) => o.ok).map((o) => o.table);
    assert.equal(created.length, 17);
    assert.ok(!created.includes('EMPLOYEE') && !created.includes('CUSTOMER') && !created.includes('PAYMENT'));
  });

  test('curly quotes are not string delimiters', () => {
    assert.match(failed('IS_ACTIVE').error, /column "‘t’" does not exist/);
    assert.match(failed('CUSTOMER').error, /column "‘male’" does not exist/);
  });

  test('trailing commas before the closing parenthesis', () => {
    for (const table of ['EXPENSE', 'CONTRACTING_COMPANY', 'EMPLOYEE_LOCATION', 'CUSTOMER_LOCATION']) {
      assert.match(failed(table).error, /syntax error at or near "\)"/, table);
    }
  });

  test('a semicolon inside CREATE TABLE cuts the statement in two', () => {
    assert.match(failed('DEPARTMENT').error, /syntax error at end of input/);
    assert.match(failed('HOUSE_LOCATION').error, /syntax error at end of input/);
  });

  test('tables referenced before they are created', () => {
    assert.match(failed('MEDICAL_RECORD').error, /relation "customer" does not exist/);
    assert.match(failed('HOUSE').error, /relation "insurance" does not exist/);
  });

  test('"#" in identifiers is Oracle-only (dialect difference, not a defect)', () => {
    assert.match(failed('VEHICLE').error, /syntax error at or near "#"/);
    assert.match(failed('CALLS_FOR_EMERGENCY').error, /syntax error at or near "#"/);
  });
});

describe('original data (report section X), loaded into permissive staging tables', () => {
  let db;
  let failures;
  before(async () => {
    db = await openDatabase();
    failures = await loadOriginalData(db);
  });
  after(() => db?.close());

  const q = async (sql) => (await db.query(sql)).rows;
  const count = async (sql) => scalar(await db.query(sql));

  test('four INSERT statements are not valid SQL in any dialect', () => {
    assert.deepEqual(
      failures.map((f) => f.statement),
      [
        "INSERT INTO INSURANCE VALUES 11, 'Mandatory', 75);",
        "INSERT INTO EMPLOYEE_LOCATION VALUES (202199, 'Kaslik', 'AlRoum' 320);",
        "INSERT INTO EMPLOYEE_LOCATION VALUES (202147, 'Beirut', 'AlHamra' NULL);",
        "INSERT INTO EMPLOYEE_LOCATION VALUES (202191, 'Chtoura','Jdita' 7);",
      ],
    );
  });

  test('EMPLOYEE_LOCATION repeats a primary key (202182), so one address is lost', async () => {
    assert.deepEqual(
      await q(`select employee_id, count(*)::int as n from original.employee_location
               group by employee_id having count(*) > 1`),
      [{ employee_id: '202182', n: 2 }],
    );
  });

  test('INSURANCE values are in (id, type, coverage) order but the table is (id, coverage, type)', async () => {
    assert.equal(await count(`select count(*) from original.insurance where coverage !~ '^[0-9]+$'`), 9);
  });

  test('EXPENSE values are in (number, item, price, ...) order but the table is (item, price, number, ...)', async () => {
    assert.equal(await count(`select count(*) from original.expense where price !~ '^[0-9.]+$'`), 10);
  });

  test('PAYMENT: ReceiptNo and Paid are swapped', async () => {
    // HAS1 records (customer, receipt) for all 12 payments. As declared,
    // (Paid, Type, Bill, Mechanism, ReceiptNo, CID), none of those pairs exist;
    // read with the first value as the receipt number, all of them do.
    const pairs = (receiptColumn) =>
      count(`select count(*) from original.has1 as h join original.payment as p
             on p.cid = h.customer_id and p.${receiptColumn} = h.receiptno`);
    assert.equal(await pairs('receiptno'), 0);
    assert.equal(await pairs('paid'), 12);

    // The other child tables also reference the first value, every time.
    for (const [table, column] of [
      ['payment_currency', 'receiptno'],
      ['payment_date', 'receiptno'],
      ['is_active', 'pnum'],
    ]) {
      assert.equal(
        await count(`select count(*) from original.${table} as c
                     where not exists (select 1 from original.payment as p where p.paid = c.${column})`),
        0,
        table,
      );
    }

    // As declared, customer 202204 paid 54 on a bill of 38.5; swapped back,
    // nobody has paid more than their bill.
    assert.equal(await count(`select count(*) from original.payment where paid::numeric > bill::numeric`), 1);
    assert.equal(await count(`select count(*) from original.payment where receiptno::numeric > bill::numeric`), 0);
  });

  test('HEALTH: every patient is discharged before being admitted', async () => {
    assert.equal(await count(`select count(*) from original.health where exit_date::date < enter_date::date`), 10);
  });

  test('rows that point at things that do not exist (no foreign keys)', async () => {
    const orphans = await q(`
      select 'calls_for_emergency.cnum' as ref, cnum as value from original.calls_for_emergency
        where cnum not in (select customer_id from original.customer)
      union all select 'transacts.company_name', company_name from original.transacts
        where company_name not in (select cname from original.contracting_company)
      union all select 'is_active.insurance_id', insurance_id from original.is_active
        where insurance_id not in (select iid from original.insurance)
      union all select 'customer.htitle', htitle from original.customer
        where htitle not in (select title_dead from original.house)
      order by 1, 2`);
    assert.deepEqual(
      orphans.map((o) => `${o.ref}=${o.value}`),
      [
        'calls_for_emergency.cnum=202260',
        'customer.htitle=3925632',
        'is_active.insurance_id=11', // the INSURANCE row for 11 was the one that failed to parse
        'is_active.insurance_id=26',
        'is_active.insurance_id=75',
        'transacts.company_name=HHL',
      ],
    );
  });

  test('whole tables whose keys match nothing they reference', async () => {
    const unmatched = async (table, column, target, key) =>
      count(`select count(*) from original.${table} where ${column} not in (select ${key} from original.${target})`);
    const total = (table) => count(`select count(*) from original.${table}`);

    assert.equal(await unmatched('house_location', 'title_dead', 'house', 'title_dead'), await total('house_location'));
    assert.equal(await unmatched('has2', 'title_dead', 'house', 'title_dead'), await total('has2'));
    assert.equal(await unmatched('has3', 'vsn', 'vehicle', 'sn'), await total('has3'));
    assert.equal(await unmatched('covers2', 'title_dead', 'house', 'title_dead'), await total('covers2'));
    assert.equal(
      await unmatched('ccompanies_phone_number', 'company_name', 'contracting_company', 'cname'),
      await total('ccompanies_phone_number'),
    );
  });

  test('relationships stored twice disagree with each other', async () => {
    // CUSTOMER.VSN and HAS3 both record who owns which vehicle.
    assert.equal(
      await count(`select count(*) from original.has3 as h join original.customer as c using (customer_id)
                   where c.vsn is distinct from h.vsn`),
      await count('select count(*) from original.has3'),
    );
    // VEHICLE.IID and COVERS3 both record which policy covers a vehicle.
    assert.deepEqual(
      await q(`select v.sn, v.iid as vehicle_says, c.iid as covers3_says
               from original.vehicle as v join original.covers3 as c on c.vsn = v.sn
               where c.iid <> v.iid`),
      [{ sn: '400000', vehicle_says: '665', covers3_says: '26' }],
    );
  });

  test('stored department counts do not add up', async () => {
    const stored = await count('select sum(number_of_employees::int) from original.department');
    const employees = await count('select count(*) from original.employee');
    assert.equal(stored, 39);
    assert.equal(employees, 31);
  });
});
