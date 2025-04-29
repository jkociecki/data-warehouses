--zadanie 1
SELECT COUNT(*) 'l. produktow'
FROM Production.Product;

SELECT COUNT(*) 'l. kategorii'
FROM Production.ProductCategory;

SELECT COUNT(*) 'l. podkategorii'
FROM Production.ProductSubcategory;


--zadanie 2
SELECT ProductID, Name, Color
FROM Production.Product
WHERE Color IS NULL;


--zadanie 3
SELECT YEAR(OrderDate) "Year", SUM(TotalDue) "Sum"
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY 1 DESC;

-- zadanie 4

SELECT T.Name "Territory", COUNT(*) "Customers"
FROM 
	Sales.Customer C JOIN Sales.SalesTerritory T
	ON C.TerritoryID = T.TerritoryID
GROUP BY T.Name
UNION ALL
SELECT 'Total Sum', COUNT(*)
FROM Sales.Customer;


SELECT T.Name "Territory", COUNT(*) "Sales"
FROM Sales.SalesPerson C LEFT JOIN Sales.SalesTerritory T
ON C.TerritoryID = T.TerritoryID
GROUP BY T.Name
UNION ALL
SELECT 'Total sum', COUNT(*)
FROM Sales.SalesPerson;


-- zadanie 5
SELECT YEAR(OrderDate) AS 'Year', COUNT(*) AS 'Transactions'
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate);

-- zadanie 6
SELECT C.Name, SC.Name, P.Name
FROM 
	Production.Product P 
	LEFT JOIN Sales.SalesOrderDetail SOD ON P.ProductID = SOD.ProductID
	LEFT JOIN Production.ProductSubcategory SC ON P.ProductSubcategoryID = SC.ProductSubcategoryID
	LEFT JOIN Production.ProductCategory C ON SC.ProductCategoryID = C.ProductCategoryID
WHERE SOD.SalesOrderID IS NULL
GROUP BY C.Name, SC.Name, P.Name;


-- zadanie 7
SELECT SC.Name, 
	MIN(SOD.UnitPriceDiscount * P.ListPrice) "Min", 
	MAX(SOD.UnitPriceDiscount * P.ListPrice) "Max"
FROM 
	Sales.SalesOrderDetail SOD
	JOIN Production.Product P ON SOD.ProductID = P.ProductID
	RIGHT JOIN Production.ProductSubcategory SC ON P.ProductSubcategoryID = SC.ProductSubcategoryID
WHERE
	SOD.UnitPriceDiscount != 0
GROUP BY SC.Name;


-- zadanie 8
SELECT P.Name, P.ListPrice
FROM Production.Product P
WHERE P.ListPrice > 
	(SELECT AVG(ListPrice) FROM Production.Product)
ORDER BY 2;

SELECT AVG(ListPrice) FROM Production.Product;

-- zadanie 9
SELECT MONTH(SOH.OrderDate) "Month",
		C.Name "Name" , 
		SUM(SOD.OrderQty) / COUNT(DISTINCT SOH.SalesOrderID) "avg"
FROM	
	Sales.SalesOrderDetail SOD
	JOIN Production.Product P ON SOD.ProductID = P.ProductID
	JOIN Production.ProductSubcategory SC ON P.ProductSubcategoryID = SC.ProductSubcategoryID
	JOIN Production.ProductCategory C ON SC.ProductCategoryID = C.ProductCategoryID
	JOIN Sales.SalesOrderHeader SOH ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY  MONTH(SOH.OrderDate), C.Name
ORDER BY 1, 2;


-- zadanie 10
SELECT 
	ST.CountryRegionCode, 
	AVG(DATEDIFF(DAY, SOH.OrderDate, SOH.ShipDate)) AS AverageDays
FROM 
    Sales.SalesOrderHeader SOH
    JOIN Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
GROUP BY ST.CountryRegionCode;


SELECT expierence, AVG(count), AVG(avg)
FROM
	(

	SELECT
		SalesPersonID,
		DATEDIFF(YEAR, HireDate, SYSDATETIME()) AS 'expierence',
		COUNT(*) AS 'count',
		(CAST(AVG(TotalDue)) AS FLOAT AS) 'avg'
	FROM 
		Sales.SalesPerson SP
		JOIN HumanResources.Employee E ON SP.BusinessEntityID = E.BusinessEntityID
		JOIN Sales.SalesOrderHeader SOH ON SP.BusinessEntityID = SOH.SalesPersonID
	GROUP BY SalesPersonID, DATEDIFF(YEAR, HireDate, SYSDATETIME())

	) AS sub
GROUP BY expierence;


SELECT * FROM
Sales.SalesPerson;


SELECT MAX(MONTH(OrderDate))
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2014;