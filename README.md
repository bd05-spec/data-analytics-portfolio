# Data Analytics Portfolio

Welcome to my data analytics portfolio! This repository showcases five end-to-end data analytics projects spanning healthcare, human resources, telecommunications, supply chain logistics, and e-commerce.

Each project folder follows a standardized structure containing raw-source documentation, cleaned datasets, Jupyter notebooks, T-SQL scripts, Power BI Project files (`dashboard/<Project>.pbip` with PBIR report and TMDL model folders), and page screenshots in `visuals/`. The PBIP projects read the cleaned CSVs through one `DataRoot` parameter (the GitHub raw URL of this repo by default, or a local clone folder), so they open on any PC.

---

## Portfolio Projects

### 1. [CMS HCAHPS National Data Analysis](CMS_HCAHPS_National/)
* **Focus:** Healthcare Patient Experience & Quality Benchmarks
* **Summary:** Analyzes national aggregate metrics from the Hospital Consumer Assessment of Healthcare Providers and Systems (HCAHPS) survey (Oct 2024 – Sep 2025). The analysis reconciles categorical response distributions to 100% and benchmarks top-box patient satisfaction scores across nurse communication, doctor respect, and hospital environment.
* **Key Finding:** The weakest area is explaining possible side effects of new medicines: only 49% of patients say staff always did, followed by quiet at night (60%). Courtesy and respect from nurses and doctors score highest on the same Always/Usually/Never scale (86%).
* **Explore:** [`CMS_HCAHPS_National/README.md`](CMS_HCAHPS_National/README.md)
* **Power BI:** [Open the PBIP project](CMS_HCAHPS_National/dashboard/CMS_HCAHPS_National.pbip) (2 pages: scorecard and priorities) or [download the .pbix](CMS_HCAHPS_National/dashboard/CMS_HCAHPS_National.pbix)

### 2. [IBM HR Employee Attrition Analysis](IBM_HR_Attrition/)
* **Focus:** Human Resources Analytics & Workforce Retention
* **Summary:** Explores demographic, compensation, and role-specific drivers of employee turnover across 1,470 employee records. Validates tenure logic, evaluates income distributions, and identifies job roles with elevated flight risk.
* **Key Finding:** Company-wide attrition stands at 16.12%, with Sales Representatives experiencing the highest turnover rate (39.8%), while Directors and Executives exhibit high retention (>90%).
* **Explore:** [`IBM_HR_Attrition/README.md`](IBM_HR_Attrition/README.md)
* **Power BI:** [Open the PBIP project](IBM_HR_Attrition/dashboard/IBM_HR_Attrition.pbip) (5 pages, including a sized action plan) or [download the .pbix](IBM_HR_Attrition/dashboard/IBM_HR_Attrition.pbix)

### 3. [Telco Customer Churn Analysis](Telco_Customer_Churn/)
* **Focus:** Telecommunications Customer Retention & Subscription Modeling
* **Summary:** Investigates customer attrition patterns across 7,043 accounts. Handles missing billing records for zero-tenure accounts without data fabrication and analyzes churn differentials across contract terms, payment types, and internet services.
* **Key Finding:** Overall churn is 26.54%. Customers on month-to-month contracts churn at a rate of 42.7%, compared to just 11.3% for one-year and 2.8% for two-year contracts.
* **Explore:** [`Telco_Customer_Churn/README.md`](Telco_Customer_Churn/README.md)
* **Power BI:** [Open the PBIP project](Telco_Customer_Churn/dashboard/Telco_Customer_Churn.pbip) (4 pages, including a sized action plan) or [download the .pbix](Telco_Customer_Churn/dashboard/Telco_Customer_Churn.pbix)

### 4. [DataCo Smart Supply Chain Analysis](DataCo_Supply_Chain/)
* **Focus:** Logistics, Fulfillment Risk & Global Sales Performance
* **Summary:** Evaluates 180,519 order item records spanning global e-commerce supply chains. Implements strict PII data minimization by removing sensitive customer attributes while auditing fulfillment statuses and calculating 7-day moving sales averages.
* **Key Finding:** Total sales reached $36.78M across 65,752 orders. 54.83% of all order items (57.3% excluding canceled shipments) were delivered late. Late rates are nearly identical across markets (54.4-55.2%); the difference is shipping class: First Class is late 95.3% of the time and Standard Class 38.1%.
* **Explore:** [`DataCo_Supply_Chain/README.md`](DataCo_Supply_Chain/README.md)
* **Power BI:** [Open the PBIP project](DataCo_Supply_Chain/dashboard/DataCo_Supply_Chain.pbip) (5 pages, including a promise what-if action plan) or [download the .pbix](DataCo_Supply_Chain/dashboard/DataCo_Supply_Chain.pbix)

### 5. [Ecommerce Multi-Category Behavioral Analysis](Ecommerce/)
* **Focus:** E-Commerce User Behavior, Funnel Conversion & Big Data Streaming
* **Summary:** Processes 109.95 million user interaction events (~14.7 GB raw CSVs) from October and November 2019 using a high-performance 1M-chunk Python streaming pipeline. Analyzes view-to-cart-to-purchase conversion funnels, price band value shares, and peak shopping hours.
* **Key Finding:** Users generated $505.15M in total purchase value. Overall conversion from product view to purchase is 1.59%, with 54.9% of purchase value coming from items priced over $500. Purchase value is the sum of item prices; the data has no revenue field. Cart tracking is inconsistent across days, so cart-based rates are not reliable.
* **Explore:** [`Ecommerce/README.md`](Ecommerce/README.md)
* **Power BI:** [Open the PBIP project](Ecommerce/dashboard/Ecommerce.pbip) (6 pages, including a conversion action plan) or [download the .pbix](Ecommerce/dashboard/Ecommerce.pbix) — built from full-data summaries produced by `Ecommerce/scripts/build_summaries.py`, not the 100,000-row sample.

---

## Repository Structure

Every project within this repository adheres to a unified folder architecture:

```text
data-analytics-portfolio/
├── README.md                              <- Portfolio sitemap and index
├── .gitignore                             <- Version control exclusion rules
├── <Project_Folder>/
│   ├── README.md                          <- Project documentation & key findings
│   ├── raw_unedited/                      <- Original raw source data / documentation
│   ├── data/
│   │   └── cleaned/                       <- Final cleaned analytical datasets & QA reports
│   ├── notebooks/
│   │   └── <Project>_analysis.ipynb       <- Structured Jupyter notebook
│   ├── sql/
│   │   └── <Project>.sql                  <- Production T-SQL schema & queries
│   ├── dashboard/
│   │   ├── <Project>.pbip                 <- Power BI Project (open this in Power BI Desktop)
│   │   ├── <Project>.Report/              <- PBIR report definition
│   │   └── <Project>.SemanticModel/       <- TMDL semantic model
│   └── visuals/                           <- Chart graphics and dashboard page screenshots (PNG)
```
