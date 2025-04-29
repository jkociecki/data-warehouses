--zadanie 1
SELECT
	COALESCE(CONCAT(Person.FirstName, ' ', Person.LastName), '')'FullName',
    COALESCE(CAST(YEAR(OrderDate) AS VARCHAR), '') AS OrderYear,
    SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
JOIN Sales.Customer ON Customer.CustomerID = SalesOrderHeader.CustomerID
JOIN Person.Person ON Person.BusinessEntityID = Customer.PersonID
GROUP BY 
    CUBE(CONCAT(Person.FirstName, ' ', Person.LastName), YEAR(OrderDate))
ORDER BY 
    1, 2 DESC;



SELECT
	COALESCE(CONCAT(Person.FirstName, ' ', Person.LastName), '')'FullName',
    COALESCE(CAST(YEAR(OrderDate) AS VARCHAR), '') AS OrderYear,
    SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
JOIN Sales.Customer ON Customer.CustomerID = SalesOrderHeader.CustomerID
JOIN Person.Person ON Person.BusinessEntityID = Customer.PersonID
GROUP BY GROUPING SETS
    (
		(CONCAT(Person.FirstName, ' ', Person.LastName)),
        (YEAR(OrderDate), CONCAT(Person.FirstName, ' ', Person.LastName))
    )
ORDER BY 
    1, 2 DESC;



SELECT
	COALESCE(CONCAT(Person.FirstName, ' ', Person.LastName), '')'FullName',
    COALESCE(CAST(YEAR(OrderDate) AS VARCHAR), '') AS OrderYear,
    SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
JOIN Sales.Customer ON Customer.CustomerID = SalesOrderHeader.CustomerID
JOIN Person.Person ON Person.BusinessEntityID = Customer.PersonID
GROUP BY 
    ROLLUP (CONCAT(Person.FirstName, ' ', Person.LastName), YEAR(OrderDate))
ORDER BY 
    1, 2 DESC;

-- zadanie 1.2
SELECT 
    PC.Name AS Kategoria, 
    P.Name AS Produkt, 
    COALESCE(CAST(YEAR(SOH.OrderDate) AS VARCHAR), '') AS Rok, 
    SUM(SOD.LineTotal * SOD.UnitPriceDiscount) AS Kwota
FROM 
	Sales.SalesOrderHeader SOH 
	JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
	JOIN Production.Product P ON SOD.ProductID = P.ProductID
	JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
	JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY GROUPING SETS (
    (PC.Name, P.Name, YEAR(SOH.OrderDate)),
	(PC.Name, P.Name)
)
ORDER BY PC.Name, P.Name, Rok DESC;

SELECT 
    YEAR(SOH.OrderDate) AS Rok, 
    COALESCE(PC.Name, '') AS Kategoria,
    SUM(SOD.OrderQty * SOD.UnitPrice * SOD.UnitPriceDiscount) AS Kwota_znizek
FROM 
    Sales.SalesOrderHeader SOH 
    JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
    JOIN Production.Product P ON SOD.ProductID = P.ProductID
    JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
    JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY ROLLUP(YEAR(SOH.OrderDate), PC.Name)
ORDER BY Rok;

-- zadanie 2.1
SELECT
    *,
    SUM("w miesiacu") OVER (
        PARTITION BY "Imię i nazwisko",
		Rok
		ORDER BY Miesiac ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) 'obecny i poprzedni miesiac'
FROM
    (
        SELECT
            DISTINCT CONCAT(per.FirstName, ' ', per.LastName) "Imię i nazwisko",
            YEAR(soh.OrderDate) Rok,
            MONTH(soh.OrderDate) Miesiac,
            COUNT(soh.SalesOrderID) OVER (
                PARTITION BY CONCAT(per.FirstName, ' ', per.LastName),
                YEAR(soh.OrderDate),
                MONTH(soh.OrderDate)
            ) "w miesiacu",

            COUNT(soh.SalesOrderID) OVER (
                PARTITION BY CONCAT(per.FirstName, ' ', per.LastName),
                YEAR(soh.OrderDate)
            ) "w roku",

            COUNT(soh.SalesOrderID) OVER (
                PARTITION BY CONCAT(per.FirstName, ' ', per.LastName),
                YEAR(soh.OrderDate)
                ORDER BY
                    MONTH(soh.OrderDate) RANGE BETWEEN UNBOUNDED PRECEDING
                    AND CURRENT ROW
            ) "w roku narastająco"
        FROM
            Sales.SalesOrderHeader soh
            JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
            JOIN HumanResources.Employee E ON sp.BusinessEntityID = E.BusinessEntityID
            JOIN Person.Person per ON per.BusinessEntityID = E.BusinessEntityID
    ) AS Sprzedawcy
ORDER BY
    1, 2, 3;

-- zadanie 2.2
SELECT
	*
FROM
	(
		SELECT 
			PC.Name 'Kategoria',
			YEAR(SOH.OrderDate) 'Rok',
			ROUND(
				SUM(SOH.TotalDue) OVER(PARTITION BY PC.Name, YEAR(SOH.OrderDate)) * 100 / SUM(SOH.TotalDue) OVER(Partition BY PC.Name),
				2
			) 'Procent'
		FROM
			Production.Product P
			JOIN Sales.SalesOrderDetail SOD ON P.ProductID = SOD.ProductID
			JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
			JOIN Production.ProductCategory PC ON PC.ProductCategoryID = PS.ProductCategoryID
			JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
		WHERE
			PC.Name IN ('Accessories', 'Bikes', 'Components', 'Clothing')
	) AS src
PIVOT
	(
		MAX(Procent)
		FOR Rok IN ([2011], [2012], [2013], [2014])
	
	) AS pvot_table
ORDER BY 1;


--zadanie 2.3
SELECT 
	CONCAT(P.FirstName, ' ', P.LastName) 'Full Name',
	RANK() OVER (ORDER BY SUM(SOD.OrderQty) DESC) 'rank',
	DENSE_RANK() OVER (ORDER BY SUM(SOD.OrderQty) DESC) 'dense_rank'
FROM
	Sales.SalesOrderHeader SOH
	JOIN SAles.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
	JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID
	JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
GROUP BY 	CONCAT(P.FirstName, ' ', P.LastName);


-- zadanie 2.4
SELECT
	produkt 'produkt',
	DENSE_RANK() OVER( ORDER BY srednia DESC) 'miejsce',
	CASE NTILE(3) OVER (ORDER BY srednia DESC)
		WHEN 1 THEN 'najlepiej' WHEN 2 then 'srednio' WHEN 3 THEN 'najslabiej'
	END 'Grupa'
FROM
	(
		SELECt DISTINCT 
			P.Name 'produkt',
			AVG(CAST(SOD.OrderQty AS FLOAT)) OVER (PARTITION BY SOD.ProductID) 'srednia'
		FROM
			Sales.SalesOrderDetail SOD
			JOIN Production.Product P ON SOD.ProductID = P.ProductID
	) AS prd;













