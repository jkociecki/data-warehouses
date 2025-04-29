USE AdventureWorks2019;
GO
CREATE TABLE Kociecki.DIM_TIME 
(
	PK_TIME INT PRIMARY KEY,
	Rok INT NOT NULL,
	Kwartal INT NOT NULL,
	Miesiac INT NOT NULL,
	Miesiac_slownie VARCHAR(20) NOT NULL,
	Dzien_tyg_slownie VARCHAR(20) NOT NULL,
	Dzein_miesiaca INT NOT NULL
);

CREATE TABLE Kociecki.MONTHS_NAMES 
(
	month_number INT PRIMARY KEY,
	month_name VARCHAR(20) NOT NULL
);


CREATE TABLE KOCIECKI.WEEKDAY_NAMES
(
	weekday_number INT PRIMARY KEY,
	weekday_name VARCHAR(20) NOT NULL
);