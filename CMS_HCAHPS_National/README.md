# CMS HCAHPS National Patient Experience Benchmark

I analyzed the national summary metrics from the CMS Hospital Consumer Assessment of Healthcare Providers and Systems (HCAHPS) survey. The dataset captures patient experience evaluations across 51 standardized survey measures for the reporting period from October 1, 2024, through September 30, 2025.

Because this public file is already rolled up to national aggregates, it does not include hospital-level identifiers or regional splits. My analysis focuses strictly on evaluating domain-level benchmarks, validating response distributions across response tiers, and building a clean reference model.

## Raw Data & Identified Constraints
* **Granularity**: Exactly 51 rows and 7 raw columns. Each record represents a single national reporting value for a specific survey measure.
* **Structural Limitations**: There are no provider IDs, geographical breakdowns, or longitudinal periods in this table. I deliberately avoided calculating hospital rankings, mock confidence intervals, or pseudo-time trends that the raw data cannot support.
* **Footnotes**: Footnote columns contained purely null entries across all 51 rows in this reporting cycle, which I flagged during profiling and omitted from the relational model.

## Data Cleaning & Transformation Decisions
1. **Header Normalization**: I converted all source headers to standardized lowercase snake_case (hcahps_measure_id, hcahps_question, hcahps_answer_description, hcahps_answer_percent, start_date, end_date).
2. **Dimension Parsing**: The raw hcahps_measure_id encodes both the survey topic and the response level. I wrote parsing logic to unpack these into two distinct attributes: question_group (18 distinct question domains such as H_NURSE_RESPECT, H_DOCTOR_LISTEN, H_CLEAN_HSP) and 
esponse_code (A for Always, U for Usually, SN for Sometimes/Never, Y for Yes, N for No).
3. **Data Types**: I cast hcahps_answer_percent to a strict integer range (0-100) and parsed start/end dates into standardized ISO dates.

`sql
SELECT
    question_group,
    SUM(answer_percent) AS category_percent_sum,
    CASE WHEN SUM(answer_percent)=100 THEN 1 ELSE 0 END AS reconciles_to_100
FROM dbo.HCAHPS_National
GROUP BY question_group
ORDER BY question_group;
`

## Data Validation Results
Before designing the dashboard, I ran cross-checks in Python and SQL:
* **Row Count & Uniqueness**: Both environments verified exactly 51 rows, with measure_id serving as a distinct primary key.
* **100% Categorical Reconciliation**: For every single one of the 18 question groups, summing the answer percentages across tiers ('Always', 'Usually', 'Sometimes/Never') yields exactly 100%. None were dropped or distorted.
* **Range Checks**: Validated that all percentage values lie strictly between 0% and 100% (minimum 4%, maximum 88%).

## Key Findings & Visuals

### 1. Domain-Level Top-Box Scores
Top-box responses (patients choosing the most favorable category, typically 'Always') reveal substantial variation across domains. Interpersonal respect from clinicians consistently tops the survey, whereas care discharge assistance and medication side effect communication score noticeably lower.

![National HCAHPS top-box responses](visuals/CMS_HCAHPS_National_topbox.png)

### 2. Category Sum Integrity Check
Every question group reconciles cleanly to 100%, confirming that the survey tiers capture full respondent coverage without rounding leakage.

![HCAHPS Response Category Sum Reconciliation](visuals/CMS_HCAHPS_reconciliation_check.png)

## Folder Contents
* [
aw_unedited/HCAHPS-National.csv](raw_unedited/HCAHPS-National.csv) - Original CMS national export.
* [data/cleaned/](data/cleaned/) - Cleaned analytical files (.csv, .xlsx) and category reconciliation tables.
* [
otebooks/CMS_HCAHPS_National_analysis.ipynb](notebooks/CMS_HCAHPS_National_analysis.ipynb) - Jupyter notebook with end-to-end cleaning, assertions, and plots.
* [sql/CMS_HCAHPS_National.sql](sql/CMS_HCAHPS_National.sql) - Schema DDL, range validation, and top-box queries.
* [dashboard/](dashboard/) - Power BI project (CMS_HCAHPS_National.pbip) featuring card KPIs, question group slicer, top-box bar chart, and category table.
* [isuals/](visuals/) - Exported summary visuals.\n