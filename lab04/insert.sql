

INSERT INTO KOCIECKI.DIM_CUSTOMER (
    CustomerID,
    FirstName,
    LastName,
    Title,
    City,
    TerritoryName,
    CountryRegionCode,
    [Group]
)
SELECT DISTINCT
    C.CustomerID,
    P.FirstName,
    P.LastName,
    P.Title,
    A.City,
    T.[Name],
    T.CountryRegionCode,
    T.[Group]
FROM Sales.Customer C
JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
JOIN Sales.SalesTerritory T ON C.TerritoryID = T.TerritoryID
JOIN Sales.SalesOrderHeader SOH ON C.CustomerID = SOH.CustomerID
JOIN Person.Address A ON A.AddressID = SOH.ShipToAddressID;


INSERT INTO KOCIECKI.DIM_PRODUCT
SELECT
	P.ProductID,
	P.Name,
	P.ListPrice,
	P.Color,
	PS.Name,
	PC.Name,
	P.Weight,
	P.Size,
	~P.MakeFlag
FROM
	Production.Product P
	LEFT JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
	LEFT JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID;


INSERT INTO KOCIECKI.DIM_SALESPERSON
SELECT 
    sp.BusinessEntityID AS SalesPersonID, 
    p.FirstName, 
    p.LastName, 
    p.Title, 
    e.Gender, 
    st.CountryRegionCode, 
    st.[Group]
FROM Sales.SalesPerson sp
LEFT JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
LEFT JOIN HumanResources.Employee e ON  p.BusinessEntityID = e.BusinessEntityID
LEFT JOIN Sales.SalesTerritory st ON sp.TerritoryID = st.TerritoryID;

INSERT INTO KOCIECKI.FACT_SALES 
(ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate, OrderQty, UnitPrice, UnitPriceDiscount, LineTotal)
SELECT 
    sod.ProductId,
    soh.CustomerID,
    soh.SalesPersonID,
    DATEPART(YYYY, soh.OrderDate) * 10000 + DATEPART(M, soh.OrderDate) * 100 + DATEPART(D, soh.OrderDate),
    DATEPART(YYYY, soh.ShipDate) * 10000 + DATEPART(M, soh.ShipDate) * 100 + DATEPART(D, soh.ShipDate),
    sod.OrderQty,
    sod.UnitPrice,
    sod.UnitPriceDiscount,
    sod.LineTotal
FROM Sales.SalesOrderHeader soh 
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID;