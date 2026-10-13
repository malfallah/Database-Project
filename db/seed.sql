-- Seed data for the Safe Hands database.
--
-- Source: the INSERT listing (report section X) cross-checked against the
-- screenshots of the live Oracle tables (pp. 77-99). Where the two disagree
-- the screenshot wins, because it shows what was actually in the database.
-- Every correction is listed in docs/errata.md under "Data".
--
-- All people and companies are fictional coursework data. Email domains were
-- replaced with example.com (RFC 2606) so no real mailbox is published.
--
-- Run once on an empty, migrated database. It is one transaction because
-- department.manager_id and employee.dept_no reference each other.

begin;

insert into department (dept_no, name, manager_id, manager_start_date) values
(1, 'HR', 202104, '2014-06-06'),
(502, 'IT', 202155, '2014-09-11'),
(584, 'Health', 202177, '2015-02-17'),
(510, 'Finance', 202133, '2014-07-13'),
(588, 'Marketing', 202199, '2016-03-18'),
(513, 'Electronic Trading', 202164, '2014-10-19'),
(577, 'Claims', 202108, '2017-05-07'),
(555, 'Underwriting', 202100, '2015-09-16'),
(544, 'Maintenance', 202109, '2017-11-11'),
(521, 'Executive', 202122, '2018-12-13');

-- dept_no comes from the EMPLOYEE screenshot (p. 77-78); the report's DDL and
-- INSERTs omitted the column entirely.
insert into employee (
    employee_id, first_name, middle_name, last_name, salary, birth_date, gender, supervisor_id, role, dept_no
) values
(202104, 'Omar', 'Wissam', 'Temsah', 9999, '2004-03-18', 'Male', null, 'CEO', 1),
(202164, 'Ahmad', 'Nader', 'Mourad', 8675, '2002-10-17', 'Male', 202104, 'Manager', 513),
(202133, 'Mohammad', 'Ghazi', 'Alizzi', 7500, '2003-10-15', 'Male', 202104, 'Manager', 510),
(202155, 'Mohammad', 'Amin', 'Alfallah', 7500, '2003-03-25', 'Male', 202104, 'Manager', 502),
(202108, 'Ola', 'Mohammad', 'Makki', 6777, '2000-03-30', 'Female', 202104, 'Manager', 577),
(202177, 'Bilal', 'Mohammad', 'Delbani', 8000, '2003-05-08', 'Male', 202104, 'Manager', 584),
(202199, 'Jessica', 'William', 'Henwick', 7500, '2002-06-18', 'Female', 202104, 'Manager', 588),
(202100, 'Nazek', 'Ayman', 'Bohsali', 8000, '1990-12-03', 'Female', 202104, 'Manager', 555),
(202109, 'Maria', 'Tawfiq', 'Alloush', 7666, '2000-09-30', 'Female', 202104, 'Manager', 544),
(202122, 'Hadi', 'Firas', 'Sharafeddin', 7865, '2002-02-15', 'Male', 202104, 'Manager', 521),
(202126, 'Douaa', 'Houssam', 'Shamly', 7000, '2003-08-04', 'Female', 202199, 'Trainer', 584),
(202147, 'Mohammad', 'Wissam', 'Temsah', 8000, '1992-07-13', 'Male', 202100, 'Security', 510),
(202192, 'Karen', 'Habib', 'Khalife', 6000, '2003-04-24', 'Female', 202199, 'Secretary', 502),
(202166, 'Zeinab', 'Nader', 'Olaywan', 7500, '2003-11-29', 'Female', 202199, 'Trainer', 588),
(202182, 'Ahmad', 'Wissam', 'Temsah', 7500, '1996-10-31', 'Male', 202133, 'Security', 584),
(202103, 'Lynn', 'Ibrahim', 'Chakaron', 7000, '2003-09-26', 'Female', 202100, 'Advisor', 555),
(202115, 'Makhoul', 'Ahmad', 'Shbeib', 8700.5, '2003-10-11', 'Male', 202109, 'Trainer', 544),
(202110, 'Batoul', 'Hussein', 'Saayed', 8000, '2003-05-12', 'Female', 202177, 'Secretary', 510),
(202198, 'Mohammad', 'Mostafa', 'Ballouz', 9200, '2003-06-16', 'Male', 202133, 'Advisor', 502),
(202154, 'Nathalie', 'Karim', 'Delbani', 7000, '2003-04-17', 'Female', 202100, 'Trainer', 555),
(202178, 'Ali', 'Mourad', 'Khalil', 8766, '2001-10-26', 'Male', 202109, 'Secretary', 544),
(202123, 'Farah', 'Jawad', 'Farhat', 6789, '1999-11-29', 'Female', 202164, 'Trainer', 513),
(202124, 'Leen', 'Kamal', 'Almasri', 8888, '2001-06-27', 'Female', 202133, 'Advisor', 510),
(202106, 'Najib', 'Fariss', 'Bannout', 6000, '1997-12-22', 'Male', 202199, 'Advisor', 588),
(202148, 'Omar', 'Ali', 'Karaki', 6742, '1998-09-11', 'Male', 202177, 'Security', 584),
(202151, 'Shikri', 'Faisal', 'Bakri', 5500, '2003-11-19', 'Male', 202122, 'Secretary', 521),
(202159, 'Lamiss', 'Fadi', 'Ghandour', 6300, '1993-01-01', 'Female', 202122, 'Trainer', 521),
(202191, 'Houssam', 'Walid', 'Kahled', 6458, '2003-10-09', 'Male', 202164, 'Advisor', 513),
(202193, 'Asmaa', 'Khalil', 'Ballouz', 7800, '1994-12-12', 'Female', 202108, 'Trainer', 577),
(202187, 'Ali', 'Fouad', 'Solaiman', 8300, '2003-08-27', 'Male', 202100, 'Security', 555),
(202183, 'Elias', 'Charbel', 'Shehab', 6900, '2004-01-28', 'Male', 202133, 'Advisor', 510);

