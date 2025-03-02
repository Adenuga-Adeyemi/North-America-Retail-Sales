SELECT * FROM [dbo].[Sales Retail];

--SPLIT INTO FACT TABLES
--To create a DimCustomer Table from Sales Table

SELECT * INTO DimCustomer
FROM
(SELECT Customer_ID, Customer_Name FROM [Sales Retail])
AS DimC

--Remove Duplicates

WITH CTE_DimC
AS
	(SELECT Customer_ID, Customer_Name, ROW_NUMBER() OVER(PARTITION BY Customer_ID, Customer_Name ORDER BY Customer_ID ASC) AS RowNum
	FROM DimCustomer)
DELETE FROM CTE_DimC
WHERE RowNum > 1

SELECT * FROM DimCustomer

ALTER TABLE [dbo].[DimCustomer]
DROP COLUMN [Segment];



---To create DimLocation table from Sales Retail

SELECT * INTO DimLocation
FROM
(SELECT [Postal_Code],[Country], [City], [State], [Region] FROM [Sales Retail])
AS DimL

SELECT * FROM DimLocation;

--Remove duplicates

WITH CTE_DimL
AS
	(SELECT [Postal_Code],[Country], [City], [State], [Region], ROW_NUMBER() OVER(PARTITION BY [Postal_Code],[Country], [City], [State], [Region] ORDER BY [Postal_Code] ASC) AS RowNum
	FROM DimLocation)
DELETE FROM CTE_DimL
WHERE RowNum > 1

--To create DimProduct from Sales Retails table

SELECT * INTO DimProduct
FROM
(SELECT [Product_ID], [Category], [Sub_Category], [Product_Name] FROM [Sales Retail])
AS DimP

--Remove duplicates

WITH CTE_DimP
AS
	(SELECT [Product_ID], [Category], [Sub_Category], [Product_Name], ROW_NUMBER() OVER(PARTITION BY [Product_ID], [Category], [Sub_Category], [Product_Name] ORDER BY [Product_ID] ASC) AS RowNum
	FROM DimProduct)
DELETE FROM CTE_DimP
WHERE RowNum > 1;

---To create a FactTable

SELECT * INTO OrdersFactTable
FROM
(SELECT  
[Order_ID],[Order_Date],[Ship_Date],[Ship_Mode],[Customer_ID],[Postal_Code], [Retail_Sales_People], [Product_ID], [Returned], [Sales], [Quantity], [Discount], [Profit]
FROM [Sales Retail])
AS Ordersfact;

SELECT * FROM OrdersFactTable;

WITH CTE_Ordersfact
AS
	(SELECT [Order_ID],[Order_Date],[Ship_Date],[Ship_Mode],[Customer_ID],[Postal_Code], [Retail_Sales_People], [Product_ID], [Returned], [Sales], [Quantity], [Discount], [Profit], 
	ROW_NUMBER() OVER (PARTITION BY [Order_ID],[Order_Date],[Ship_Date],[Ship_Mode],[Customer_ID],[Postal_Code], [Retail_Sales_People], [Product_ID], [Returned], [Sales], [Quantity], [Discount], [Profit] ORDER BY [Order_ID] ASC) AS RowNum
	FROM OrdersFactTable) 
DELETE FROM CTE_Ordersfact
WHERE RowNum > 1

SELECT * FROM DimProduct
WHERE Product_ID = 'FUR-FU-10004091';

--Remove Duplicates from Product_ID table from a specific table

WITH DuplicateCTE 
AS 
	(SELECT *,
        ROW_NUMBER() OVER (PARTITION BY [Product_ID], [Category], [Sub_Category],[Product_Name] ORDER BY Product_ID) AS RowNum
    FROM DimProduct
    WHERE Product_ID = 'FUR-FU-10004091'
)
DELETE FROM DimProduct
WHERE Product_ID IN (
    SELECT Product_ID
    FROM DuplicateCTE)


SELECT * FROM DimProduct
WHERE Product_ID = 'FUR-FU-10004270'

WITH DuplicateCTE 
AS 
	(SELECT *,
        ROW_NUMBER() OVER (PARTITION BY [Product_ID], [Category], [Sub_Category],[Product_Name] ORDER BY Product_ID) AS RowNum
    FROM DimProduct
    WHERE Product_ID = 'FUR-FU-10004270'
)
DELETE FROM DimProduct
WHERE Product_ID IN (
    SELECT Product_ID
    FROM DuplicateCTE)


----Remove all duplicates from DimProduct table
WITH DuplicateRecords AS (
    SELECT
        [Product_ID], [Category], [Sub_Category],[Product_Name],
        ROW_NUMBER() OVER (PARTITION BY [Product_ID] ORDER BY Product_ID) AS RowNUM
    FROM DimProduct
)
DELETE FROM DimProduct
WHERE Product_ID IN (
    SELECT Product_ID
    FROM DuplicateRecords
    WHERE RowNUM > 1
);


