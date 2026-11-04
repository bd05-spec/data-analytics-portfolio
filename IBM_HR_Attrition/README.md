# IBM HR Attrition Analysis

1,470 employees, 237 of whom left, and I wanted to know *who*. The headline number is a company-wide attrition rate of 16.12%, but that average hides almost everything interesting - the real story is a 16x spread between the safest and least safe job roles in the business.

## The dashboard

Five pages answering "who leaves, and when?":

* **Overview** - KPI rail (1,470 employees, 16.1% attrition, median monthly pay $3,202 for leavers vs $5,204 for stayers), attrition by role and by tenure.
* **Drivers** - overtime (30.5% vs 10.4%), a job level x overtime heatmap (Level 1 on overtime: 52.6%, n=156), travel and income bands.
* **More drivers** - age, stock options, job involvement, work-life balance, job satisfaction and marital status.
* **Explore** - job role x overtime matrix with six slicers. I tried a decomposition tree here, but it hung Power BI Desktop twice, so a matrix replaced it.
* **Action plan** - six retention moves sized with a gap-closed slider. Capping overtime avoids the most leavers: about 42 of 237 at half the gap. These are associations, so each move should be piloted against a control group.

![Overview](visuals/dashboard_overview.png)
![Action plan](visuals/dashboard_action_plan.png)

**Source:** Kaggle `pavansubhasht/ibm-hr-analytics-attrition-dataset` (v1), a simulated dataset built by IBM data scientists. None of these people are real.

## What the data looked like on arrival

1,470 rows and 35 columns, one row per employee, and honestly almost nothing to clean. I checked the usual things and they all came back flat:

* **Zero null cells.** Not one missing value anywhere in 51,450 cells.
* **Zero duplicate rows**, and `EmployeeNumber` is unique across all 1,470 records, so it works as a primary key.
* **Three dead columns.** `EmployeeCount`, `Over18` and `StandardHours` each hold a single value for every row (`1`, `N`, `80`). They cannot vary, so they cannot support any analysis. I left them in the CSV and dropped them from the BI model.
* **No temporal contradictions.** I checked whether anyone had been in their current role longer than they had been at the company, which would be a data-entry error. Nobody had.

So the cleaning step here was mostly *deliberate removal* rather than repair. The one transformation that mattered was bucketing `Age` into five bands, because the raw range (18-65) was too wide to plot meaningfully.

## What I found

The department view is the least interesting of the three, which is part of why I kept it as a slicer instead of a headline chart. Sales sits at 20.6% and HR at 19.0%, R&D at 13.8% - a real spread, but nothing you would act on.

![Attrition rate by department](visuals/IBM_HR_Attrition_dept_attrition.png)

The role breakdown is where it gets sharp. Sales Representatives churn at **39.8%**, Research Directors at **2.5%**. Sixteen times worse. Age moves the same way: 18-25 year olds leave at 35.8%, 26-35 at 19.1%, 36-45 at 9.2%, with a small rise to 12.5% at 46-60.

![Attrition rate by job role](visuals/IBM_HR_Attrition_role_attrition.png)

I want to be careful about over-reading this. A role of 83 people (Sales Reps) and one with 2 exits out of 80 (Research Directors) are very different statistical strengths, and a naive ranking makes the small-sample roles look more certain than they are. The pattern is consistent enough across both department and age to be worth flagging to HR, but I would want tenure and exit-reason data before recommending any specific intervention.

## What is in the folder

* [`raw_unedited/WA_Fn-UseC_-HR-Employee-Attrition.csv`](raw_unedited/WA_Fn-UseC_-HR-Employee-Attrition.csv) - the original Kaggle file, untouched.
* [`data/cleaned/`](data/cleaned/) - cleaned CSV and XLSX, plus `IBM_HR_Attrition_role_summary.csv`, the aggregated role table that feeds the dashboard.
* [`notebooks/IBM_HR_Attrition_analysis.ipynb`](notebooks/IBM_HR_Attrition_analysis.ipynb) - the pandas pipeline and chart exports.
* [`sql/IBM_HR_Attrition.sql`](sql/IBM_HR_Attrition.sql) - SQL Server DDL and the four aggregation queries, written independently of the notebook.
* [`dashboard/IBM_HR_Attrition.pbip`](dashboard/IBM_HR_Attrition.pbip) - the Power BI project (PBIR report + TMDL model) reading the cleaned CSV through a `DataRoot` parameter. Five pages: Overview, Drivers, More drivers, Explore, Action plan.
* [`dashboard/IBM_HR_Attrition.pbix`](dashboard/IBM_HR_Attrition.pbix) - standalone copy for download.
* [`visuals/`](visuals/) - the two charts embedded above.

## Data validation

I rebuilt the headline numbers in both Python and T-SQL and made sure they agreed, which is the only reason I trust a hand-off number:

| Metric | Python | SQL |
| --- | --- | --- |
| Rows | 1,470 | 1,470 |
| Distinct EmployeeNumber | 1,470 | 1,470 |
| Attrition count | 237 | 237 |
| Attrition rate | 16.12% | 16.12% |

The role ranking uses `RANK()` in SQL so the ordering is reproducible, rather than inheriting whatever order the engine happens to return.
