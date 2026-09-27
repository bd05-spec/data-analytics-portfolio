# CMS HCAHPS National Data Analysis

## Overview
This project analyzes the national aggregate data for the CMS Hospital Consumer Assessment of Healthcare Providers and Systems (HCAHPS) survey. 
The dataset contains national-level summary metrics for the reporting window from October 1, 2024, to September 30, 2025. 

**Source:** Local CMS national export (from data.cms.gov dataset 99ue-w85f).

## Data Quality & Limitations
* **Aggregation Level:** The dataset provides only one national response per measure ID. It does not contain provider-level or hospital-level details, meaning no time-series trends, hospital rankings, or significance tests are possible.
* **Format:** The raw data contains 51 rows and 7 columns. 

## Data Cleaning & Transformation
The data preparation process focused on standardizing the schema and extracting analytical dimensions:
1. **Standardization:** Column names were converted to lowercase and whitespace was trimmed.
2. **Data Types:** Date columns were explicitly parsed and percentage answers were cast to integers.
3. **Dimensional Extraction:** The `hcahps_measure_id` was parsed to extract the underlying `question_group` and categorical `response_code` (e.g., 'A' for Always, 'U' for Usually).

## Folder Contents
* [`raw_unedited/HCAHPS-National.csv`](raw_unedited/HCAHPS-National.csv) - The original, unmodified source file.
* [`data/cleaned/`](data/cleaned/) - Contains the cleaned analytical datasets (CSV, Excel) and reconciliation reports.
* [`notebooks/CMS_HCAHPS_National_analysis.ipynb`](notebooks/CMS_HCAHPS_National_analysis.ipynb) - Jupyter notebook detailing the data processing and analysis.
* [`sql/CMS_HCAHPS_National.sql`](sql/CMS_HCAHPS_National.sql) - SQL Server schema, validation, and analysis queries.
* [`dashboard/`](dashboard/) - Power BI semantic model (`.pbip` format).
* [`visuals/CMS_HCAHPS_National_topbox.png`](visuals/CMS_HCAHPS_National_topbox.png) - Exported chart visuals.

## Data Validation
To ensure accuracy, the processed metrics were independently validated across Python and SQL:
* **Row Count:** Verified exactly 51 independent measures in both environments.
* **100% Reconciliation:** A critical cross-check confirmed that for every single question group, the combined response percentages ('Always' + 'Usually' + 'Sometimes/Never') correctly sum up to 100%.

## Key Finding

Here is the distribution of the "Top-Box" (most positive) responses across the national HCAHPS measures:

![National HCAHPS top-box responses](visuals/CMS_HCAHPS_National_topbox.png)
