/* 
I''m creating the curated order-item fact table. PII fields (customer names, emails, passwords)
were intentionally excluded during data cleaning to enforce data minimization.
Order Item Id serves as the primary key.
*/
CREATE TABLE dbo.DataCo_OrderItem(
    [Order Item Id] bigint NOT NULL PRIMARY KEY,
    [Order Id] bigint NOT NULL,
    [Order Customer Id] bigint NOT NULL,
    [order date (DateOrders)] datetime2 NULL,
    [shipping date (DateOrders)] datetime2 NULL,
    [Sales] decimal(19,4) NOT NULL,
    [Order Profit Per Order] decimal(19,4) NULL,
    [Late_delivery_risk] bit NOT NULL,
    [Delivery Status] nvarchar(40) NULL,
    [Category Name] nvarchar(100) NULL,
    [Order Region] nvarchar(100) NULL,
    [Order Status] nvarchar(40) NULL
);

/* 
Validating the import by checking total item count, distinct order count, aggregate sales and profit,
and average late delivery risk rate.
*/
SELECT 
    COUNT(*) AS order_items, 
    COUNT(DISTINCT [Order Item Id]) AS distinct_item_ids, 
    COUNT(DISTINCT [Order Id]) AS orders, 
    SUM(Sales) AS sales, 
    SUM([Order Profit Per Order]) AS profit, 
    AVG(CAST([Late_delivery_risk] AS float)) AS late_risk_rate 
FROM dbo.DataCo_OrderItem;

/* 
Summarizing sales, profitability, and delivery risk by geographic Order Region.
This highlights key revenue drivers alongside operational fulfillment risks.
*/
SELECT 
    [Order Region], 
    COUNT(*) AS items, 
    SUM(Sales) AS sales, 
    SUM([Order Profit Per Order]) AS profit, 
    AVG(CAST([Late_delivery_risk] AS float)) AS late_risk_rate 
FROM dbo.DataCo_OrderItem 
GROUP BY [Order Region] 
ORDER BY sales DESC;

/* 
Evaluating profitability by product category to identify underperforming or loss-leading categories.
*/
SELECT 
    [Category Name], 
    COUNT(*) AS items, 
    SUM(Sales) AS sales, 
    SUM([Order Profit Per Order]) AS profit 
FROM dbo.DataCo_OrderItem 
GROUP BY [Category Name] 
ORDER BY profit;

/* 
Calculating cumulative sales and a 7-day moving average of daily sales using window functions
to smooth out daily purchasing volatility.
*/
WITH M AS (
    SELECT 
        CAST([order date (DateOrders)] AS date) AS order_day, 
        SUM(Sales) AS sales 
    FROM dbo.DataCo_OrderItem 
    GROUP BY CAST([order date (DateOrders)] AS date)
) 
SELECT 
    order_day,
    sales,
    SUM(sales) OVER(ORDER BY order_day ROWS UNBOUNDED PRECEDING) AS running_sales,
    AVG(sales) OVER(ORDER BY order_day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS seven_day_avg 
FROM M 
ORDER BY order_day;
