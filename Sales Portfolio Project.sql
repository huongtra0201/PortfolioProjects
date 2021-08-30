--DATA TYPES FUNCTIONs
/*Calculate age of each Employee when they are hired. (HireDate - BirthDate)
Calculate age of each Employee today.
Get user name of each employee. Username is last part of login ID: adventure-works\jun0 -> 
Username = jun0
*/
SELECT FirstName, LastName, BirthDate, HireDate,
datediff(year,BirthDate, HireDate) as age_when_hired,
datediff(year,BirthDate, current_timestamp) as today_age,
LoginID,
SUBSTRING (LoginID, CHARINDEX('\', LoginID)+1, 30) AS user_name1, -- CÁCH 1
STUFF (LoginID,1,CHARINDEX('\', LoginID),NULL) AS user_name2,-- CÁCH 2
STUFF (REPLACE (LoginID,'adventure-works\',0),1,1,NULL) AS user_name3,-- CÁCH 3
RIGHT(LoginID,(LEN (LoginID) - CHARINDEX('\', LoginID))) AS user_name4-- CÁCH 4 
FROM DimEmployee

-- OUTER JOINs, UNION

/*Displaying the Product key,EnglishProductName, and Color columns from rows in the dbo.DimProduct table 
which has EnglishProductSubCategoryName is 'Mountain Bikes'.
and ListPrice > 1000*/
SELECT ProductKey,
EnglishProductName,
Color
FROM DimProduct
LEFT JOIN DimProductSubcategory
ON DimProduct.ProductSubcategoryKey = DimProductSubcategory.ProductSubcategoryKey 
WHERE EnglishProductSubCategoryName = 'Mountain Bikes'
AND ListPrice > 1000

/*Find all SalesOrderNumber which EnglishProductName contains 'Road' in name and Color is Yellow */
SELECT SalesOrderNumber, 'FIS' as type 
FROM FactInternetSales FIS
LEFT JOIN DimProduct DP 
ON FIS.ProductKey = DP.ProductKey
WHERE EnglishProductName LIKE '%Road%'
AND Color = 'Yellow'
UNION
SELECT SalesOrderNumber, 'RSLS' as type 
FROM FactResellerSales FRS
LEFT JOIN DimProduct DP 
ON FRS.ProductKey = DP.ProductKey
WHERE EnglishProductName LIKE '%Road%'
AND Color = 'Yellow'

/* Displaying the SalesOrderNumber, SalesOrderLineNumber, ProductKey, Quantity, EnglishProductName, 
Color, EnglishProductCategoryName
where SalesReasonReasonType is 'Marketing' 
and EnglishProductSubcategoryName contains 'Bikes' */
SELECT FIS.SalesOrderNumber,
FIS.SalesOrderLineNumber,
FIS.ProductKey, 
OrderQuantity,
EnglishProductName,
Color
FROM FactInternetSales AS FIS
LEFT JOIN FactInternetSalesReason FISR
ON FIS.SalesOrderNumber = FISR.SalesOrderNumber AND FIS.SalesOrderLineNumber = FISR.SalesOrderLineNumber
LEFT JOIN DimSalesReason AS DSR ON FISR. SalesReasonKey = DSR. SalesReasonKey
LEFT JOIN DimProduct AS DP ON FIS. ProductKey = DP. ProductKey
LEFT JOIN DimProductSubcategory AS PS ON DP.ProductSubcategoryKey = PS.ProductSubcategoryKey 
LEFT JOIN DimProductCategory AS PC ON PC.ProductCategoryKey = PS.ProductCategoryKey
WHERE SalesReasonReasonType = 'Marketing'
AND EnglishProductSubcategoryName LIKE '%Bikes%'

/*Display ProductKey, EnglishProductName of products which never have been ordered and 
ProductCategory is 'Bikes'*/
SELECT DP.ProductKey,
EnglishProductName
FROM FactInternetSales AS FIS
RIGHT JOIN DimProduct AS DP ON FIS.ProductKey = DP.ProductKey
WHERE DP.ProductKey NOT IN
(select distinct ProductKey from FactInternetSales) 
AND DP.ProductKey IN ( 
select ProductKey
from DimProduct AS DP
left join DimProductSubcategory AS PS on DP.ProductSubcategoryKey = PS.ProductSubcategoryKey 
left join DimProductCategory AS PC on PC.ProductCategoryKey = PS.ProductCategoryKey
where EnglishProductCategoryName = 'Bikes')

--SELF JOIN

/*Display DepartmentGroupName and their parent DepartmentGroupName */ 
SELECT EDG.DepartmentGroupKey AS employee_department_gr_key,
EDG.DepartmentGroupName AS employee_department_gr_name,
PDG.DepartmentGroupKey AS parent_department_gr_key,
PDG. DepartmentGroupName AS parent__department_gr_name
FROM DimDepartmentGroup AS EDG
LEFT JOIN DimDepartmentGroup AS PDG
ON EDG.ParentDepartmentGroupKey = PDG.DepartmentGroupKey

--CASE WHEN

/*Create new Color_group, if product color is 'Black' or 'Silver' or 
'Silver/Black' leave 'Basic', else keep Color.
Then Caculate total SalesAmount by new Color_group */
SELECT sum(SalesAmount),
CASE
WHEN Color ='NA' THEN 'Other'
ELSE Color end
FROM FactInternetSales
LEFT JOIN DimProduct on FactInternetSales. ProductKey = DimProduct. ProductKey
GROUP BY CASE
WHEN Color ='NA' THEN 'Other'
ELSE Color end

/*Retrieve saleordernumber,productkey, 
orderdate, shipdate of orders in October 2011, along with sales type ('Resell' or 'Internet')*/
SELECT SalesOrderNumber,
ProductKey,
OrderDate,
ShipDate,
'Internet' as Sale_type
FROM FactInternetsales
WHERE month(ShipDate) = 10 and year(ShipDate) = 2011 
UNION
SELECT SalesOrderNumber,
ProductKey,
OrderDate,
ShipDate,
'Resell' as Sale_type
FROM FactResellerSales
WHERE month(ShipDate) = 10 and year(ShipDate) = 2011

--CTEs

/*Display ProductKey, EnglishProductName, Total OrderQuantity (caculate from 
OrderQuantity in Quarter 3 of 2013) 
of product sold in London for each Sales type ('Resell' and 'Internet')*/
WITH FactSales AS
 (SELECT ProductKey,
 'Internet' AS sales_type,
 OrderQuantity,
 OrderDate,
 SalesTerritoryKey
 FROM FactInternetSales AS Sales
 UNION 
 SELECT FactResellerSales.ProductKey,
 'Reseller' AS sales_type,
 OrderQuantity,
 OrderDate,
 SalesTerritoryKey
 FROM FactResellerSales)
 
SELECT sales_type,
Product.ProductKey,
EnglishProductName,
SUM(OrderQuantity) AS 'Total OrderQuantity'
FROM FactSales
LEFT JOIN DimProduct Product ON FactSales.ProductKey = Product.ProductKey
LEFT JOIN DimSalesTerritory Ter ON Ter.SalesTerritoryKey = FactSales.SalesTerritoryKey
LEFT JOIN DimGeography Geo ON Geo.SalesTerritoryKey = Ter.SalesTerritoryKey 
WHERE YEAR(OrderDate) = 2013
AND MONTH(OrderDate) BETWEEN 7 AND 9
AND Geo.City = 'London'
GROUP BY sales_type,
 Product.ProductKey,
 EnglishProductName
ORDER BY sales_type,
 Product.ProductKey,
 EnglishProductName

/*Retrieve total SalesAmount monthly of internet_sales and reseller_sales. */
WITH Internet_sales_by_day AS
 ( SELECT OrderDateKey ,
 SUM(SalesAmount) AS Internet_Sale_amount
 FROM FactInternetSales
 GROUP BY OrderDateKey),
 Reseller_sales_by_day AS
 (SELECT OrderDateKey,
 SUM(SalesAmount) AS Reseller_Sale_amount
 FROM FactResellerSales
 GROUP BY OrderDateKey)

SELECT YEAR(FullDateAlternateKey) AS calendar_year,
MONTH(FullDateAlternateKey) AS calendar_month,
Sum(FIS.Internet_Sale_amount) AS internet_sales,
SUM (FRS.Reseller_Sale_amount) AS reseller_sales
FROM DimDate AS D2
LEFT JOIN Internet_sales_by_day AS FIS ON FIS.OrderDateKey = D2.DateKey
LEFT JOIN Reseller_sales_by_day AS FRS ON FRS.OrderDateKey = D2.DateKey
GROUP BY YEAR(FullDateAlternateKey),
MONTH(FullDateAlternateKey)
ORDER BY calendar_year DESC,calendar_month

--WINDOW FUNCTIONs

/*Find out 5 transactions with highest SalesAmount by month in InternetSales tables*/
WITH Sales_by_month AS (
SELECT SalesOrderNumber,
year(OrderDate) as year,
month(OrderDate) as month,
sum(SalesAmount) as total_sales,
ROW_NUMBER() OVER (PARTITION BY year(OrderDate), month(OrderDate) ORDER 
BY sum(SalesAmount) DESC ) as row_num
from FactInternetSales
GROUP BY SalesOrderNumber, Year(OrderDate), month(OrderDate) 
) 
SELECT * 
FROM Sales_by_month
WHERE row_num <=5