insert into department_location (dept_no, location) values
(1, 'Beirut'),
(502, 'Kaslik'),
(584, 'Saida'),
(510, 'Saida'),
(588, 'Beirut'),
(513, 'Tripoli'),
(577, 'Beirut'),
(555, 'Sour'),
(544, 'Kaslik'),
(521, 'Jounieh');

insert into dependent (employee_id, name, gender, birth_date, relationship) values
(202100, 'Mahdi', 'Male', '2003-05-08', 'Son'),
(202109, 'Ali', 'Male', '2000-07-10', 'Husband'),
(202122, 'Fatima', 'Female', '2003-02-15', 'Wife'),
(202126, 'Husam', 'Male', '2015-08-12', 'Son'),
(202147, 'Hiba', 'Female', '2010-04-02', 'Daughter'),
(202182, 'Samira', 'Female', '1998-09-25', 'Wife'),
(202166, 'Jamel', 'Male', '1999-07-19', 'Husband'),
(202115, 'Rayan', 'Female', '2005-12-14', 'Sister'),
(202110, 'Wisam', 'Male', '2000-07-12', 'Brother'),
(202148, 'Huda', 'Female', '1980-03-29', 'Mother');

-- The original listing gave the "Baalbek" address, the second "811..." phone
-- and the "Elias.charbel" email to 202182; they belong to 202183 (Elias
-- Charbel Shehab), who otherwise had no contact details at all.
insert into employee_address (employee_id, city, street, apartment_no) values
(202104, 'Beirut', 'Abdulghani', 31),
(202164, 'Arabssalim', null, 3),
(202133, 'Nabatieh', 'Nabatieh Fawqa', 53),
(202155, 'Dahye', 'Autostrad Sayd', 44),
(202108, 'Batroun', 'Mahroun', 10),
(202177, 'Sour', 'Sour', 130),
(202199, 'Kaslik', 'AlRoum', 320),
(202100, 'Alay', null, 300),
(202109, 'Hasbayya', 'Ain Jafra', 2),
(202122, 'Qureitem', 'Marie-Curie', 12),
(202126, 'Aramoun', 'AlRammal', 111),
(202147, 'Beirut', 'AlHamra', null),
(202192, 'Beirut', 'Zoqaq AlBlat', 68),
(202166, 'Bchamoun', 'Bchamoun', 210),
(202182, 'Beirut', 'Fayza AlSolh', 10),
(202103, 'Nabatieh', null, 690),
(202115, 'Zahlah', null, null),
(202110, 'Yahmor', null, null),
(202198, 'Mazboud', null, null),
(202148, 'Saida', 'Hariri Street', null),
(202154, 'Rashaya', null, 5),
(202178, 'Bint Jbeil', null, 1),
(202123, 'Haris', 'Haris', null),
(202124, 'Tayr Harfa', null, 2),
(202106, 'Hasbayya', null, null),
(202151, 'Aamrani', 'Aazieh', 4),
(202159, 'Houmin', 'Houmin alfawqa', null),
(202191, 'Chtoura', 'Jdita', 7),
(202193, 'Tal Alkhayat', null, 1),
(202187, 'Anssar', 'Anssar', 11),
(202183, 'Baalbek', 'Brital', null);

