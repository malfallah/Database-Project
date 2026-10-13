-- migrate:up

-- Descriptions for every table, view and column. They show up in psql (\d+)
-- and are the source for docs/schema.md (npm run docs). "Original:" names the
-- table or column in the 2022 Oracle design.

comment on table department is
'A company department (DEPARTMENT, with MANAGES). Original: DEPARTMENT.';
comment on column department.dept_no is 'Department number. Original: DNumber.';
comment on column department.name is 'Department name, unique. Original: DName.';
comment on column department.manager_id is
'Employee who manages the department (MANAGES, 1:1). Deferred FK. Original: EID.';
comment on column department.manager_start_date is
'When the current manager took over. Original: Manager_Start_Date.';

comment on table employee is 'A company employee (EMPLOYEE, with SUPERVISES and WORKS_FOR). Original: EMPLOYEE.';
comment on column employee.employee_id is 'Employee number. Original: Employee_ID.';
comment on column employee.first_name is 'First name. Original: Fname.';
comment on column employee.middle_name is 'Middle name. Original: Mname.';
comment on column employee.last_name is 'Last name. Original: Lname.';
comment on column employee.salary is 'Monthly salary; must exceed 5000. Original: Salary.';
comment on column employee.birth_date is 'Date of birth; age is derived in employee_profile. Original: BDate.';
comment on column employee.gender is 'Male or Female. Original: Gender.';
comment on column employee.role is 'Job title within the department (WORKS_FOR.Role). Original: Role.';
comment on column employee.supervisor_id is 'Supervising employee (SUPERVISES, 1:N). Original: Super_ID.';
comment on column employee.dept_no is
'Department the employee works for (WORKS_FOR, N:1). Original: DNo (missing from the report''s DDL).';

comment on table department_location is
'Locations of a department (multivalued attribute). Original: DEPARTMENT_LOCATION.';
comment on column department_location.dept_no is 'Department. Original: DNumber.';
comment on column department_location.location is 'City or branch. Original: DLocation.';

comment on table dependent is
'Family member of an employee (weak entity, DEPENDENTS_OF). Original: DEPENDENT.';
comment on column dependent.employee_id is 'Employee the dependent belongs to. Original: EID.';
comment on column dependent.name is 'First name; partial key. Original: Name.';
comment on column dependent.gender is 'Male or Female. Original: Gender.';
comment on column dependent.birth_date is 'Date of birth. Original: BDate.';
comment on column dependent.relationship is 'Relationship to the employee. Original: Relationship.';

comment on table employee_address is
'Addresses of an employee (multivalued composite attribute). Original: EMPLOYEE_LOCATION.';
comment on column employee_address.address_id is 'Surrogate key. New.';
comment on column employee_address.employee_id is 'Employee. Original: Employee_ID.';
comment on column employee_address.city is 'City or town. Original: ECity.';
comment on column employee_address.street is 'Street. Original: EStreet.';
comment on column employee_address.apartment_no is 'Apartment number. Original: EApartment_number.';

comment on table employee_phone is 'Phone numbers of an employee (multivalued attribute). Original: EMPLOYEE_PHONE.';
comment on column employee_phone.employee_id is 'Employee. Original: Employee_ID.';
comment on column employee_phone.phone is '8-digit Lebanese phone number. Original: EPhone.';

comment on table employee_email is
'Email addresses of an employee (multivalued attribute). Original: EMPLOYEE_EMAIL.';
comment on column employee_email.employee_id is 'Employee. Original: Employee_ID.';
comment on column employee_email.email is 'Email address. Original: EEmail.';

comment on table customer is 'An insurance customer. Original: CUSTOMER.';
comment on column customer.customer_id is 'Customer number. Original: Customer_ID.';
comment on column customer.first_name is 'First name. Original: Fname.';
comment on column customer.middle_name is 'Middle name. Original: Mname.';
comment on column customer.last_name is 'Last name. Original: Lname.';
comment on column customer.satisfaction is 'Satisfaction score from 0 to 10. Original: Satisfaction.';
comment on column customer.gender is 'Male or Female. Original: Gender.';

