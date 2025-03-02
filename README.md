# North American Sales
## Overview
North America Retail is a major retail company operating in multiple locations, offering a wide range of products to different customer groups. The company prioritizes excellent customer service and a smooth shopping experience.
This project analyzes sales data to uncover key insights on profitability, business performance, products, and customer behavior. 

## Objectives
The key objectives of this study are:
1. To analyze the average delivery days for different product subcategories.
2. To determine the average delivery days for each customer segment.
3. To identify the top 5 fastest and slowest delivered products.
4. To find out which product subcategory generates the most profit.
5. To analyze which customer segment generates the most profit.
6. To identify the top 5 customers contributing to the highest profits.
7. To count the total number of products by subcategory.

## Data Sources
The dataset originates from North American retail transactions .csv file and consists of sales records for different customers, and product categories. 

## Tools Used
SQL Server for Data extraction, transformation, and analysis

## Data Integration and Normalization
To ensure efficiency, I transformed the raw dataset into a star schema with:

### Fact Table:
**OrdersFactTable:** Contains sales, profit, and delivery details.
To create a Fact table
```sql code
SELECT * INTO OrdersFactTable
FROM
(SELECT  
[Order_ID],[Order_Date],[Ship_Date],[Ship_Mode],[Customer_ID],[Postal_Code], [Retail_Sales_People], [Product_ID], [Returned], [Sales], [Quantity], [Discount], [Profit]
FROM [Sales Retail])
AS Ordersfact;

SELECT * FROM OrdersFactTable;
```
### Dimension Tables:
**dimCustomers**: Customer details (ID, segment, region, etc.).
```sql code
SELECT * INTO DimCustomer
FROM
(SELECT Customer_ID, Customer_Name FROM [Sales Retail])
AS DimC
```

**dimProducts**: Product details (ID, category, subcategory, etc.).
```sql code
SELECT * INTO DimProduct
FROM
(SELECT [Product_ID], [Category], [Sub_Category], [Product_Name] FROM [Sales Retail])
AS DimP
```

**dimCalendar:** Date details (Year, Month, Day, etc.).
imported a csv file including the calendar date

**dimLocation:** Store location details.
```sql code
SELECT * INTO DimLocation
FROM
(SELECT [Postal_Code],[Country], [City], [State], [Region] FROM [Sales Retail])
AS DimL

SELECT * FROM DimLocation;
```
I ensured data consistency and accuracy by:
1. Removing redundant information
2. Using unique keys for dimensions
3. Normalizing tables to improve query performance

## Data Cleaning Process in SQL
The data cleaning process involves:
1. Handling missing values
2. Removing duplicate records using the Common Table Expressions (CTE)
3. Standardizing data formats
4. Correcting inconsistencies in product and customer records
5. Ensuring foreign key relationships between tables

## OrdersFacttable Data Cleaning 
```sql code
WITH CTE_Ordersfact
AS
	(SELECT [Order_ID],[Order_Date],[Ship_Date],[Ship_Mode],[Customer_ID],[Postal_Code], [Retail_Sales_People], [Product_ID], [Returned], [Sales], [Quantity], [Discount], [Profit], 
	ROW_NUMBER() OVER (PARTITION BY [Order_ID],[Order_Date],[Ship_Date],[Ship_Mode],[Customer_ID],[Postal_Code], [Retail_Sales_People], [Product_ID], [Returned], [Sales], [Quantity], [Discount], [Profit] ORDER BY [Order_ID] ASC) AS RowNum
	FROM OrdersFactTable) 
DELETE FROM CTE_Ordersfact
WHERE RowNum > 1
```
#### Findings: Only 1 row was affected

## Dimensiontables Data Cleaning
### DimCustomer
``` sql code
WITH CTE_DimC
AS
	(SELECT Customer_ID, Customer_Name, ROW_NUMBER() OVER(PARTITION BY Customer_ID, Customer_Name ORDER BY Customer_ID ASC) AS RowNum
	FROM DimCustomer)
DELETE FROM CTE_DimC
WHERE RowNum > 1;
```
### DimProducts
```sql code
WITH CTE_DimP
AS
	(SELECT [Product_ID], [Category], [Sub_Category], [Product_Name], ROW_NUMBER() OVER(PARTITION BY [Product_ID], [Category], [Sub_Category], [Product_Name] ORDER BY [Product_ID] ASC) AS RowNum
	FROM DimProduct)
DELETE FROM CTE_DimP
WHERE RowNum > 1;
```
### DimLocation
```sql code
WITH CTE_DimL
AS
	(SELECT [Postal_Code],[Country], [City], [State], [Region], ROW_NUMBER() OVER(PARTITION BY [Postal_Code],[Country], [City], [State], [Region] ORDER BY [Postal_Code] ASC) AS RowNum
	FROM DimLocation)
DELETE FROM CTE_DimL
WHERE RowNum > 1
```