insert into employee_phone (employee_id, phone) values
(202104, '71214707'),
(202104, '71136925'),
(202164, '03111111'),
(202133, '03111112'),
(202155, '03111113'),
(202108, '03111110'),
(202177, '03111102'),
(202199, '03121117'),
(202100, '71111111'),
(202109, '71111112'),
(202122, '71111113'),
(202126, '71111101'),
(202147, '71111102'),
(202192, '71111103'),
(202166, '70111111'),
(202182, '70111112'),
(202103, '70111113'),
(202115, '70111101'),
(202110, '70111102'),
(202198, '70111103'),
(202148, '76111111'),
(202154, '76111112'),
(202178, '76111113'),
(202123, '76111101'),
(202124, '76111102'),
(202106, '76111103'),
(202151, '81111111'),
(202159, '81111112'),
(202191, '81111113'),
(202193, '81111101'),
(202187, '81111102'),
(202183, '81111103');

insert into employee_email (employee_id, email) values
(202104, 'omartemsah2004@example.com'),
(202104, 'Omar.Temsah@example.com'),
(202164, 'Ahmad.Mourad@example.com'),
(202133, 'Mohammad.Alizzi@example.com'),
(202155, 'Mohammad.AlFallah@example.com'),
(202108, 'OlaMakki@example.com'),
(202177, 'Bilal.Delbani@example.com'),
(202199, 'Jessica.Henwick@example.com'),
(202100, 'Nazek.Bohsali@example.com'),
(202109, 'MariaAlloush2000@example.com'),
(202122, 'Hadi.Sharafeddin01@example.com'),
(202126, 'Douaa.shamly@example.com'),
(202147, 'Mohammad.Temsah@example.com'),
(202192, 'KarenH.Khalife@example.com'),
(202166, 'Zeinab.olaywan@example.com'),
(202182, 'Ahmad.temsah@example.com'),
(202103, 'LynnChakaron@example.com'),
(202115, 'Makhoul.Shbeib@example.com'),
(202110, 'Batoul.Saayed@example.com'),
(202198, 'Mohammad.Ballouz@example.com'),
(202148, 'Omar.karaki@example.com'),
(202154, 'Nathalie.delbani@example.com'),
(202178, 'Ali.khalil2001@example.com'),
(202123, 'Farah.Farhat@example.com'),
(202124, 'Leen.almasri@example.com'),
(202106, 'najib.bannout@example.com'),
(202151, 'Shikri.aamrani@example.com'),
(202159, 'lamissGhandour90@example.com'),
(202191, 'Houssam.khaled@example.com'),
(202193, 'Asmaa.Hnaini@example.com'),
(202187, 'ali.mezher@example.com'),
(202183, 'Elias.charbel@example.com');

insert into customer (customer_id, first_name, middle_name, last_name, satisfaction, gender) values
(202200, 'John', 'Cristopher', 'Wong', 8, 'Male'),
(202204, 'Ghina', 'Youssef', 'Wehbe', 7, 'Female'),
(202213, 'Kareem', 'Ibrahim', 'Boulez', 9, 'Male'),
(202244, 'Sara', 'Rodwan', 'Roumani', 7, 'Female'),
(202251, 'Ali', 'Mohammad', 'Zhour', 10, 'Male'),
(202289, 'Hassan', 'Ali', 'Malaeb', 4, 'Male'),
(202266, 'Zeina', 'Moahmmad', 'Al zahabi', 6, 'Female'),
(202271, 'Layla', 'Wissam', 'Issa', 7, 'Female'),
(202255, 'Reem', 'Jad', 'Daher', 5, 'Female'),
(202205, 'Jad', 'Wael', 'Lawlab', 10, 'Male'),
(202299, 'Wael', 'Emil', 'Kfoury', 9, 'Male'),
(202219, 'Myriam', 'Salem', 'Klink', 10, 'Female');

insert into customer_address (customer_id, district, city, street, apartment_no) values
(202200, 'Almaten', 'Aley', 'Bsous', 8),
(202204, 'Nabatieh', 'Habboush', 'Hay-Almaslakh', 10),
(202213, 'Beirut', 'Mazraa', 'Tadros', 7),
(202213, 'Jnoub', 'Blat', null, null),
(202244, 'Nabatieh', 'Deir-Alzahrani', 'Deir-Alzahrani', 10),
(202251, 'Beirut', 'Msaytbeh', 'Maalouf', 8),
(202289, 'Beirut', 'Badaro', 'Bardawil', 9),
(202266, 'Jnoub', 'Saida', 'Saida', 10),
(202271, 'Chmel', 'Tripoli', 'Riad Elsolh', 6),
(202255, 'Chmel', 'Anjar', 'Majdel-Aanjar', 9),
(202205, 'Chmel', 'Akkar', 'Halba', 10),
(202299, 'Beirut', 'Ashrafieh', 'Sassine', 11),
(202299, 'Chmel', 'Batroun', null, 26),
(202219, 'Mountain', 'Kaslik', 'AlRoum', 13);

insert into customer_phone (customer_id, phone) values
(202200, '71520901'),
(202204, '81720444'),
(202213, '03890112'),
(202213, '71567890'),
(202244, '76113478'),
(202251, '81333786'),
(202289, '70981379'),
(202266, '70325689'),
(202271, '03619625'),
(202255, '76477889'),
(202205, '78144589'),
(202299, '71230988'),
(202299, '81999401'),
(202219, '03659872'),
(202219, '78330912');

insert into customer_email (customer_id, email) values
(202200, 'John.Wong@example.com'),
(202204, 'Ghina.Wehbe@example.com'),
(202213, 'Kareem.Boulez@example.com'),
(202213, 'kareem2000@example.com'),
(202244, 'Sara.roumani@example.com'),
(202251, 'ali.zhour@example.com'),
(202289, 'Hassan.Malaeb@example.com'),
(202289, 'HassounMalaeb@example.com'),
(202266, 'ZeinaAlzahabi@example.com'),
(202271, 'LaylaIssa@example.com'),
(202255, 'Reem.daher03@example.com'),
(202205, 'JadLawlab@example.com'),
(202299, 'WaelKfoury@example.com'),
(202299, 'Wael.Kfoury2000@example.com'),
(202219, 'MyriamKlink@example.com');

insert into serves (customer_id, employee_id) values
(202200, 202126),
(202200, 202147),
(202204, 202166),
(202204, 202103),
(202213, 202115),
(202213, 202110),
(202244, 202198),
(202251, 202154),
(202289, 202178),
(202266, 202123),
(202271, 202124),
(202255, 202106),
(202205, 202151),
(202299, 202159),
(202219, 202191),
(202219, 202193),
(202299, 202182),
(202205, 202182),
(202255, 202159),
(202271, 202193);

insert into deals_with (dept_no, customer_id, start_date, end_date) values
(1, 202200, '2022-06-01', '2025-06-01'),
(502, 202204, '2021-03-17', '2027-03-17'),
(584, 202213, '2020-05-08', '2022-05-08'),
(510, 202244, '2021-03-16', '2024-09-10'),
(588, 202251, '2019-10-17', '2022-12-31'),
(513, 202289, '2015-02-26', '2020-07-13'),
(577, 202266, '2017-04-20', '2023-01-02'),
(555, 202271, '2019-08-31', '2027-11-07'),
(544, 202255, '2021-05-09', '2024-05-09'),
(521, 202205, '2017-06-22', '2025-06-22');

-- The listing had customer 202260, which does not exist; every other row
-- pairs a department with the customer it deals with, and DEALS_WITH pairs
-- department 577 with 202266.
insert into calls_for_emergency (dept_no, customer_id, emergency_phone_no) values
(1, 202200, '111'),
(502, 202204, '112'),
(584, 202213, '113'),
(510, 202244, '114'),
(588, 202251, '115'),
(513, 202289, '112'),
(577, 202266, '116'),
(555, 202271, '117'),
(544, 202255, '118'),
(521, 202205, '112');