comment on table customer_address is
'Addresses of a customer (multivalued composite attribute). Original: CUSTOMER_LOCATION.';
comment on column customer_address.address_id is 'Surrogate key. New.';
comment on column customer_address.customer_id is 'Customer. Original: Customer_ID.';
comment on column customer_address.district is 'District. Original: CDistrict.';
comment on column customer_address.city is 'City or town. Original: CCity.';
comment on column customer_address.street is 'Street. Original: CStreet.';
comment on column customer_address.apartment_no is 'Apartment number. Original: CApartment_number.';

comment on table customer_phone is 'Phone numbers of a customer (multivalued attribute). Original: CUSTOMER_PHONE.';
comment on column customer_phone.customer_id is 'Customer. Original: Customer_ID.';
comment on column customer_phone.phone is '8-digit Lebanese phone number. Original: CPhone.';

comment on table customer_email is
'Email addresses of a customer (multivalued attribute). Original: CUSTOMER_EMAIL.';
comment on column customer_email.customer_id is 'Customer. Original: Customer_ID.';
comment on column customer_email.email is 'Email address. Original: CEmail.';

comment on table serves is 'Which employees serve which customers (SERVES, M:N). Original: SERVES.';
comment on column serves.customer_id is 'Customer. Original: CustID.';
comment on column serves.employee_id is 'Employee. Original: EID.';

comment on table deals_with is
'Departments a customer deals with, and for how long (DEALS_WITH). Original: DEALS_WITH.';
comment on column deals_with.dept_no is 'Department. Original: DNo.';
comment on column deals_with.customer_id is 'Customer. Original: Customer_Number.';
comment on column deals_with.start_date is 'Start of the service period. Original: Start_Date.';
comment on column deals_with.end_date is 'End of the service period. Original: End_Date.';

comment on table calls_for_emergency is
'Emergency hotlines between customers and departments (CALLS_FOR_EMERGENCY, M:N). Original: CALLS_FOR_EMERGENCY.';
comment on column calls_for_emergency.dept_no is 'Department. Original: DNum.';
comment on column calls_for_emergency.customer_id is 'Customer. Original: CNum.';
comment on column calls_for_emergency.emergency_phone_no is '3-digit emergency number. Original: EmergencyPhoneNo#.';

comment on table medical_record is
'Medical record of a customer (weak entity, PROVIDES, 1:1). Original: MEDICAL_RECORD.';
comment on column medical_record.customer_id is 'Customer the record belongs to. Original: CID.';
comment on column medical_record.record_no is 'Record number; partial key. Original: RecordNo.';
comment on column medical_record.blood_type is 'ABO/Rh blood type. Original: Blood_Type.';
comment on column medical_record.weight_kg is 'Weight in kilograms. Original: Weight.';
comment on column medical_record.height_cm is 'Height in centimetres. Original: Height.';
comment on column medical_record.age_years is 'Age when the record was taken. Original: Age.';
comment on column medical_record.disease is 'Known disease, if any. Original: Disease.';
comment on column medical_record.allergy is 'Known allergy or symptom, if any. Original: Allergy.';

comment on table insurance is 'An insurance policy type. Original: INSURANCE.';
comment on column insurance.insurance_id is 'Policy number. Original: IID.';
comment on column insurance.insurance_type is 'Mandatory, Against others, or Other. Original: Type_of_Insurance.';
comment on column insurance.coverage_pct is 'Default coverage, 30-100%. Original: Coverage.';