## Creating Relationships using Database Diagrams
Created a star schema to link the Primary Key from the Ordersfacttable to the Dimensions table. 
Below is the view of the relationship

<img width="731" alt="Screenshot 2025-02-23 235334" src="https://github.com/user-attachments/assets/6ecb6277-940f-45a1-ae66-265e8b0818cf" />

## Exploratory Data Analysis (EDA)
I conducted an in-depth analysis using SQL and Python to answer the business questions outlined in our objectives.
### Key Insights:
#### 1. What is the average delivery days for different product subcategories?
``` sql code
SELECT * FROM [dbo].[OrdersFactTable]
SELECT * FROM DimProduct

SELECT DP.Sub_Category, AVG(DATEDIFF(DAY,OFT.Order_Date, OFT.Ship_Date)) As [Delivery Days]
FROM OrdersFactTable AS OFT
LEFT JOIN DimProduct AS DP ON OFT.Product_ID = DP.Product_ID
GROUP BY DP.Sub_Category;
```
<img width="755" alt="Screenshot 2025-02-24 000228" src="https://github.com/user-attachments/assets/1445aa05-bd20-4c5b-a1b9-a81bc6d1e488" />

<img width="749" alt="Screenshot 2025-02-24 000738" src="https://github.com/user-attachments/assets/19d74322-b753-40d5-9242-317e7bcf6717" />

### **Findings**: 
The analysis indicates that, on average, Chairs take 32 days to deliver, Bookcases 29 days, and both Furnishings and Tables require 34 days

#### 2. What is the average delivery days for each customer segment.
```sql code
SELECT [Segment], AVG(DATEDIFF(DAY,Order_Date, Ship_Date)) As [Delivery Days]
FROM [dbo].[Sales Retail]
GROUP BY [Segment]
ORDER BY 2 DESC;
```
<img width="759" alt="Screenshot 2025-02-24 001658" src="https://github.com/user-attachments/assets/457b7560-d0f9-400b-9091-e3cc5dd314e6" />

### Findings: 
The results indicate that the Corporate segment has the longest average delivery time at 35 days, followed by the Consumer segment with 34 days, while the Home Office segment experiences the shortest delivery time at 31 days. This suggests that corporate orders may involve bulk purchases or additional processing requirements, leading to longer delivery times, whereas home office orders might be smaller and easier to fulfill more quickly

#### 3. To identify the top 5 fastest and slowest delivered products.
##### Top 5 fastest delivered products
```sql code
SELECT TOP 5 DP.Product_Name, DATEDIFF(DAY,OFT.Order_Date, OFT.Ship_Date) As [Delivery Days]
FROM OrdersFactTable AS OFT
LEFT JOIN DimProduct AS DP 
ON OFT.Product_ID = DP.Product_ID
ORDER BY 2 ASC;
```
<img width="757" alt="Screenshot 2025-02-24 002301" src="https://github.com/user-attachments/assets/9c87df44-ac48-4c3c-8a96-83fa5dcd40bc" />

### Findings
The data reveals that certain products are delivered immediately, with a 0-day delivery time, indicating a highly efficient distribution system. These products include Eldon Cleatmat Plus Chair Mats for High Pile Carpets, Hon Pagoda Stacking Chairs, Acrylic Self-Standing Desk Frames, Deflect-o EconoMat Studded No Bevel Mat for Low Pile Carpeting, and KI Adjustable-Height Table. The immediate dispatch of these items suggests a well-optimized inventory management system, ensuring that these products are consistently in stock and readily available for shipment. This efficiency may be due to strong supplier relationships, strategic warehousing, or automated order fulfillment processes, ultimately enhancing customer satisfaction and operational performance.

