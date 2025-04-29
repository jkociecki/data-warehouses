USE AdventureWorks2019;
GO
INSERT INTO kociecki.MONTHS_NAMES (month_number, month_name)
VALUES (1, 'styczeń'), 
       (2, 'luty'), 
       (3, 'marzec'), 
       (4, 'kwiecień'),
       (5, 'maj'),
       (6, 'czerwiec'),
       (7, 'lipiec'),
       (8, 'sierpień'),
       (9, 'wrzesień'),
       (10, 'październik'),
       (11, 'listopad'),
       (12, 'grudzień');

USE AdventureWorks2019;
GO
INSERT INTO KOCIECKI.WEEKDAY_NAMES (weekday_number, weekday_name)
VALUES (1, 'poniedziałek'),
       (2, 'wtorek'),
       (3, 'środa'),
       (4, 'czwartek'),
       (5, 'piątek'),
       (6, 'sobota'),
       (7, 'niedziela');


USE AdventureWorks2019;
GO

WITH SourceDates AS (
    SELECT DISTINCT OrderDate AS CalendarDate
    FROM Sales.SalesOrderHeader
    WHERE OrderDate IS NOT NULL
    UNION
    SELECT DISTINCT ShipDate AS CalendarDate
    FROM Sales.SalesOrderHeader
    WHERE ShipDate IS NOT NULL
)
INSERT INTO Kociecki.DIM_TIME (
    PK_TIME,
    Rok,
    Kwartal,
    Miesiac,
    Miesiac_slownie,
    Dzien_tyg_slownie,
    Dzein_miesiaca
)
SELECT
    (DATEPART(year, sd.CalendarDate) * 10000) + (DATEPART(month, sd.CalendarDate) * 100) + DATEPART(day, sd.CalendarDate) AS PK_TIME,
    DATEPART(year, sd.CalendarDate) AS Rok,
    DATEPART(quarter, sd.CalendarDate) AS Kwartal,
    DATEPART(month, sd.CalendarDate) AS Miesiac,
    ISNULL(mn.month_name, 'Unknown') AS Miesiac_slownie,
    ISNULL(wn.weekday_name, 'Unknown') AS Dzien_tyg_slownie,
    DATEPART(day, sd.CalendarDate) AS Dzien_miesiaca
FROM
    SourceDates sd
    LEFT JOIN Kociecki.MONTHS_NAMES mn ON DATEPART(month, sd.CalendarDate) = mn.month_number
    LEFT JOIN Kociecki.WEEKDAY_NAMES wn ON DATEPART(weekday, sd.CalendarDate) = wn.weekday_number;

UPDATE kociecki.DIM_PRODUCT
SET Color = 'UNKNOWN'
WHERE Color IS NULL;

UPDATE kociecki.DIM_PRODUCT
SET SubCategoryName = 'UNKNOWN'
WHERE SubCategoryName IS NULL;

UPDATE kociecki.DIM_CUSTOMER
SET [Group] = 'UNKNOWN'
WHERE [Group] IS NULL;

UPDATE kociecki.DIM_CUSTOMER
SET CountryRegionCode = '000'
WHERE CountryRegionCode IS NULL;