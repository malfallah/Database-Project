-- migrate:up

-- Safe Hands insurance database, PostgreSQL port of the 2022 Oracle design.
-- Every entity and relationship from the original ER diagram is kept; see
-- docs/schema.md for the table-by-table mapping and docs/errata.md for what
-- changed and why.
--
-- Conventions
--   * snake_case, singular table names; original names are noted per table.
--   * Money is numeric(12, 2), never float.
--   * Each 1:N relationship is stored once, as a foreign key on the N side.
--   * Multivalued attributes live in child tables that cascade on delete.
--   * Every foreign key column has an index (checked by tests/schema.test.js).

-- ---------------------------------------------------------------------------
-- Organisation
-- ---------------------------------------------------------------------------

-- DEPARTMENT (+ MANAGES). Employee and customer counts were stored columns in
-- the original and drifted from reality; they are computed by the
-- department_summary view instead.
create table department (
    dept_no integer primary key check (dept_no > 0),
    name varchar(30) not null unique,
    manager_id integer not null,
    manager_start_date date not null
);

-- EMPLOYEE (+ SUPERVISES, WORKS_FOR). Age is derived (employee_profile view).
create table employee (
    employee_id integer primary key check (employee_id > 9999),
    first_name varchar(15) not null,
    middle_name varchar(15) not null,
    last_name varchar(15) not null,
    salary numeric(12, 2) not null default 6000 check (salary > 5000),
    birth_date date,
    gender varchar(6) check (gender in ('Male', 'Female')),
    role varchar(15) not null
    check (role in ('CEO', 'Manager', 'Advisor', 'Secretary', 'Security', 'Trainer')),
    supervisor_id integer references employee (employee_id) on delete set null,
    dept_no integer not null references department (dept_no),
    constraint employee_not_own_supervisor check (supervisor_id <> employee_id)
);

create index employee_supervisor_id_idx on employee (supervisor_id);
create index employee_dept_no_idx on employee (dept_no);

-- Departments and employees reference each other, and both sides are total
-- participation (NOT NULL). The manager FK is deferred so a department and
-- its manager can be inserted in the same transaction. An employee manages
-- at most one department (MANAGES is 1:1), hence the unique constraint.
alter table department
add constraint department_manager_id_fkey
foreign key (manager_id) references employee (employee_id)
deferrable initially deferred,
add constraint department_manager_id_key unique (manager_id);

create table department_location (
    dept_no integer not null references department (dept_no) on delete cascade,
    location varchar(20) not null,
    primary key (dept_no, location)
);

-- DEPENDENT: weak entity owned by EMPLOYEE (DEPENDENTS_OF).
create table dependent (
    employee_id integer not null references employee (employee_id) on delete cascade,
    name varchar(15) not null,
    gender varchar(6) check (gender in ('Male', 'Female')),
    birth_date date,
    relationship varchar(10) not null
    check (relationship in ('Son', 'Daughter', 'Husband', 'Wife', 'Mother', 'Father', 'Brother', 'Sister')),
    primary key (employee_id, name)
);

-- EMPLOYEE_LOCATION. The original made employee_id the whole primary key,
-- which allowed only one address per employee and contradicted the ER
-- diagram's multivalued Location attribute.
create table employee_address (
    address_id integer generated always as identity primary key,
    employee_id integer not null references employee (employee_id) on delete cascade,
    city varchar(20) not null,
    street varchar(20),
    apartment_no integer check (apartment_no > 0),
    constraint employee_address_unique unique nulls not distinct (employee_id, city, street, apartment_no)
);

create table employee_phone (
    employee_id integer not null references employee (employee_id) on delete cascade,
    phone char(8) not null check (phone ~ '^[0-9]{8}$'),
    primary key (employee_id, phone)
);

