-- Transcribed from docs/original/safe-hands-report-2022.pdf (section XI, pp. 100-115).
-- Kept verbatim (including its errors) for reference. Line breaks the PDF
-- introduced inside statements were re-joined; nothing else was changed.
-- See docs/errata.md for what is wrong with it and how it was fixed.

-- QUERY 1: Rami is in search of an old house
SELECT C.Fname, C.Mname, C.Lname, CPN.CPhone
FROM CUSTOMER C,
CUSTOMER_PHONE CPN,
HOUSE_LOCATION HL,
HOUSE H
WHERE C.HTitle = H.Title_dead
AND H.Year_built<=2005
AND HL.Title_dead = H.Title_dead
AND HL.HCity = 'SOUR'
AND CPN.Customer_ID = C.Customer_ID;

-- QUERY 2: Explosion in ‘Health’ department
UPDATE EMPLOYEE
SET Salary = 1.05*Salary
WHERE Dno IN (SELECT DEPARTMENT.DNumber
FROM DEPARTMENT
WHERE DEPARTMENT.DName = 'Health');
AND
UPDATE EMPLOYEE
SET Dno = 1
WHERE Dno IN (SELECT DEPARTMENT.DNumber
FROM DEPARTMENT
WHERE DEPARTMENT.DName = 'Health');

-- QUERY 3: Punishment!!
UPDATE EMPLOYEE
SET Salary = 0.87*Salary
WHERE Employee_ID IN (SELECT S.EID
FROM SERVES S, CUSTOMER C
WHERE C.Fname = 'Wael'
AND C.Mname = 'Emil'
AND C.Lname = 'Kfoury'
AND C.Customer_ID = S.CUSTID);

-- QUERY 4: Robbery in the Finance department
(
SELECT E.Employee_ID
FROM EMPLOYEE E,
DEPARTMENT D
WHERE E.Dno = D.DNumber
AND D.DName = ‘Finance’
AND E.Role = ‘Trainer’
AND E.Gender = ‘Male’
)
UNION
(
SELECT E.Employee_ID
FROM EMPLOYEE E,
DEPARTMENT D
WHERE E.Dno = D.Number
AND D.Name = ‘Finance’
AND E.Role = ‘Secretary’
AND E.Gender = ‘Male’
)
UNION
(
SELECT E.Employee_ID
FROM EMPLOYEE E,
DEPARTMENT D
WHERE E.Dno = D.Number
AND D.Name = ‘Finance’
AND E.Role = ‘Security’
AND E.Gender = ‘Male’
)
UNION
(
SELECT E.Employee_IDs
FROM EMPLOYEE E,
DEPARTMENT D
WHERE E.Dno = D.Number
AND D.Name = ‘Finance’
AND E.Role = ‘Advisor’
AND E.Gender = ‘Male’ );

-- QUERY 5: Tragedy is Happening, and we are here to help!!
UPDATE EMPLOYEE
SET Salary = Salary*1.2
WHERE EXISTS (SELECT *
FROM DEPENDENT DEP, EMPLOYEE E
WHERE E.Employee_ID = DEP.EID)
AND Salary < (SELECT AVG(Salary)
FROM Employee);

-- QUERY 6: All Customers should be satisfied
SELECT DISTINCT C.Fname, C.Lname, CP.CPhone, CL.CCity, CL.CDistrict, CL.CStreet,
CL.CApartment_number
FROM CUSTOMER C, CUSTOMER_PHONE CP, CUSTOMER_LOCATION CL, INSURANCE
WHERE Satisfaction<6
AND C.CUSTOMER_ID= CL.CUSTOMER_ID
AND C.CUSTOMER_ID= CP.CUSTOMER_ID
AND NOT EXISTS ( SELECT *
FROM INSURANCE, CUSTOMER
WHERE Customer_ID = IID);

-- QUERY 7: Mother’s Day!
SELECT DISTINCT E.Fname, E.Lname,EP.EPhone
FROM EMPLOYEE E, EMPLOYEE_PHONE EP
WHERE E.Gender='Female'
AND E.Employee_ID= EP.Employee_ID
AND EXISTS ( SELECT *
FROM DEPENDENT D, EMPLOYEE EM
WHERE EM.Employee_ID = D.EID
AND (D.Relationship='Son'
OR D.Relationship='Daughter'))
UNION
(SELECT DISTINCT C.Fname, C.Lname, CP.CPhone
FROM CUSTOMER C, CUSTOMER_PHONE CP
WHERE Gender='Female'
AND C.CUSTOMER_ID= CP.CUSTOMER_ID);

-- QUERY 8: New fatal Disease!!
SELECT DISTINCT C.Fname, C.Lname, CE.CEMail
FROM CUSTOMER C, CUSTOMER_EMAIL CE, HEALTH H, MEDICAL_RECORD M
WHERE C.Customer_ID =M.CID
AND C.Customer_ID=H.CID
AND C.CUSTOMER_ID = CE.CUSTOMER_ID
AND H.Percentage < ( SELECT AVG(Percentage)
FROM HEALTH)
AND M.Age<50;

-- QUERY 9: Happy Anniversary!!
SELECT A.Fname, A.Lname, E.EEMail
FROM EMPLOYEE A, EMPLOYEE_EMAIL E, DEPARTMENT D
WHERE A.Employee_ID =E.Employee_ID
AND D.DNumber= A.DNo
AND D.DName= 'Executive'
UNION
(
SELECT Em.Fname, Em.Lname, E.EEMail
FROM EMPLOYEE Em, EMPLOYEE_EMAIL E
WHERE Em.Employee_ID =E.Employee_ID
AND (Em.Role= 'Manager' OR Em.Role= ‘CEO’)
);

-- QUERY 10: New Policy!!
DELETE FROM EMPLOYEE
WHERE (UPDATE DEPARTMENT
SET Number_of_employees = Number_of_employees – (SELECT COUNT(*)
FROM EMPLOYEE
WHERE BDate< '01-01-1962')
WHERE DName=’Maintenance’)
AND BDate< '01-01-1962';
