-- ============================================================
-- HEALTHCARE SQL ANALYTICS PROJECT
-- Dataset: Patient, Doctor, Appointment, Medical Procedure, Billing
-- Dialect: MySQL 8+

--
-- Relationships:
-- Patient 1 ----< Appointment >---- 1 Doctor
-- Appointment 1 ----< MedicalProcedure
-- Patient 1 ----< Billing
--
-- Note: The supplied Appointment file contains Date and Time as separate
-- columns. Date is treated as DATE and Time as DATETIME in this project.

CREATE DATABASE IF NOT EXISTS healthcare_sql_project;
USE healthcare_sql_project;

DROP TABLE IF EXISTS medical_procedure;
DROP TABLE IF EXISTS billing;
DROP TABLE IF EXISTS appointment;
DROP TABLE IF EXISTS doctor;
DROP TABLE IF EXISTS patient;

CREATE TABLE patient (
    PatientID INT PRIMARY KEY,
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    Email VARCHAR(255)
);

CREATE TABLE doctor (
    DoctorID INT PRIMARY KEY,
    DoctorName VARCHAR(150),
    Specialization VARCHAR(150),
    DoctorContact VARCHAR(255)
);

CREATE TABLE appointment (
    AppointmentID INT PRIMARY KEY,
    Date DATE,
    Time DATETIME,
    PatientID INT,
    DoctorID INT,
    CONSTRAINT fk_appointment_patient
        FOREIGN KEY (PatientID) REFERENCES patient(PatientID),
    CONSTRAINT fk_appointment_doctor
        FOREIGN KEY (DoctorID) REFERENCES doctor(DoctorID)
);

CREATE TABLE medical_procedure (
    ProcedureID INT PRIMARY KEY,
    ProcedureName VARCHAR(255),
    AppointmentID INT,
    CONSTRAINT fk_procedure_appointment
        FOREIGN KEY (AppointmentID) REFERENCES appointment(AppointmentID)
);

CREATE TABLE billing (
    InvoiceID CHAR(36) PRIMARY KEY,
    PatientID INT,
    Items VARCHAR(255),
    Amount DECIMAL(15,2),
    CONSTRAINT fk_billing_patient
        FOREIGN KEY (PatientID) REFERENCES patient(PatientID)
);


-- ============================================================
-- LEVEL 1 — SQL FUNDAMENTALS
-- ============================================================

-- Q1. Display all patients.
SELECT * FROM patient;

-- Q2. Display only patient ID, first name, last name and email.
SELECT PatientID, FirstName, LastName, Email
FROM patient;

-- Q3. Find patients whose first name starts with 'A'.
SELECT *
FROM patient
WHERE FirstName LIKE 'A%';

-- Q4. Find all doctors specializing in Oncology.
SELECT *
FROM doctor
WHERE Specialization = 'Oncologist';

-- Q5. Show appointments scheduled after 2023-01-01.
SELECT *
FROM appointment
WHERE Date > '2023-01-01'
ORDER BY Date;

-- Q6. Show the 10 most expensive bills.
SELECT *
FROM billing
ORDER BY Amount DESC
LIMIT 10;

-- Q7. Find the minimum, maximum and average billing amount.
SELECT
    MIN(Amount) AS MinBill,
    MAX(Amount) AS MaxBill,
    ROUND(AVG(Amount), 2) AS AvgBill
FROM billing;

-- Q8. Count the total number of patients, doctors and appointments.
SELECT
    (SELECT COUNT(*) FROM patient) AS TotalPatients,
    (SELECT COUNT(*) FROM doctor) AS TotalDoctors,
    (SELECT COUNT(*) FROM appointment) AS TotalAppointments;

-- Q9. Find bills greater than 500000.
SELECT *
FROM billing
WHERE Amount > 500000
ORDER BY Amount DESC;

-- Q10. Display unique medical procedures.
SELECT DISTINCT ProcedureName
FROM medical_procedure
ORDER BY ProcedureName;

-- ============================================================
-- LEVEL 2 — JOINS AND GROUP BY
-- ============================================================

-- Q11. Show each appointment with patient name and doctor name.
SELECT
    a.AppointmentID,
    a.Date,
    a.Time,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    d.DoctorName,
    d.Specialization
FROM appointment a
JOIN patient p ON a.PatientID = p.PatientID
JOIN doctor d ON a.DoctorID = d.DoctorID
ORDER BY a.Date, a.Time;

-- Q12. Show each medical procedure with appointment and patient.
SELECT
    mp.ProcedureID,
    mp.ProcedureName,
    mp.AppointmentID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName
FROM medical_procedure mp
JOIN appointment a ON mp.AppointmentID = a.AppointmentID
JOIN patient p ON a.PatientID = p.PatientID;

-- Q13. Count appointments handled by each doctor.
SELECT
    d.DoctorID,
    d.DoctorName,
    COUNT(a.AppointmentID) AS AppointmentCount
FROM doctor d
LEFT JOIN appointment a ON d.DoctorID = a.DoctorID
GROUP BY d.DoctorID, d.DoctorName
ORDER BY AppointmentCount DESC;

-- Q14. Find doctors with more than 5 appointments.
SELECT
    d.DoctorID,
    d.DoctorName,
    COUNT(a.AppointmentID) AS AppointmentCount
FROM doctor d
JOIN appointment a ON d.DoctorID = a.DoctorID
GROUP BY d.DoctorID, d.DoctorName
HAVING COUNT(a.AppointmentID) > 5
ORDER BY AppointmentCount DESC;

-- Q15. Count patients by doctor specialization.
SELECT
    d.Specialization,
    COUNT(DISTINCT a.PatientID) AS UniquePatients
FROM doctor d
JOIN appointment a ON d.DoctorID = a.DoctorID
GROUP BY d.Specialization
ORDER BY UniquePatients DESC;

-- Q16. Calculate total billing amount per patient.
SELECT
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    COALESCE(SUM(b.Amount), 0) AS TotalBilling
FROM patient p
LEFT JOIN billing b ON p.PatientID = b.PatientID
GROUP BY p.PatientID, p.FirstName, p.LastName
ORDER BY TotalBilling DESC;

-- Q17. Find the top 10 patients by total billing.
SELECT
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    SUM(b.Amount) AS TotalBilling
FROM patient p
JOIN billing b ON p.PatientID = b.PatientID
GROUP BY p.PatientID, p.FirstName, p.LastName
ORDER BY TotalBilling DESC
LIMIT 10;

-- Q18. Find the average bill for each billing item.
SELECT
    Items,
    COUNT(*) AS InvoiceCount,
    ROUND(AVG(Amount), 2) AS AverageAmount
FROM billing
GROUP BY Items
ORDER BY AverageAmount DESC;

-- Q19. Find the most expensive billing item/category.
SELECT
    Items,
    SUM(Amount) AS TotalRevenue
FROM billing
GROUP BY Items
ORDER BY TotalRevenue DESC
LIMIT 1;

-- Q20. Count how many procedures are associated with each procedure name.
SELECT
    ProcedureName,
    COUNT(*) AS ProcedureCount
FROM medical_procedure
GROUP BY ProcedureName
ORDER BY ProcedureCount DESC;

-- ============================================================
-- LEVEL 3 — INTERMEDIATE ANALYTICS
-- ============================================================

-- Q21. Find patients who have appointments but no billing record.
SELECT DISTINCT
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName
FROM patient p
JOIN appointment a ON p.PatientID = a.PatientID
LEFT JOIN billing b ON p.PatientID = b.PatientID
WHERE b.PatientID IS NULL;

-- Q22. Find patients who have billing records but no appointments.
SELECT DISTINCT
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName
FROM patient p
JOIN billing b ON p.PatientID = b.PatientID
LEFT JOIN appointment a ON p.PatientID = a.PatientID
WHERE a.PatientID IS NULL;

-- Q23. Find doctors who have no appointments.
SELECT
    d.DoctorID,
    d.DoctorName,
    d.Specialization
FROM doctor d
LEFT JOIN appointment a ON d.DoctorID = a.DoctorID
WHERE a.AppointmentID IS NULL;

-- Q24. Find patients with more than one appointment.
SELECT
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    COUNT(a.AppointmentID) AS AppointmentCount
FROM patient p
JOIN appointment a ON p.PatientID = a.PatientID
GROUP BY p.PatientID, p.FirstName, p.LastName
HAVING COUNT(a.AppointmentID) > 1
ORDER BY AppointmentCount DESC;

-- Q25. Find the number of appointments per month.
SELECT
    YEAR(Date) AS AppointmentYear,
    MONTH(Date) AS AppointmentMonth,
    COUNT(*) AS AppointmentCount
FROM appointment
GROUP BY YEAR(Date), MONTH(Date)
ORDER BY AppointmentYear, AppointmentMonth;

-- Q26. Find the number of appointments per year.
SELECT
    YEAR(Date) AS AppointmentYear,
    COUNT(*) AS AppointmentCount
FROM appointment
GROUP BY YEAR(Date)
ORDER BY AppointmentYear;

-- Q27. Find the busiest appointment date.
SELECT
    Date,
    COUNT(*) AS AppointmentCount