create table employee_email (
    employee_id integer not null references employee (employee_id) on delete cascade,
    email varchar(50) not null check (email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
    primary key (employee_id, email)
);

-- ---------------------------------------------------------------------------
-- Customers
-- ---------------------------------------------------------------------------

create table customer (
    customer_id integer primary key check (customer_id > 9999),
    first_name varchar(15) not null,
    middle_name varchar(15) not null,
    last_name varchar(15) not null,
    satisfaction smallint check (satisfaction between 0 and 10),
    gender varchar(6) not null check (gender in ('Male', 'Female'))
);

-- CUSTOMER_LOCATION (same primary-key fix as employee_address).
create table customer_address (
    address_id integer generated always as identity primary key,
    customer_id integer not null references customer (customer_id) on delete cascade,
    district varchar(20) not null,
    city varchar(20) not null,
    street varchar(20),
    apartment_no integer check (apartment_no > 0),
    constraint customer_address_unique
    unique nulls not distinct (customer_id, district, city, street, apartment_no)
);

create table customer_phone (
    customer_id integer not null references customer (customer_id) on delete cascade,
    phone char(8) not null check (phone ~ '^[0-9]{8}$'),
    primary key (customer_id, phone)
);

create table customer_email (
    customer_id integer not null references customer (customer_id) on delete cascade,
    email varchar(50) not null check (email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
    primary key (customer_id, email)
);

-- SERVES (M:N employee-customer).
create table serves (
    customer_id integer not null references customer (customer_id) on delete cascade,
    employee_id integer not null references employee (employee_id) on delete cascade,
    primary key (customer_id, employee_id)
);

create index serves_employee_id_idx on serves (employee_id);

-- DEALS_WITH (customer-department, with service period).
create table deals_with (
    dept_no integer not null references department (dept_no) on delete cascade,
    customer_id integer not null references customer (customer_id) on delete cascade,
    start_date date not null,
    end_date date not null,
    primary key (dept_no, customer_id),
    constraint deals_with_period_check check (end_date >= start_date)
);

create index deals_with_customer_id_idx on deals_with (customer_id);

-- CALLS_FOR_EMERGENCY (M:N customer-department, with hotline number).
create table calls_for_emergency (
    dept_no integer not null references department (dept_no) on delete cascade,
    customer_id integer not null references customer (customer_id) on delete cascade,
    emergency_phone_no char(3) not null check (emergency_phone_no ~ '^[0-9]{3}$'),
    primary key (dept_no, customer_id)
);

create index calls_for_emergency_customer_id_idx on calls_for_emergency (customer_id);

-- MEDICAL_RECORD: weak entity owned by CUSTOMER (PROVIDES, 1:1).
-- The original also stored Sex, a copy of customer.gender that could
-- disagree with it; it was dropped. age_years is the age when the record was
-- taken (the original design has no customer birth date to derive it from).
create table medical_record (
    customer_id integer not null references customer (customer_id) on delete cascade,
    record_no integer not null check (record_no > 0),
    blood_type varchar(3) not null default 'O+'
    check (blood_type in ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    weight_kg numeric(5, 1) not null check (weight_kg >= 3),
    height_cm numeric(5, 1) not null check (height_cm >= 40),
    age_years smallint not null check (age_years between 1 and 130),
    disease varchar(20),
    allergy varchar(20),
    primary key (customer_id, record_no),
    constraint medical_record_one_per_customer unique (customer_id)
);

-- ---------------------------------------------------------------------------
-- Insurance and insured assets
-- ---------------------------------------------------------------------------

create table insurance (
    insurance_id integer primary key check (insurance_id > 0),
    insurance_type varchar(20) not null check (insurance_type in ('Mandatory', 'Against others', 'Other')),
    coverage_pct smallint not null default 30 check (coverage_pct between 30 and 100)
);

-- VEHICLE (+ HAS customer-vehicle, + COVERS insurance-vehicle).
-- "State" in the report is the letter on a Lebanese plate; together with the
-- registration number it identifies the plate, so the pair is unique.
create table vehicle (
    serial_no integer primary key check (serial_no > 99999),
    plate_letter char(1) check (plate_letter ~ '^[A-Z]$'),
    registration_no integer check (registration_no > 0),
    model_year smallint not null check (model_year >= 1886),
    make varchar(15) not null,
    model varchar(15) not null,
    market_value numeric(12, 2) not null check (market_value > 0),
    owner_id integer not null references customer (customer_id),
    insurance_id integer references insurance (insurance_id),
    coverage_pct smallint check (coverage_pct between 30 and 100),
    constraint vehicle_plate_key unique (plate_letter, registration_no),
    constraint vehicle_coverage_check check ((insurance_id is null) = (coverage_pct is null))
);

create index vehicle_owner_id_idx on vehicle (owner_id);
create index vehicle_insurance_id_idx on vehicle (insurance_id);

create table vehicle_color (
    serial_no integer not null references vehicle (serial_no) on delete cascade,
    color varchar(10) not null,
    primary key (serial_no, color)
);

-- HOUSE (+ HAS customer-house, + COVERS insurance-house). HOUSE_LOCATION was
-- keyed by the title deed alone, i.e. single-valued, so it is folded in here.
create table house (
    title_deed varchar(100) primary key,
    area_m2 numeric(8, 2) not null check (area_m2 > 0),
    year_built smallint not null,
    market_value numeric(12, 2) not null check (market_value > 5000),
    collectibles_value numeric(12, 2) check (collectibles_value >= 0),
    collectibles_type varchar(30),
    collectibles_material varchar(30),
    collectibles_quantity integer check (collectibles_quantity > 0),
    district varchar(20) not null,
    city varchar(20) not null,
    street varchar(20),
    apartment_no integer check (apartment_no > 0),
    owner_id integer not null references customer (customer_id),
    insurance_id integer references insurance (insurance_id),
    coverage_pct smallint check (coverage_pct between 30 and 100),
    constraint house_coverage_check check ((insurance_id is null) = (coverage_pct is null))
);

create index house_owner_id_idx on house (owner_id);
create index house_insurance_id_idx on house (insurance_id);

-- HEALTH (+ CHECKS customer-health 1:1, + COVERS insurance-health).
create table health_report (
    report_no integer primary key check (report_no > 0),
    customer_id integer not null unique references customer (customer_id),
    hospital_name varchar(30) not null,
    admitted_on date not null,
    discharged_on date not null,
    checkup_done boolean not null default false,
    insurance_id integer not null references insurance (insurance_id),
    coverage_pct smallint not null check (coverage_pct between 30 and 100),
    constraint health_report_stay_check check (discharged_on >= admitted_on)
);

create index health_report_insurance_id_idx on health_report (insurance_id);

-- ---------------------------------------------------------------------------
-- Money in and out
-- ---------------------------------------------------------------------------

-- PAYMENT (+ HAS customer-payment). "Left" was a derived attribute in the ER
-- diagram; it is a generated column here so it can never be stale.
create table payment (
    receipt_no integer primary key check (receipt_no > 0),
    customer_id integer not null references customer (customer_id),
    payment_type varchar(15) not null check (payment_type in ('INSTALLMENT', 'LUMP SUM')),
    mechanism varchar(20) not null check (mechanism in ('CASH', 'BANK', 'CREDIT CARD', 'BOND')),
    bill numeric(12, 2) not null check (bill > 0),
    paid numeric(12, 2) not null default 0 check (paid >= 0),
    amount_due numeric(12, 2) generated always as (bill - paid) stored,
    constraint payment_not_overpaid check (paid <= bill)
);

create index payment_customer_id_idx on payment (customer_id);

create table payment_currency (
    receipt_no integer not null references payment (receipt_no) on delete cascade,
    currency varchar(10) not null check (currency in ('Dollar', 'Euro', 'Lira', 'Dirham')),
    primary key (receipt_no, currency)
);

create table payment_date (
    receipt_no integer not null references payment (receipt_no) on delete cascade,
    paid_on date not null,
    primary key (receipt_no, paid_on)
);

-- IS_ACTIVE (M:N insurance-payment, with an active flag).
create table payment_policy (
    receipt_no integer not null references payment (receipt_no) on delete cascade,
    insurance_id integer not null references insurance (insurance_id),
    is_active boolean not null,
    primary key (receipt_no, insurance_id)
);

create index payment_policy_insurance_id_idx on payment_policy (insurance_id);

create table expense (
    receipt_no integer primary key check (receipt_no > 0),
    item varchar(30) not null,
    item_type varchar(30) not null,
    price numeric(12, 2) not null check (price > 0),
    spent_on date not null
);

-- PAYS (M:N department-expense).
create table pays (
    dept_no integer not null references department (dept_no) on delete cascade,
    expense_receipt_no integer not null references expense (receipt_no) on delete cascade,
    primary key (dept_no, expense_receipt_no)
);

create index pays_expense_receipt_no_idx on pays (expense_receipt_no);

-- ---------------------------------------------------------------------------
-- Partner companies
-- ---------------------------------------------------------------------------

create table contracted_company (
    name varchar(30) primary key,
    service varchar(20) not null check (service in ('Vehicles', 'Houses', 'Health'))
);

create table contracted_company_location (
    company_name varchar(30) not null
    references contracted_company (name) on update cascade on delete cascade,
    location varchar(20) not null,
    primary key (company_name, location)
);

create table contracted_company_phone (
    company_name varchar(30) not null
    references contracted_company (name) on update cascade on delete cascade,
    phone char(8) not null check (phone ~ '^[0-9]{8}$'),
    primary key (company_name, phone)
);

create table contracted_company_email (
    company_name varchar(30) not null
    references contracted_company (name) on update cascade on delete cascade,
    email varchar(50) not null check (email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
    primary key (company_name, email)
);

-- TRANSACTS (M:N department-company, with contract length in years).
create table transacts (
    dept_no integer not null references department (dept_no) on delete cascade,
    company_name varchar(30) not null
    references contracted_company (name) on update cascade on delete cascade,
    period_years smallint not null default 1 check (period_years >= 1),
    primary key (dept_no, company_name)
);

create index transacts_company_name_idx on transacts (company_name);

-- migrate:down

drop table transacts;
drop table contracted_company_email;
drop table contracted_company_phone;
drop table contracted_company_location;
drop table contracted_company;
drop table pays;
drop table expense;
drop table payment_policy;
drop table payment_date;
drop table payment_currency;
drop table payment;
drop table health_report;
drop table house;
drop table vehicle_color;
drop table vehicle;
drop table insurance;
drop table medical_record;
drop table calls_for_emergency;
drop table deals_with;
drop table serves;
drop table customer_email;
drop table customer_phone;
drop table customer_address;
drop table customer;
drop table employee_email;
drop table employee_phone;
drop table employee_address;
drop table dependent;
drop table department_location;
alter table department drop constraint department_manager_id_fkey;
drop table employee;
drop table department;