----Remove all duplicates from OrdersFactTable table
WITH DuplicateRecords AS (
    SELECT
        [Order_ID],[Order_Date],[Ship_Date],[Ship_Mode],[Customer_ID],[Postal_Code], [Retail_Sales_People], [Product_ID], [Returned], [Sales], [Quantity], [Discount], [Profit],
        ROW_NUMBER() OVER (PARTITION BY [Order_ID] ORDER BY Order_ID) AS RowNUM
    FROM OrdersFactTable
)
DELETE FROM OrdersFactTable
WHERE Order_ID IN (
    SELECT Order_ID
    FROM DuplicateRecords
    WHERE RowNUM > 1
); 

---to correct conflicting data

SELECT DISTINCT f.Product_ID
FROM OrdersFactTable f
LEFT JOIN DimProduct d ON f.Product_ID = d.Product_ID
WHERE d.Product_ID IS NULL;

DELETE FROM OrdersFactTable
WHERE Product_ID IN (
    SELECT f.Product_ID
    FROM OrdersFactTable f
    LEFT JOIN DimProduct d ON f.Product_ID = d.Product_ID
    WHERE d.Product_ID IS NULL
);

\*---EXPLORATORY ANALYSIS
--1. What was the Average delivery days for different product subcategory?*\

SELECT * FROM [dbo].[OrdersFactTable]
SELECT * FROM DimProduct

SELECT DP.Sub_Category, AVG(DATEDIFF(DAY,OFT.Order_Date, OFT.Ship_Date)) As [Delivery Days]
FROM OrdersFactTable AS OFT
LEFT JOIN DimProduct AS DP ON OFT.Product_ID = DP.Product_ID
GROUP BY DP.Sub_Category;

---\*The analysis indicates that, on average, Chairs take 32 days to deliver, Bookcases 29 days, and both Furnishings and Tables require 34 days*\

---\*2. What was the Average delivery days for each segment ?*\

SELECT [Segment], AVG(DATEDIFF(DAY,Order_Date, Ship_Date)) As [Delivery Days]
FROM [dbo].[Sales Retail]
GROUP BY [Segment]
ORDER BY 2 DESC;

----\*The results indicate that the Corporate segment has the longest average delivery time at 35 days, followed by the Consumer segment with 34 days, while the Home Office segment experiences the shortest delivery time at 31 days. This suggests that corporate orders may involve bulk purchases or additional processing requirements, leading to longer delivery times, whereas home office orders might be smaller and easier to fulfill more quickly*\

-----3.What are the Top 5 Fastest delivered products and Top 5 slowest delivered products?
---*\Top 5 fastest delivery products

SELECT TOP 5 DP.Product_Name, DATEDIFF(DAY,OFT.Order_Date, OFT.Ship_Date) As [Delivery Days]
FROM OrdersFactTable AS OFT
LEFT JOIN DimProduct AS DP 
ON OFT.Product_ID = DP.Product_ID
ORDER BY 2 ASC;

--The data indicates that the following products are delivered immediately—with a delivery time of 0 days: 
--\*1. Eldon Cleatmat Plus Chair Mats for High Pile Carpets
---2. Hon Pagoda Stacking Chairs
---3. Acrylic Self-Standing Desk Frames
---4. Deflect-o EconoMat Studded, No Bevel Mat for Low Pile Carpeting
---5. KI Adjustable-Height Table
---This means these items are available for immediate dispatch, highlighting an efficient delivery process or strong inventory availability*\


---*\Top 5 SLOWEST delivery products

SELECT TOP 5 DP.Product_Name, DATEDIFF(DAY,OFT.Order_Date, OFT.Ship_Date) As [Delivery Days]
FROM OrdersFactTable AS OFT
LEFT JOIN DimProduct AS DP 
ON OFT.Product_ID = DP.Product_ID
ORDER BY 2 DESC;

---4. Which product Subcategory generate most profit?

SELECT DP.Sub_Category, ROUND(SUM(OFT.Profit),0) AS [Total Profits] 
FROM OrdersFactTable AS OFT
LEFT JOIN DimProduct AS DP 
ON OFT.Product_ID = DP.Product_ID
GROUP BY DP.Sub_Category
ORDER BY 2 DESC;

---The product that generated the most profit is Chairs, while Tables and Bookcases didn't generate any profit.

---5. Which segment generates the most profit?

SELECT [Segment], ROUND(SUM(Profit),0) AS [Total Profits] 
FROM [dbo].[Sales Retail]
WHERE Profit > 0
GROUP BY [Segment]
ORDER BY 2 DESC;


---The result shows that consumers generates the most profits

---6. Which Top 5 customers made the most profit?

SELECT TOP 5 DC.Customer_Name, ROUND(SUM(Profit),0) AS [Total Profit]
FROM OrdersFactTable AS OFT
LEFT JOIN DimCustomer AS DC
ON OFT.Customer_ID = DC.Customer_ID
WHERE Profit > 0
GROUP BY DC.Customer_Name
ORDER BY 2 DESC;


---The results shows that the highest customer that generated shows quincy jones with 1013, Laura armstrong with 890, Maria Etezadi with 823, Bill Donatelli with 820, and Brenda Bowman with 772 profits in total.


---7. What is the total number of products by Subcategory?

SELECT Sub_Category, COUNT(Product_Name) AS [Total Product]
FROM DimProduct
GROUP BY Sub_Category
ORDER BY 2 DESC;
--- The result shows that book cases as 48 subcategory, chairs has 87, furnishings has 178, while tables has 34.