comment on table vehicle is 'An insured vehicle (with HAS and COVERS). Original: VEHICLE.';
comment on column vehicle.serial_no is 'Serial number. Original: SN.';
comment on column vehicle.plate_letter is 'Letter on the Lebanese plate. Original: State.';
comment on column vehicle.registration_no is 'Plate number; unique together with the letter. Original: Reg#.';
comment on column vehicle.model_year is 'Year of manufacture. Original: Year.';
comment on column vehicle.make is 'Manufacturer. Original: Make.';
comment on column vehicle.model is 'Model. Original: Model.';
comment on column vehicle.market_value is 'Market value. Original: Value.';
comment on column vehicle.owner_id is 'Owning customer (HAS, 1:N). Original: CUSTOMER.VSN and HAS3.';
comment on column vehicle.insurance_id is 'Covering policy (COVERS, 1:N). Original: IID and COVERS3.';
comment on column vehicle.coverage_pct is 'Coverage for this vehicle, 30-100%. Original: Percentage.';

comment on table vehicle_color is 'Colours of a vehicle (multivalued attribute). Original: VEHICLE_COLOR.';
comment on column vehicle_color.serial_no is 'Vehicle. Original: SN.';
comment on column vehicle_color.color is 'Colour. Original: VCOLOR.';

comment on table house is 'An insured house (with HAS and COVERS). Original: HOUSE and HOUSE_LOCATION.';
comment on column house.title_deed is 'Title deed number. Original: Title_dead.';
comment on column house.area_m2 is 'Floor area in square metres. Original: Area.';
comment on column house.year_built is 'Year built. Original: Year_built.';
comment on column house.market_value is 'Market value; must exceed 5000. Original: Value.';
comment on column house.collectibles_value is 'Value of insured collectibles. Original: VCollectibles.';
comment on column house.collectibles_type is 'Kind of collectibles. Original: TCollectibles.';
comment on column house.collectibles_material is 'Material of the collectibles. Original: MCollectibles.';
comment on column house.collectibles_quantity is 'Number of collectible items. Original: QCollectibles.';
comment on column house.district is 'District. Original: HOUSE_LOCATION.HDistrict.';
comment on column house.city is 'City or town. Original: HOUSE_LOCATION.HCity.';
comment on column house.street is 'Street. Original: HOUSE_LOCATION.HStreet.';
comment on column house.apartment_no is 'Apartment number. Original: HOUSE_LOCATION.HApartment_Number.';
comment on column house.owner_id is 'Owning customer (HAS, 1:N). Original: CUSTOMER.HTitle and HAS2.';
comment on column house.insurance_id is 'Covering policy (COVERS, 1:N). Original: IID and COVERS2.';
comment on column house.coverage_pct is 'Coverage for this house, 30-100%. Original: Percentage.';

comment on table health_report is
'A hospital stay of a customer (CHECKS 1:1, COVERS). Original: HEALTH.';
comment on column health_report.report_no is 'Report number. Original: ReportNo.';
comment on column health_report.customer_id is 'Patient (CHECKS, 1:1). Original: CID.';
comment on column health_report.hospital_name is 'Hospital. Original: Hospital_Name.';
comment on column health_report.admitted_on is 'Admission date. Original: Enter_Date.';
comment on column health_report.discharged_on is 'Discharge date. Original: Exit_Date.';
comment on column health_report.checkup_done is 'Whether a health check was done. Original: HBoolean.';
comment on column health_report.insurance_id is 'Covering policy (COVERS, 1:N). Original: IID and COVERS1.';
comment on column health_report.coverage_pct is 'Coverage for this stay, 30-100%. Original: Percentage.';

comment on table payment is 'A customer payment (with HAS). Original: PAYMENT.';
comment on column payment.receipt_no is 'Receipt number. Original: ReceiptNo.';
comment on column payment.customer_id is 'Paying customer (HAS, 1:N). Original: CID and HAS1.';
comment on column payment.payment_type is 'INSTALLMENT or LUMP SUM. Original: Type.';
comment on column payment.mechanism is 'Cash, bank transfer, credit card or bond. Original: Mechanism.';
comment on column payment.bill is 'Total amount owed. Original: Bill.';
comment on column payment.paid is 'Amount paid so far; at most the bill. Original: Paid.';
comment on column payment.amount_due is 'bill - paid, generated. Original: derived attribute Left.';

