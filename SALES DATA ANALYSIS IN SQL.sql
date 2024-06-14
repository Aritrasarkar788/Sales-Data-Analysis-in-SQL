--- Inspecting Data
SELECT * 
FROM [dbo].[sales_data_sample];

--- Checking Unique Values
SELECT DISTINCT status 
FROM [dbo].[sales_data_sample];

--- Nice to Plot
SELECT DISTINCT YEAR_ID 
FROM [dbo].[sales_data_sample];

SELECT DISTINCT PRODUCTLINE 
FROM [dbo].[sales_data_sample];

--- Nice to Plot
SELECT DISTINCT COUNTRY 
FROM [dbo].[sales_data_sample];

--- Nice to Plot
SELECT DISTINCT DEALSIZE 
FROM [dbo].[sales_data_sample];

--- Nice to Plot
SELECT DISTINCT TERRITORY 
FROM [dbo].[sales_data_sample];

--- Analysis. Let's start by grouping sales by Productline
SELECT PRODUCTLINE, SUM(sales) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY PRODUCTLINE
ORDER BY 2 DESC;

--- Let's see in which year they made the most sales
SELECT YEAR_ID, SUM(sales) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY YEAR_ID
ORDER BY 2 DESC;

--- IN 2004 THEY MADE THE MOST SALES WHEREAS IN 2005 THEY MADE THE LEAST SALES BECAUSE THEY OPERATED FOR ONLY FEW MONTHS

--- Let's find out which dealsize generates the maximum revenue
SELECT DEALSIZE, SUM(sales) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY DEALSIZE
ORDER BY 2 DESC;

--- THE MEDIUM DEALSIZE GENERATES THE MOST REVENUE AND THE LARGE DEALSIZE GENERATES THE LEAST REVENUE

--- What was the best month for sales in a specific year and how much they had earned in that month?
SELECT MONTH_ID, SUM(sales) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY 2 DESC;

--- NOVEMBER SEEMS TO BE THE BEST MONTH FOR SALES IN A SPECIFIC YEAR

--- PRODUCT THEY SOLD IN NOVEMBER
SELECT MONTH_ID, PRODUCTLINE, SUM(sales) AS Revenue, COUNT(ORDERNUMBER)
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2004 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC;

--- NOVEMBER WAS THE BEST MONTH FOR SALES AND THEY HAD SOLD MOST NUMBER OF CLASSIC CARS IN NOVEMBER.

--- LET'S FIND OUT WHO WAS THE BEST CUSTOMER (THIS COULD BE ANSWERED WITH RFM)

-- Calculate RFM values for each customer
DROP TABLE IF EXISTS ##RFM;

WITH RFM_CTE AS (
    SELECT 
        CUSTOMERNAME,
        SUM(SALES) AS MONETARYVALUE,
        AVG(SALES) AS AvgMONETARYVALUE,
        COUNT(ORDERNUMBER) AS Frequency,
        MAX(ORDERDATE) AS LAST_ORDER_DATE,
        (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample]) AS Max_order_Date
    FROM 
        [dbo].[sales_data_sample]
    GROUP BY 
        CUSTOMERNAME
)
SELECT 
    r.CUSTOMERNAME,
    r.MONETARYVALUE,
    r.AvgMONETARYVALUE,
    r.Frequency,
    r.LAST_ORDER_DATE,
    r.Max_order_Date,
    DATEDIFF(DD, r.LAST_ORDER_DATE, r.Max_order_Date) AS RECENCY,
    NTILE(4) OVER (ORDER BY DATEDIFF(DD, r.LAST_ORDER_DATE, r.Max_order_Date) DESC) AS RFM_RECENCY,
    NTILE(4) OVER (ORDER BY r.Frequency) AS RFM_FREQUENCY,
    NTILE(4) OVER (ORDER BY r.AvgMONETARYVALUE) AS RFM_MONETARY,
    NTILE(4) OVER (ORDER BY DATEDIFF(DD, r.LAST_ORDER_DATE, r.Max_order_Date) DESC) +
    NTILE(4) OVER (ORDER BY r.Frequency) +
    NTILE(4) OVER (ORDER BY r.AvgMONETARYVALUE) AS RFM_CELL,
    CAST(NTILE(4) OVER (ORDER BY DATEDIFF(DD, r.LAST_ORDER_DATE, r.Max_order_Date) DESC) AS varchar) +
    CAST(NTILE(4) OVER (ORDER BY r.Frequency) AS varchar) +
    CAST(NTILE(4) OVER (ORDER BY r.AvgMONETARYVALUE) AS varchar) AS RFM_CELL_STRING
INTO ##RFM
FROM 
    RFM_CTE r;

-- Verify the contents of the temporary table #RFM
SELECT * FROM ##RFM;

--- WHAT PRODUCTS ARE OFTEN SOLD TOGETHER?
select DISTINCT ORDERNUMBER,  stuff(
	(SELECT ',' + PRODUCTCODE
	FROM [dbo].[sales_data_sample] P
	WHERE ORDERNUMBER IN
		(
			SELECT ORDERNUMBER
			FROM(
				SELECT ORDERNUMBER, COUNT(*) RN
				FROM [dbo].[sales_data_sample]
				WHERE STATUS = 'SHIPPED'
				GROUP BY ORDERNUMBER
				)M
				WHERE RN = 2
		)
		AND P.ORDERNUMBER = S.ORDERNUMBER
		FOR xml path ('')), 1, 1, '') PRODUCTCODES
FROM [dbo].[sales_data_sample] S
ORDER BY 2 DESC   