FROM appointment
GROUP BY Date
ORDER BY AppointmentCount DESC
LIMIT 1;

-- Q28. Rank doctors by number of appointments.
SELECT
    DoctorID,
    DoctorName,
    AppointmentCount,
    DENSE_RANK() OVER (ORDER BY AppointmentCount DESC) AS DoctorRank
FROM (
    SELECT
        d.DoctorID,
        d.DoctorName,
        COUNT(a.AppointmentID) AS AppointmentCount
    FROM doctor d
    LEFT JOIN appointment a ON d.DoctorID = a.DoctorID
    GROUP BY d.DoctorID, d.DoctorName
) x
ORDER BY DoctorRank, DoctorName;

-- Q29. Rank patients by total billing amount.
SELECT
    PatientID,
    PatientName,
    TotalBilling,
    DENSE_RANK() OVER (ORDER BY TotalBilling DESC) AS BillingRank
FROM (
    SELECT
        p.PatientID,
        CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
        SUM(b.Amount) AS TotalBilling
    FROM patient p
    JOIN billing b ON p.PatientID = b.PatientID
    GROUP BY p.PatientID, p.FirstName, p.LastName
) x
ORDER BY BillingRank, PatientName;

-- Q30. Calculate each patient's percentage of total billing.
SELECT
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    SUM(b.Amount) AS PatientBilling,
    ROUND(
        100 * SUM(b.Amount) / (SELECT SUM(Amount) FROM billing),
        2
    ) AS BillingPercentage
FROM patient p
JOIN billing b ON p.PatientID = b.PatientID
GROUP BY p.PatientID, p.FirstName, p.LastName
ORDER BY BillingPercentage DESC;

-- ============================================================
-- LEVEL 4 — ADVANCED SQL / BUSINESS QUESTIONS
-- ============================================================

-- Q31. Find the highest-billing patient using a CTE.
WITH patient_billing AS (
    SELECT
        PatientID,
        SUM(Amount) AS TotalBilling
    FROM billing
    GROUP BY PatientID
)
SELECT
    pb.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    pb.TotalBilling
FROM patient_billing pb
JOIN patient p ON pb.PatientID = p.PatientID
ORDER BY pb.TotalBilling DESC
LIMIT 1;

-- Q32. Find the second-highest total billing patient.
WITH patient_billing AS (
    SELECT
        PatientID,
        SUM(Amount) AS TotalBilling
    FROM billing
    GROUP BY PatientID
),
ranked AS (
    SELECT
        PatientID,
        TotalBilling,
        DENSE_RANK() OVER (ORDER BY TotalBilling DESC) AS rnk
    FROM patient_billing
)
SELECT
    r.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    r.TotalBilling
FROM ranked r
JOIN patient p ON r.PatientID = p.PatientID
WHERE r.rnk = 2;

-- Q33. Find the average number of appointments per doctor.
SELECT ROUND(AVG(AppointmentCount), 2) AS AvgAppointmentsPerDoctor
FROM (
    SELECT d.DoctorID, COUNT(a.AppointmentID) AS AppointmentCount
    FROM doctor d
    LEFT JOIN appointment a ON d.DoctorID = a.DoctorID
    GROUP BY d.DoctorID
) x;

-- Q34. Find each doctor's most common procedure.
WITH procedure_counts AS (
    SELECT
        a.DoctorID,
        mp.ProcedureName,
        COUNT(*) AS ProcedureCount
    FROM appointment a
    JOIN medical_procedure mp
        ON a.AppointmentID = mp.AppointmentID
    GROUP BY a.DoctorID, mp.ProcedureName
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY DoctorID
               ORDER BY ProcedureCount DESC, ProcedureName
           ) AS rn
    FROM procedure_counts
)
SELECT
    d.DoctorID,
    d.DoctorName,
    r.ProcedureName,
    r.ProcedureCount
FROM ranked r
JOIN doctor d ON r.DoctorID = d.DoctorID
WHERE r.rn = 1
ORDER BY d.DoctorName;

-- Q35. Find patients with billing above the overall average patient billing.
WITH patient_billing AS (
    SELECT PatientID, SUM(Amount) AS TotalBilling
    FROM billing
    GROUP BY PatientID
)
SELECT
    pb.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    pb.TotalBilling
FROM patient_billing pb
JOIN patient p ON pb.PatientID = p.PatientID
WHERE pb.TotalBilling > (SELECT AVG(TotalBilling) FROM patient_billing)
ORDER BY pb.TotalBilling DESC;

