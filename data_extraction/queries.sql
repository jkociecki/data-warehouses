--zadanie 1a
SELECT YEAR(OrderDate) 'Rok', MONTH(OrderDate) 'Miesiac', COUNT(DISTINCT CustomerID) 'Rozni klienci'
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY 1, 2;


--zadanie 1b
SELECT * FROM
(
	SELECT DISTINCT YEAR(OrderDate) 'Rok', MONTH(OrderDate) 'Miesiac', CustomerID 'Rozni_klienci'
	FROM Sales.SalesOrderHeader
) src
PIVOT
(
	COUNT(Rozni_klienci)
	FOR Miesiac IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS pivot_table
ORDER BY Rok;


--zadanie 2
SELECT * FROM
(
	SELECT CONCAT(FirstName, ' ' ,LastName) 'Imie i nazwisko', YEAR(OrderDate) 'rok'
	FROM
		Sales.SalesOrderHeader SOH
		JOIN Person.Person P ON P.BusinessEntityID = SOH.SalesPersonID
) src
PIVOT
(
	COUNT(rok)
	FOR rok IN ([2011], [2012], [2013], [2014])

) pivot_table
WHERE 
	[2011] != 0
	AND [2012] != 0
	AND [2013] != 0
	AND [2014] != 0;


--zadanie 3
SELECT 
    YEAR(OrderDate) AS 'Rok', 
    MONTH(OrderDate) AS 'Miesiac', 
    DAY(OrderDate) AS 'Dzien', 
    CAST(ROUND(SUM(LineTotal), 2) AS DECIMAL(10,2)) AS 'Suma', 
    COUNT(DISTINCT ProductID) AS 'Liczba roznych produktow'
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DAY(OrderDate)
ORDER BY 1, 2, 3;




--zadanie 4

SELECT 	
    MONTH(OrderDate) AS 'Miesiac', 
    CASE DATEPART(weekday, OrderDate)
        WHEN 1 THEN 'Niedziela'
        WHEN 2 THEN 'Poniedziałek'
        WHEN 3 THEN 'Wtorek'
        WHEN 4 THEN 'Środa'
        WHEN 5 THEN 'Czwartek'
        WHEN 6 THEN 'Piątek'
        WHEN 7 THEN 'Sobota'
    END AS 'Dzien tygodnia',
    CAST(ROUND(SUM(LineTotal), 2) AS DECIMAL(10,2)) AS 'Suma', 
    COUNT(DISTINCT ProductID) AS 'Liczba roznych produktow'
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY MONTH(OrderDate), DATEPART(weekday, OrderDate)
ORDER BY 1, 2;


-- zadanie 5
CREATE TABLE Karty(
	Imie VARCHAR(255),
	Nazwisko VARCHAR(255),
	"Liczba transakcji" int,
	"Laczna kwota transakcji" int,
	"Kolor karty" VARCHAR(255)

);

WITH transakcje AS (
    SELECT SOH.CustomerID, COUNT(SOH.SalesOrderID) AS LiczbaZamowien, SUM(SOH.TotalDue) AS LacznaKwota
    FROM Sales.SalesOrderHeader SOH
    GROUP BY SOH.CustomerID
),

gold AS (
    SELECT SOH.CustomerID, COUNT(SOH.SalesOrderID) AS WiecejNizSrednia
    FROM Sales.SalesOrderHeader SOH
    WHERE SOH.TotalDue > 2.5 * (SELECT AVG(TotalDue) FROM Sales.SalesOrderHeader)
    GROUP BY SOH.CustomerID
),

plat AS (
    SELECT SOH.CustomerID, COUNT(DISTINCT SOH.SalesOrderID) AS LiczbaPelnychZamowien
    FROM Sales.SalesOrderHeader SOH
    JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
    JOIN Production.Product P ON SOD.ProductID = P.ProductID
    JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
    JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
    GROUP BY SOH.CustomerID, SOH.SalesOrderID
    HAVING COUNT(DISTINCT PC.ProductCategoryID) = (SELECT COUNT(*) FROM Production.ProductCategory)
)

INSERT INTO Karty (Imie, Nazwisko, "Liczba transakcji", "Laczna kwota transakcji", "Kolor karty")
SELECT 
    P.FirstName AS Imie,
    P.LastName AS Nazwisko,
    T.LiczbaZamowien,
    T.LacznaKwota,
    CASE
        WHEN T.LiczbaZamowien >= 4 AND G.WiecejNizSrednia >= 2 AND P2.LiczbaPelnychZamowien >= 1 THEN 'Platynowa'
        WHEN T.LiczbaZamowien >= 4 AND G.WiecejNizSrednia >= 2 THEN 'Zlota'
        WHEN T.LiczbaZamowien >= 2 THEN 'Srebrna'
        ELSE 'Brak'
    END AS "Kolor karty"
FROM transakcje T
LEFT JOIN gold G ON T.CustomerID = G.CustomerID
LEFT JOIN plat P2 ON T.CustomerID = P2.CustomerID
JOIN Person.Person P ON T.CustomerID = P.BusinessEntityID;

SELECT *
FROM Karty
WHERE [Kolor karty] = 'Zlota'
ORDER BY Imie, Nazwisko;