##### Top 5 SLOWEST delivery products
``` sql code
SELECT TOP 5 DP.Product_Name, DATEDIFF(DAY,OFT.Order_Date, OFT.Ship_Date) As [Delivery Days]
FROM OrdersFactTable AS OFT
LEFT JOIN DimProduct AS DP 
ON OFT.Product_ID = DP.Product_ID
ORDER BY 2 DESC;
```
<img width="754" alt="Screenshot 2025-02-24 002322" src="https://github.com/user-attachments/assets/bea73e62-b786-4a9d-9b3c-67835571f85e" />

#### 4. To find out which product subcategory generates the most profit.
```sql code
SELECT DP.Sub_Category, ROUND(SUM(OFT.Profit),0) AS [Total Profits] 
FROM OrdersFactTable AS OFT
LEFT JOIN DimProduct AS DP 
ON OFT.Product_ID = DP.Product_ID
GROUP BY DP.Sub_Category
ORDER BY 2 DESC;
```
<img width="374" alt="Screenshot 2025-02-24 002832" src="https://github.com/user-attachments/assets/01f81a48-6175-4ef2-8c96-387e1dda66de" />

### FIndings:
The product that generated the most profit is Chairs, while Tables and Bookcases didn't generate any profit.

#### 5. To analyze which customer segment generates the most profit.
```sql code
SELECT [Segment], ROUND(SUM(Profit),0) AS [Total Profits] 
FROM [dbo].[Sales Retail]
WHERE Profit > 0
GROUP BY [Segment]
ORDER BY 2 DESC;
```
<img width="755" alt="Screenshot 2025-02-24 002843" src="https://github.com/user-attachments/assets/350f2c60-28ae-4036-8db4-c299970408e4" />

### Findings:
The result shows that consumers generates the most profits

### 6. To identify the top 5 customers contributing to the highest profits.
``` sql code
SELECT TOP 5 DC.Customer_Name, ROUND(SUM(Profit),0) AS [Total Profit]
FROM OrdersFactTable AS OFT
LEFT JOIN DimCustomer AS DC
ON OFT.Customer_ID = DC.Customer_ID
WHERE Profit > 0
GROUP BY DC.Customer_Name
ORDER BY 2 DESC;
```
<img width="574" alt="Screenshot 2025-02-24 003343" src="https://github.com/user-attachments/assets/245edbec-82b1-410b-bc46-503c492d5167" />

### Findings:
The results shows that the highest customer that generated shows quincy jones with 1013, Laura armstrong with 890, Maria Etezadi with 823, Bill Donatelli with 820, and Brenda Bowman with 772 profits in total.

### 7. To count the total number of products by subcategory.
``` sql code
SELECT Sub_Category, COUNT(Product_Name) AS [Total Product]
FROM DimProduct
GROUP BY Sub_Category
ORDER BY 2 DESC;
```
<img width="754" alt="Screenshot 2025-02-24 003745" src="https://github.com/user-attachments/assets/28779c0a-528b-436a-90b6-dcf6aad79454" />

### Findings:
The result shows that book cases as 48 subcategory, chairs has 87, furnishings has 178, while tables has 34.


## Conclusion
The exploratory data analysis of North American retail sales provided valuable insights into delivery efficiency, profitability, and customer segmentation. 
1. The findings reveal that delivery times vary significantly across product subcategories, with Chairs and Tables experiencing the longest delays. 
2. The Corporate segment has the highest average delivery time, likely due to bulk orders, while the Home Office segment receives faster deliveries.
3. Certain products are delivered immediately, indicating an optimized supply chain.
4. Profitability analysis shows that Chairs generate the most revenue, while Tables and Bookcases struggle to be profitable.
5. Additionally, Consumers contribute the highest profit margin, highlighting their importance in the market.
6. Finally, specific high-value customers drive significant revenue, reinforcing the need for targeted customer relationship management.

## Recommendations
Based on the insights, the following are the recommendations;
1. The company should collaborate more effectively with suppliers and improve inventory management to minimize delays in delivering Chairs, Tables, and Bookcases.
2. The company should maintain a steady supply of products with 0-day delivery time to sustain efficiency and customer satisfaction.
3. Personalized sales strategies should be implemented for top-performing customers, such as Quincy Jones and Laura Armstrong, to foster loyalty and increase profitability.
4. Cross-bundling sales strategies should be implemented to improve the performance of underperforming items.
5. There is a need to create special promotions, offers, and loyalty programs to attract and retain high-profit customers.
   
