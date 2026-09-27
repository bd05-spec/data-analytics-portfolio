/* 
I'm creating the core table for the national HCAHPS scores. This data represents a single 
reporting window rolled up to the national level, so the measure ID acts as the primary key.
There are no provider-level keys here.
*/
CREATE TABLE dbo.HCAHPS_National(
    measure_id varchar(40) NOT NULL PRIMARY KEY,
    question nvarchar(500) NOT NULL,
    answer_description nvarchar(500) NOT NULL,
    answer_percent tinyint NOT NULL CHECK(answer_percent BETWEEN 0 AND 100),
    footnote float NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    question_group varchar(40) NOT NULL,
    response_code varchar(10) NULL
);

/* 
First, I'm validating the load by checking the date ranges and ensuring all answer percentages fall within 
valid bounds (0-100).
*/
SELECT 
    COUNT(*) AS measures,
    COUNT(DISTINCT measure_id) AS unique_measure_ids,
    MIN(answer_percent) AS min_percent,
    MAX(answer_percent) AS max_percent,
    MIN(start_date) AS start_date,
    MAX(end_date) AS end_date 
FROM dbo.HCAHPS_National;

/* 
This is a critical cross-check: for every question group, the possible categorical responses 
(e.g., 'Always', 'Usually', 'Sometimes/Never') MUST sum up to exactly 100%. 
*/
SELECT 
    question_group,
    SUM(answer_percent) AS category_percent_sum,
    CASE WHEN SUM(answer_percent)=100 THEN 1 ELSE 0 END AS reconciles_to_100 
FROM dbo.HCAHPS_National 
GROUP BY question_group 
ORDER BY question_group;

/* 
To understand performance, I'm isolating just the "top-box" (most positive) responses, indicated 
by response_code='A'. Sorting by percentage helps easily identify the highest-performing areas.
*/
SELECT 
    question_group,
    answer_description,
    answer_percent 
FROM dbo.HCAHPS_National 
WHERE response_code='A' 
ORDER BY answer_percent;