comment on table payment_currency is
'Currencies a payment was made in (multivalued attribute). Original: PAYMENT_CURRENCY.';
comment on column payment_currency.receipt_no is 'Payment. Original: ReceiptNo.';
comment on column payment_currency.currency is 'Dollar, Euro, Lira or Dirham. Original: Currency.';

comment on table payment_date is 'Dates on which a payment was made (multivalued attribute). Original: PAYMENT_DATE.';
comment on column payment_date.receipt_no is 'Payment. Original: ReceiptNo.';
comment on column payment_date.paid_on is 'Payment date. Original: PDate.';

comment on table payment_policy is
'Policies a payment is for, and whether each is active (IS_ACTIVE, M:N). Original: IS_ACTIVE.';
comment on column payment_policy.receipt_no is 'Payment. Original: PNum.';
comment on column payment_policy.insurance_id is 'Policy. Original: Insurance_ID.';
comment on column payment_policy.is_active is 'Whether the policy is still active. Original: IBoolean.';

comment on table expense is 'Something the company paid for. Original: EXPENSE.';
comment on column expense.receipt_no is 'Receipt number. Original: RNumber.';
comment on column expense.item is 'What was bought. Original: Item.';
comment on column expense.item_type is 'Expense category. Original: Type_of_Item.';
comment on column expense.price is 'Amount paid. Original: Price.';
comment on column expense.spent_on is 'Date of the expense. Original: Date.';

comment on table pays is 'Which departments paid which expenses (PAYS, M:N). Original: PAYS.';
comment on column pays.dept_no is 'Department. Original: DNum.';
comment on column pays.expense_receipt_no is 'Expense. Original: ERNum.';

comment on table contracted_company is
'A partner company that provides insured services. Original: CONTRACTING_COMPANY.';
comment on column contracted_company.name is 'Company name. Original: CName.';
comment on column contracted_company.service is 'Vehicles, Houses or Health. Original: Service.';

comment on table contracted_company_location is
'Branches of a partner company (multivalued attribute). Original: CCOMPANIES_LOCATION.';
comment on column contracted_company_location.company_name is 'Company. Original: Company_name.';
comment on column contracted_company_location.location is 'City or branch. Original: CCLocation.';

comment on table contracted_company_phone is
'Phone numbers of a partner company (multivalued attribute). Original: CCOMPANIES_PHONE_NUMBER.';
comment on column contracted_company_phone.company_name is 'Company. Original: Company_name.';
comment on column contracted_company_phone.phone is '8-digit Lebanese phone number. Original: CCPhone_Number.';

comment on table contracted_company_email is
'Email addresses of a partner company (multivalued attribute). Original: CCOMPANIES_EMAIL.';
comment on column contracted_company_email.company_name is 'Company. Original: Company_name.';
comment on column contracted_company_email.email is 'Email address. Original: CCEmail.';

comment on table transacts is
'Contracts between departments and partner companies (TRANSACTS, M:N). Original: TRANSACTS.';
comment on column transacts.dept_no is 'Department. Original: DNo.';
comment on column transacts.company_name is 'Company. Original: Company_Name.';
comment on column transacts.period_years is 'Contract length in years. Original: Period_of_transaction.';

comment on view employee_profile is 'Employees with their derived age and department name. New.';
comment on view department_summary is
'Departments with derived employee and customer counts (replaces the stored Number_of_employees/customers).';

-- migrate:down

do $$
declare
    rel record;
    col record;
begin
    for rel in
        select c.oid, c.relname, c.relkind
        from pg_class as c
        inner join pg_namespace as n on c.relnamespace = n.oid
        where n.nspname = 'public' and c.relkind in ('r', 'v') and c.relname <> 'schema_migrations'
    loop
        execute format(
            'comment on %s %I is null', case rel.relkind when 'v' then 'view' else 'table' end, rel.relname
        );
        for col in
            select a.attname from pg_attribute as a
            where a.attrelid = rel.oid and a.attnum > 0 and not a.attisdropped
        loop
            execute format('comment on column %I.%I is null', rel.relname, col.attname);
        end loop;
    end loop;
end
$$;