insert into medical_record (
    customer_id, record_no, blood_type, weight_kg, height_cm, age_years, disease, allergy
) values
(202204, 2, 'AB+', 66.9, 148.3, 25, null, 'Rashes'),
(202213, 3, 'B+', 88.2, 156.1, 29, 'Covid-19', 'Cough'),
(202244, 4, 'O+', 56.8, 169.3, 21, 'Cancer', null),
(202251, 5, 'O+', 76.5, 177.2, 30, 'Covid-19', 'Cough'),
(202289, 6, 'A-', 52.1, 156.5, 33, 'Diabetes', null),
(202266, 7, 'O-', 88.8, 177.7, 37, null, 'Throat Closing'),
(202271, 8, 'O+', 55.7, 176.1, 30, 'Covid-19', 'Cough'),
(202255, 9, 'A+', 66.6, 170.9, 26, 'heart diseases', 'Chest tightness'),
(202205, 10, 'O+', 70.0, 178.6, 45, null, null),
(202299, 11, 'B-', 81.1, 156.5, 38, 'Cancer', null),
(202219, 12, 'AB-', 51.6, 155.3, 23, 'High Blood Pressure', null);

-- The INSERTs passed (id, type, coverage) into a (id, coverage, type) table;
-- the screenshot (p. 79) shows the intended values.
insert into insurance (insurance_id, insurance_type, coverage_pct) values
(39, 'Other', 40),
(12, 'Mandatory', 30),
(876, 'Against others', 50),
(345, 'Mandatory', 90),
(23, 'Other', 100),
(53, 'Against others', 45),
(11, 'Mandatory', 75),
(665, 'Mandatory', 65),
(5, 'Against others', 54),
(6, 'Mandatory', 76);

-- Owners come from CUSTOMER.VSN in the original. Vehicles 400004 and 600006
-- had no owner, which the ER diagram forbids (total participation), so they
-- were assigned to customers without a vehicle.
insert into vehicle (
    serial_no, plate_letter, registration_no, model_year, make, model, market_value,
    owner_id, insurance_id, coverage_pct
) values
(100000, 'B', 1234, 2011, 'BMW', 'X6', 4500, 202200, 39, 40),
(200000, 'N', 2345, 2020, 'Audi', 'A3', 19200, 202213, 876, 50),
(300000, 'N', 3456, 2019, 'Hyundai', 'Accent', 13400, 202251, 11, 75),
(400000, 'S', 3456, 2010, 'Nissan', 'Versa', 6500, 202266, 665, 76),
(100001, 'O', 2356, 2010, 'Chevrolet', 'Corvette', 10000, 202255, 53, 45),
(200002, 'B', 2468, 2011, 'Toyota', 'Prius', 8911, 202205, 23, 100),
(300003, 'T', 2033, 2014, 'Volkswagen', 'GTI', 9999, 202299, 665, 65),
(400004, 'J', 1788, 2011, 'Kia', 'Sorento', 5000, 202204, 23, 100),
(500005, 'N', 3395, 2016, 'Toyota', 'Camry', 10200, 202219, 53, 45),
(600006, 'O', 2070, 2020, 'Mercedes', 'A-Class', 33795, 202271, 11, 75);

insert into vehicle_color (serial_no, color) values
(100000, 'White'),
(100000, 'Black'),
(200000, 'White'),
(300000, 'Blue'),
(400000, 'Red'),
(400000, 'Black'),
(100001, 'Red'),
(200002, 'Yellow'),
(300003, 'Blue'),
(400004, 'Red'),
(500005, 'White'),
(500005, 'Grey'),
(600006, 'Grey');

