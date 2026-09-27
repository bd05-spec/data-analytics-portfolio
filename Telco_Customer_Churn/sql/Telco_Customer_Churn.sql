/* 
I''m creating the primary customer table for the Telco dataset.
customerID serves as the unique natural key. TotalCharges is nullable to allow
for new accounts (tenure = 0) that have not yet completed a billing cycle.
*/
CREATE TABLE dbo.Telco_Customer(
    customerID varchar(20) NOT NULL PRIMARY KEY,
    gender varchar(10) NOT NULL,
    SeniorCitizen bit NOT NULL,
    Partner varchar(3) NOT NULL,
    Dependents varchar(3) NOT NULL,
    tenure smallint NOT NULL CHECK(tenure BETWEEN 0 AND 100),
    Contract varchar(30) NOT NULL,
    MonthlyCharges decimal(10,2) NOT NULL CHECK(MonthlyCharges>=0),
    TotalCharges decimal(12,2) NULL CHECK(TotalCharges IS NULL OR TotalCharges>=0),
    Churn varchar(3) NOT NULL CHECK(Churn IN ('Yes','No'))
);

/* 
First, I''m validating the import by checking total customers, confirming customerID uniqueness,
and counting how many records had blank TotalCharges converted to NULL.
*/
SELECT 
    COUNT(*) AS customers, 
    COUNT(DISTINCT customerID) AS distinct_ids, 
    SUM(CASE WHEN Churn=''Yes'' THEN 1 ELSE 0 END) AS churned, 
    AVG(CASE WHEN Churn=''Yes'' THEN 1.0 ELSE 0.0 END) AS churn_rate, 
    SUM(CASE WHEN TotalCharges IS NULL THEN 1 ELSE 0 END) AS missing_total_charges 
FROM dbo.Telco_Customer;

/* 
Here I''m analyzing churn rate broken down by contract type. Month-to-month contracts
typically show substantially higher churn rates than long-term contracts.
*/
SELECT 
    Contract, 
    COUNT(*) AS customers, 
    SUM(CASE WHEN Churn=''Yes'' THEN 1 ELSE 0 END) AS churned, 
    AVG(CASE WHEN Churn=''Yes'' THEN 1.0 ELSE 0.0 END) AS churn_rate 
FROM dbo.Telco_Customer 
GROUP BY Contract 
ORDER BY churn_rate DESC;

/* 
This query examines churn rate across tenure (months as a customer) to understand
whether customer attrition happens early or later in the lifecycle.
*/
SELECT 
    tenure, 
    COUNT(*) AS customers, 
    AVG(CASE WHEN Churn=''Yes'' THEN 1.0 ELSE 0.0 END) AS churn_rate 
FROM dbo.Telco_Customer 
GROUP BY tenure 
ORDER BY tenure;

/* 
Finally, evaluating churn across payment methods to identify potential friction points
in payment processing or billing preferences (e.g., electronic check vs credit card).
*/
SELECT 
    PaymentMethod, 
    COUNT(*) AS customers, 
    AVG(CASE WHEN Churn=''Yes'' THEN 1.0 ELSE 0.0 END) AS churn_rate 
FROM dbo.Telco_Customer 
GROUP BY PaymentMethod 
ORDER BY churn_rate DESC;