-- Q36. Show appointment count and total billing for every patient.
SELECT
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    COUNT(DISTINCT a.AppointmentID) AS AppointmentCount,
    COALESCE(SUM(b.Amount), 0) AS TotalBilling
FROM patient p
LEFT JOIN appointment a ON p.PatientID = a.PatientID
LEFT JOIN billing b ON p.PatientID = b.PatientID
GROUP BY p.PatientID, p.FirstName, p.LastName
ORDER BY TotalBilling DESC;

-- Q37. Identify high-value patients:
-- total billing >= 500000 OR at least 3 appointments.
WITH patient_metrics AS (
    SELECT
        p.PatientID,
        CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
        COUNT(DISTINCT a.AppointmentID) AS AppointmentCount,
        COALESCE(SUM(DISTINCT b.Amount), 0) AS TotalBilling
    FROM patient p
    LEFT JOIN appointment a ON p.PatientID = a.PatientID
    LEFT JOIN billing b ON p.PatientID = b.PatientID
    GROUP BY p.PatientID, p.FirstName, p.LastName
)
SELECT *
FROM patient_metrics
WHERE TotalBilling >= 500000
   OR AppointmentCount >= 3
ORDER BY TotalBilling DESC, AppointmentCount DESC;

-- Q38. Find the specialization generating the highest total billing.
WITH specialization_billing AS (
    SELECT
        d.Specialization,
        SUM(b.Amount) AS TotalBilling
    FROM doctor d
    JOIN appointment a ON d.DoctorID = a.DoctorID
    JOIN billing b ON a.PatientID = b.PatientID
    GROUP BY d.Specialization
)
SELECT *
FROM specialization_billing
ORDER BY TotalBilling DESC
LIMIT 1;

-- Q39. Create a patient-level healthcare summary view.
DROP VIEW IF EXISTS patient_healthcare_summary;

CREATE VIEW patient_healthcare_summary AS
SELECT
    p.PatientID,
    CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
    COUNT(DISTINCT a.AppointmentID) AS AppointmentCount,
    COUNT(DISTINCT mp.ProcedureID) AS ProcedureCount,
    COUNT(DISTINCT b.InvoiceID) AS InvoiceCount,
    COALESCE(SUM(DISTINCT b.Amount), 0) AS TotalBilling
FROM patient p
LEFT JOIN appointment a ON p.PatientID = a.PatientID
LEFT JOIN medical_procedure mp ON a.AppointmentID = mp.AppointmentID
LEFT JOIN billing b ON p.PatientID = b.PatientID
GROUP BY p.PatientID, p.FirstName, p.LastName;

SELECT *
FROM patient_healthcare_summary
ORDER BY TotalBilling DESC;

-- Q40. Produce a management KPI report.
SELECT
    (SELECT COUNT(*) FROM patient) AS TotalPatients,
    (SELECT COUNT(*) FROM doctor) AS TotalDoctors,
    (SELECT COUNT(*) FROM appointment) AS TotalAppointments,
    (SELECT COUNT(*) FROM medical_procedure) AS TotalProcedures,
    (SELECT COUNT(*) FROM billing) AS TotalInvoices,
    (SELECT ROUND(SUM(Amount), 2) FROM billing) AS TotalBilling,
    (SELECT ROUND(AVG(Amount), 2) FROM billing) AS AverageInvoiceAmount;

-- ============================================================
-- BONUS INTERVIEW QUESTIONS
-- ============================================================

-- B1. Find duplicate patient emails.
SELECT
    Email,
    COUNT(*) AS EmailCount
FROM patient
GROUP BY Email
HAVING COUNT(*) > 1;

-- B2. Find duplicate doctor contact values.
SELECT
    DoctorContact,
    COUNT(*) AS ContactCount
FROM doctor
GROUP BY DoctorContact
HAVING COUNT(*) > 1;

-- B3. Find the top 5 procedures by frequency.
SELECT
    ProcedureName,
    COUNT(*) AS ProcedureCount
FROM medical_procedure
GROUP BY ProcedureName
ORDER BY ProcedureCount DESC
LIMIT 5;

-- B4. Find the percentage of patients who have at least one appointment.
SELECT
    ROUND(
        100.0 * COUNT(DISTINCT a.PatientID) / COUNT(*),
        2
    ) AS PatientAppointmentPercentage
FROM patient p
LEFT JOIN appointment a ON p.PatientID = a.PatientID;

-- B5. Find appointments that have a medical procedure.
SELECT
    a.AppointmentID,
    a.Date,
    mp.ProcedureName
FROM appointment a
JOIN medical_procedure mp
    ON a.AppointmentID = mp.AppointmentID
ORDER BY a.Date;