-- House 3925632 is missing from the INSERT listing but present in the HOUSE
-- screenshot (p. 80). Locations come from the HOUSE_LOCATION screenshot
-- (p. 94); the listing truncated the title deeds ('392', '840', ...).
-- Owners come from CUSTOMER.HTitle; the four houses without one were
-- assigned (total participation, as for vehicles).
insert into house (
    title_deed, area_m2, year_built, market_value,
    collectibles_value, collectibles_type, collectibles_material, collectibles_quantity,
    district, city, street, apartment_no, owner_id, insurance_id, coverage_pct
) values
('3925632', 200, 2012, 80000, 5693, 'Jewelry', 'Gold', 6, 'Beirut', 'Beirut', null, 31, 202200, 39, 90),
(
    '8408742', 700, 2024, 20000, 10547, 'Furniture', 'Furniture', 20,
    'Bekaa', 'Bednayel', 'Jabbeneh', 158, 202244, 39, 50
),
('4287653', 300, 2000, 15500, 9000, 'Antiquities', 'Bronze', 4, 'Shmel', 'Arnaoun', null, 330, 202266, 23, 60),
('9075567', 200, 2001, 60300, 500, 'Glass', 'Glass', 5, 'Jnoub', 'Sour', 'Abo Dib', 71, 202255, 23, 35),
(
    '8298672', 175, 2015, 59900, null, null, null, null,
    'Mount Lebanon', 'Beirut', 'Amrousieh', 67, 202299, 53, 87
),
('3212436', 300, 2017, 100300, null, null, null, null, 'Beirut', 'Beirut', 'Bliss', 210, 202213, 11, 90),
('8486765', 500, 2009, 13000, 2100, 'Jewelry', 'Silver', 5, 'Saida', 'Saida', 'Mina', 400, 202289, 876, 74),
('1167466', 800, 1990, 500000, 30000, 'Jewelry', 'Diamond', 3, 'Jnoub', 'Arab Salim', null, 28, 202251, 5, 97),
('4478863', 200, 2004, 9000, 5725, 'Furniture', 'Furniture', 30, 'Shmel', 'Tripoli', 'Abyad', 17, 202204, 6, 89),
(
    '3463636', 600, 2000, 20000, 13000, 'Antiquities', 'Silver', 7,
    'Shmel', 'Byblos', 'Karam Alaris', 1, 202219, 665, 85
);

-- The INSERTs put the dates into (Exit_Date, Enter_Date) in that order, so
-- every patient left hospital before arriving. Swapped back here.
insert into health_report (
    report_no, customer_id, hospital_name, admitted_on, discharged_on, checkup_done, insurance_id, coverage_pct
) values
(53, 202200, 'AUB', '2000-03-25', '2003-03-29', true, 39, 70),
(24, 202204, 'Bahman', '2000-05-05', '2000-06-29', true, 876, 30),
(56, 202213, 'LAUMC', '2001-05-25', '2002-07-21', true, 345, 40),
(123, 202244, 'Najjar', '2010-06-25', '2010-08-11', false, 23, 55),
(77, 202266, 'AUB', '2005-06-22', '2006-03-02', false, 11, 100),
(345, 202251, 'Rassul', '2004-09-25', '2007-06-09', true, 12, 100),
(39, 202289, 'Jabal Amel', '2007-08-25', '2008-02-01', true, 53, 65),
(32, 202271, 'Saint George', '2019-12-26', '2020-01-19', false, 12, 54),
(35, 202255, 'Hiram', '2020-03-25', '2021-03-29', false, 11, 88),
(377, 202205, 'Zahraa', '2003-04-25', '2003-05-12', true, 665, 95);

-- The INSERTs were positional and swapped ReceiptNo and Paid: every child
-- table (HAS1, IS_ACTIVE, PAYMENT_CURRENCY, PAYMENT_DATE) references the
-- first value, and with the swap undone paid <= bill holds for every row.
insert into payment (receipt_no, customer_id, payment_type, mechanism, bill, paid) values
(22, 202200, 'INSTALLMENT', 'CREDIT CARD', 800, 343),
(54, 202204, 'INSTALLMENT', 'BANK', 38.5, 20),
(97, 202213, 'LUMP SUM', 'CASH', 285, 100),
(12, 202244, 'INSTALLMENT', 'CASH', 200, 130),
(2, 202251, 'LUMP SUM', 'CASH', 1244.7, 1),
(8, 202289, 'INSTALLMENT', 'BOND', 67, 50),
(52, 202266, 'INSTALLMENT', 'CREDIT CARD', 180, 80),
(92, 202271, 'INSTALLMENT', 'CREDIT CARD', 493, 93),
(32, 202255, 'LUMP SUM', 'BANK', 99.3, 2),
(73, 202205, 'INSTALLMENT', 'BOND', 2345, 1000),
(45, 202299, 'LUMP SUM', 'CASH', 738, 3),
(26, 202219, 'INSTALLMENT', 'CREDIT CARD', 700.34, 439);

insert into payment_currency (receipt_no, currency) values
(22, 'Lira'),
(54, 'Dollar'),
(97, 'Lira'),
(12, 'Euro'),
(2, 'Dollar'),
(8, 'Lira'),
(52, 'Dirham'),
(92, 'Lira'),
(32, 'Dollar'),
(73, 'Euro'),
(45, 'Lira'),
(26, 'Dollar');

