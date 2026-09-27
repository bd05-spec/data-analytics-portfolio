/* 
First, I'm setting up the staging table to load the cleaned employee records.
EmployeeNumber is the natural primary key here.
*/
IF OBJECT_ID('dbo.HR_Employee','U') IS NULL
CREATE TABLE dbo.HR_Employee(
    EmployeeNumber int NOT NULL PRIMARY KEY, 
    Age tinyint NOT NULL, 
    Attrition varchar(3) NOT NULL CHECK(Attrition IN ('Yes','No')), 
    Department nvarchar(100) NOT NULL, 
    JobRole nvarchar(100) NOT NULL, 
    MonthlyIncome int NOT NULL, 
    YearsAtCompany int NOT NULL, 
    TotalWorkingYears int NOT NULL
);

/* 
I want to establish a baseline of how many employees we have, and the overall company attrition rate.
*/
SELECT 
    COUNT(*) AS row_count, 
    COUNT(DISTINCT EmployeeNumber) AS distinct_employee_ids, 
    SUM(CASE WHEN Attrition='Yes' THEN 1 ELSE 0 END) AS attritions, 
    AVG(CASE WHEN Attrition='Yes' THEN 1.0 ELSE 0.0 END) AS attrition_rate 
FROM dbo.HR_Employee;

/* 
Breaking down the attrition by Department to see where the bulk of the turnover is happening.
*/
SELECT 
    Department, 
    COUNT(*) AS employees, 
    SUM(CASE WHEN Attrition='Yes' THEN 1 ELSE 0 END) AS attritions, 
    AVG(CASE WHEN Attrition='Yes' THEN 1.0 ELSE 0.0 END) AS attrition_rate 
FROM dbo.HR_Employee 
GROUP BY Department 
ORDER BY attrition_rate DESC;

/* 
Drilling deeper, I'm looking at specific job roles and ranking them by attrition rate.
This helps pinpoint exact positions that are struggling to retain talent.
*/
SELECT 
    JobRole, 
    COUNT(*) AS employees, 
    SUM(CASE WHEN Attrition='Yes' THEN 1 ELSE 0 END) AS attritions, 
    AVG(CASE WHEN Attrition='Yes' THEN 1.0 ELSE 0.0 END) AS attrition_rate, 
    RANK() OVER(ORDER BY AVG(CASE WHEN Attrition='Yes' THEN 1.0 ELSE 0.0 END) DESC) AS role_rank 
FROM dbo.HR_Employee 
GROUP BY JobRole 
ORDER BY role_rank;

/* 
Finally, analyzing attrition across age bands to see if turnover is concentrated among younger or older demographics.
*/
SELECT 
    CASE 
        WHEN Age<25 THEN '18-24' 
        WHEN Age<35 THEN '25-34' 
        WHEN Age<45 THEN '35-44' 
        WHEN Age<55 THEN '45-54' 
        ELSE '55+' 
    END AS age_band, 
    COUNT(*) AS employees, 
    AVG(CASE WHEN Attrition='Yes' THEN 1.0 ELSE 0.0 END) AS attrition_rate 
FROM dbo.HR_Employee 
GROUP BY 
    CASE 
        WHEN Age<25 THEN '18-24' 
        WHEN Age<35 THEN '25-34' 
        WHEN Age<45 THEN '35-44' 
        WHEN Age<55 THEN '45-54' 
        ELSE '55+' 
    END;
