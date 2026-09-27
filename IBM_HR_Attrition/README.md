# IBM HR Attrition Analysis

## Overview
This project explores employee attrition using a simulated HR dataset created by IBM data scientists. The goal is to uncover the factors that lead to employee turnover and identify which roles or departments are most at risk.

**Source:** Kaggle `pavansubhasht/ibm-hr-analytics-attrition-dataset` (v1).

## Data Quality & Limitations
* **Format:** The raw data consists of 1,470 rows and 35 columns, with one row per employee.
* **Integrity:** The dataset is extremely clean. There are zero null cells and zero duplicate rows.
* **Redundancy:** Several columns (`EmployeeCount`, `Over18`, `StandardHours`) contained only a single constant value across all 1,470 rows. Because they offer no analytical variance, they were excluded from the BI model.

## Data Cleaning & Transformation
1. **Deduplication & Trimming:** Validated that `EmployeeNumber` is strictly unique. String columns were trimmed of whitespace.
2. **Logical Validation:** Checked for temporal impossibilities (e.g., someone being in their current role longer than they've been at the company). No contradictions were found.
3. **Derived Metrics:** Calculated attrition rates across departments, roles, and age bands to feed into the dashboard and visuals.

## Folder Contents
* [`raw_unedited/WA_Fn-UseC_-HR-Employee-Attrition.csv`](raw_unedited/WA_Fn-UseC_-HR-Employee-Attrition.csv) - The original source file.
* [`data/cleaned/`](data/cleaned/) - Contains the cleaned analytical dataset and job role summaries.
* [`notebooks/IBM_HR_Attrition_analysis.ipynb`](notebooks/IBM_HR_Attrition_analysis.ipynb) - Jupyter notebook detailing the data processing.
* [`sql/IBM_HR_Attrition.sql`](sql/IBM_HR_Attrition.sql) - SQL Server schema and analysis queries.
* [`dashboard/`](dashboard/) - Power BI semantic model (`.pbip` format).
* [`visuals/IBM_HR_Attrition_role_attrition.png`](visuals/IBM_HR_Attrition_role_attrition.png) - Exported chart visual.

## Data Validation
Metrics were cross-checked between the Python pipeline and SQL queries to ensure exact alignment:
* **Employee Count:** 1,470 distinct employees.
* **Attrition Count:** 237 employees flagged as leaving.
* **Attrition Rate:** 16.12% overall company attrition rate.

## Key Finding

Here is a breakdown of the attrition rate by job role. Sales Representatives experience the highest turnover, while Directors and Managers are the most stable:

![Attrition rate by job role](visuals/IBM_HR_Attrition_role_attrition.png)