insert into payment_date (receipt_no, paid_on) values
(22, '2010-04-25'),
(54, '2011-08-11'),
(97, '2004-01-23'),
(12, '2002-02-12'),
(2, '2005-03-27'),
(8, '2015-09-30'),
(52, '2017-11-01'),
(92, '2018-12-02'),
(32, '2020-06-04'),
(73, '2022-03-15'),
(45, '2021-07-17'),
(26, '2010-09-20');

-- Two IS_ACTIVE rows referenced insurance 75 and 26, which do not exist;
-- they are left out (see errata).
insert into payment_policy (receipt_no, insurance_id, is_active) values
(22, 39, true),
(54, 12, true),
(97, 876, false),
(12, 345, true),
(2, 23, false),
(8, 53, false),
(52, 11, true),
(92, 665, false);

insert into expense (receipt_no, item, item_type, price, spent_on) values
(101102, 'Computers', 'Equipment', 100000, '2018-10-11'),
(101103, 'White Boards', 'Equipment', 50000, '2017-03-19'),
(101104, 'Name Badges', 'Equipment', 5000, '2015-04-03'),
(100121, 'Rent', 'Land', 20000, '2020-11-29'),
(102111, 'Salaries', 'Salary', 100000, '2021-01-15'),
(301001, 'Electronics', 'Industrial', 50000, '2021-06-27'),
(211310, 'Trucks', 'Industrial', 150000, '2017-12-01'),
(113650, 'Raw Materials', 'Equipment', 25000, '2019-11-13'),
(810720, 'Electricity Bills', 'Land', 50000, '2021-02-28'),
(300010, 'Water Supply', 'Land', 15000, '2021-01-21');

insert into pays (dept_no, expense_receipt_no) values
(1, 102111),
(1, 101102),
(502, 101104),
(584, 301001),
(584, 113650),
(510, 810720),
(588, 300010),
(513, 100121),
(577, 113650),
(555, 810720),
(544, 301001),
(521, 101104),
(502, 100121),
(510, 301001),
(588, 101104),
(1, 211310);

insert into contracted_company (name, service) values
('Safe Ride', 'Vehicles'),
('MOBM', 'Vehicles'),
('State Farm', 'Vehicles'),
('Happy House', 'Houses'),
('Aviva', 'Houses'),
('Homeprotect', 'Houses'),
('Anthem', 'Health'),
('Cigna', 'Health'),
('HHI', 'Health'),
('Geico', 'Vehicles');

insert into contracted_company_location (company_name, location) values
('Safe Ride', 'Beirut'),
('MOBM', 'Saida'),
('State Farm', 'Zahlah'),
('Happy House', 'Beirut'),
('Aviva', 'Tripoli'),
('Homeprotect', 'Sour'),
('Anthem', 'Batroun'),
('Cigna', 'Beirut'),
('HHI', 'Jounieh'),
('Geico', 'Jall Eldib');

-- From the screenshot (p. 93). The INSERT listing for this table was a
-- copy of CUSTOMER_PHONE, with customer ids in the company-name column.
insert into contracted_company_phone (company_name, phone) values
('Anthem', '01826002'),
('Aviva', '01789123'),
('Cigna', '01320021'),
('Geico', '01833996'),
('HHI', '01123321'),
('Happy House', '01810003'),
('Homeprotect', '01980111'),
('MOBM', '01800001'),
('Safe Ride', '01800000'),
('State Farm', '01800002');

insert into contracted_company_email (company_name, email) values
('Safe Ride', 'saferideoffice@example.com'),
('MOBM', 'mobm.official@example.com'),
('State Farm', 'State.Farm@example.com'),
('Happy House', 'HappyHouse.management@example.com'),
('Aviva', 'avivaofficial@example.com'),
('Homeprotect', 'Homeprotect.oce@example.com'),
('Anthem', 'anthemoffice@example.com'),
('Cigna', 'Cigna.office@example.com'),
('HHI', 'hhi.management@example.com'),
('Geico', 'geico@example.com');

-- 'HHL' in the listing is a typo for the company 'HHI'.
insert into transacts (dept_no, company_name, period_years) values
(1, 'Safe Ride', 2),
(502, 'MOBM', 1),
(584, 'State Farm', 5),
(510, 'Happy House', 5),
(588, 'Aviva', 4),
(513, 'Homeprotect', 7),
(577, 'Anthem', 3),
(555, 'Cigna', 2),
(544, 'HHI', 6),
(521, 'Geico', 4);

commit;
