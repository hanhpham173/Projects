-- Join dim_customers with dim_geography to enrich customer data with geographic information
SELECT 
	CustomerID, 
	CustomerName, 
	Email,
	Gender,
	Age, 
	Country, 
	City
FROM 
	customers c
LEFT JOIN 
	geography g 
ON
	c.GeographyID = g.GeographyID;
