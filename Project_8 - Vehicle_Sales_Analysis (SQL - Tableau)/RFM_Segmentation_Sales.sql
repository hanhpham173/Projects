-- Group Sales by ProductLine 
SELECT PRODUCTLINE, ROUND(SUM(SALES),2) Revenue
FROM sales_data_sample
GROUP BY PRODUCTLINE	
ORDER BY 2 DESC;

-- Group Sales by Year 
SELECT YEAR_ID, ROUND(SUM(SALES),2) Revenue
FROM sales_data_sample
GROUP BY YEAR_ID	
ORDER BY 2 DESC;

-- Group Sales by DealSize 
SELECT DEALSIZE, ROUND(SUM(SALES),2) Revenue
FROM sales_data_sample
GROUP BY DEALSIZE	
ORDER BY 2 DESC;

-- What was the best month for sales in a specific year? How much was earned that month? 
SELECT MONTH_ID, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY 2 DESC;

SELECT MONTH_ID, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY 2 DESC;


-- November seems to be the month, what product do they sell in November, I believe
SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2003 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC;

SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2004 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC;

-- Who is our best customer
DROP TABLE IF EXISTS #RFM;
WITH RFM AS
(
	SELECT 
		CUSTOMERNAME,
		SUM(SALES) MonetaryValue,
		AVG(SALES) AvgMonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) lastest_order_date,
		(SELECT MAX(ORDERDATE) FROM sales_data_sample) max_order_date,
		DATEDIFF (DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) Recency 
	FROM sales_data_sample
	GROUP BY CUSTOMERNAME
),
RFM_cal AS
(
SELECT *,
	NTILE(4) OVER (ORDER BY Recency) RFM_Recency,
	NTILE(4) OVER (ORDER BY Frequency) RFM_Frequency,
	NTILE(4) OVER (ORDER BY MonetaryValue) RFM_Monetary
FROM RFM
)
SELECT 
	*,
	RFM_Recency + RFM_Frequency + RFM_Monetary AS RFM_Cell,
	CAST(RFM_Recency AS varchar) + CAST(RFM_Frequency AS varchar) + CAST(RFM_Monetary AS varchar) AS RFM_Cell_String
INTO #RFM
FROM RFM_cal

SELECT 
	CUSTOMERNAME,
	RFM_Recency,
	RFM_Frequency,
	RFM_Monetary,
	CASE 
		WHEN RFM_Cell_String in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers'  --lost customers
		WHEN RFM_Cell_String in (133, 134, 143, 244, 243, 334, 343, 344, 144) THEN 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		WHEN RFM_Cell_String in (311, 312, 411, 412, 331) THEN 'new customers'
		WHEN RFM_Cell_String in (222, 223, 233, 322, 232) THEN 'potential churners'
		WHEN RFM_Cell_String in (323, 333,321, 422, 421, 332, 432) THEN 'active' --(Customers who buy often & recently, but at low price points)
		WHEN RFM_Cell_String in (433, 434, 443, 444, 423) THEN 'loyal'
	END rfm_segment
FROM #RFM;

-- What products are most often sold together? 
SELECT DISTINCT ORDERNUMBER, STUFF(

	(SELECT ',' + PRODUCTCODE
	FROM sales_data_sample p
	WHERE ORDERNUMBER IN 
		(
			SELECT ORDERNUMBER
			FROM (
				SELECT ORDERNUMBER, count(*) RowCounts
				FROM sales_data_sample
				WHERE STATUS = 'Shipped'
				GROUP BY ORDERNUMBER
			)m
			WHERE RowCounts = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		FOR XML PATH (''))
		, 1, 1, '') ProductCodes
FROM sales_data_sample s
ORDER BY 2 DESC;

--What city has the highest number of sales in a specific country?
SELECT city, SUM(SALES) Revenue
FROM sales_data_sample
WHERE country = 'UK'
GROUP BY city
ORDER BY 2 DESC;

---What is the best product in United States?
SELECT COUNTRY, YEAR_ID, PRODUCTLINE, SUM(SALES) Revenue
FROM sales_data_sample
WHERE country = 'USA'
GROUP BY country, YEAR_ID, PRODUCTLINE
ORDER BY 4 DESC;
