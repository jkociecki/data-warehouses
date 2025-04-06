-- Usuwanie istniejących tabel (czyszczenie bazy)
DROP TABLE IF EXISTS Nabycia;
DROP TABLE IF EXISTS Zakupy;
DROP TABLE IF EXISTS Oferty;
DROP TABLE IF EXISTS Produkty;
DROP TABLE IF EXISTS Sklepy;
DROP TABLE IF EXISTS Klienci;

-- Usuwanie istniejących sekwencji
DROP SEQUENCE IF EXISTS klient_seq;
DROP SEQUENCE IF EXISTS sklep_seq;
DROP SEQUENCE IF EXISTS produkt_seq;
DROP SEQUENCE IF EXISTS oferta_seq;
DROP SEQUENCE IF EXISTS zakup_seq;
DROP SEQUENCE IF EXISTS nabycie_seq;

CREATE DATABASE IF NOT EXISTS Sklepy;
USE Sklepy;

CREATE SEQUENCE klient_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE sklep_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE produkt_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE oferta_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE zakup_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE nabycie_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE Klienci(
    id_klienta INT NOT NULL DEFAULT NEXT VALUE FOR klient_seq,
    client_login VARCHAR(255) NOT NULL UNIQUE,
    PRIMARY KEY(id_klienta)
);    

CREATE TABLE Sklepy(
    id_sklepu INT NOT NULL DEFAULT NEXT VALUE FOR sklep_seq,
    nazwa VARCHAR(255) NOT NULL,
    PRIMARY KEY(id_sklepu)
);

CREATE TABLE Produkty(
    id_produktu INT NOT NULL DEFAULT NEXT VALUE FOR produkt_seq,
    nazwa VARCHAR(255) NOT NULL,
    PRIMARY KEY(id_produktu)
);

CREATE TABLE Oferty (
    id_oferty INT NOT NULL DEFAULT NEXT VALUE FOR oferta_seq,
    cena DECIMAL(10,2) NOT NULL CHECK (cena > 0),
    id_produktu INT NOT NULL,
    id_sklepu INT NOT NULL,
    PRIMARY KEY(id_oferty),
    FOREIGN KEY (id_produktu) REFERENCES Produkty(id_produktu),
    FOREIGN KEY (id_sklepu) REFERENCES Sklepy(id_sklepu)
);

CREATE TABLE Zakupy(
    id_zakupu INT NOT NULL DEFAULT NEXT VALUE FOR zakup_seq,
    data DATE NOT NULL,
    czas TIME NOT NULL,
    id_sklepu INT NOT NULL,
    id_klienta INT NOT NULL,
    PRIMARY KEY(id_zakupu),
    FOREIGN KEY (id_sklepu) REFERENCES Sklepy(id_sklepu),
    FOREIGN KEY (id_klienta) REFERENCES Klienci(id_klienta)
);

CREATE TABLE Nabycia(
    id_nabycia INT NOT NULL DEFAULT NEXT VALUE FOR nabycie_seq,
    ilosc INT NOT NULL CHECK (ilosc > 0),
    id_oferty INT NOT NULL,
    id_zakupu INT NOT NULL,
    PRIMARY KEY(id_nabycia),
    FOREIGN KEY (id_oferty) REFERENCES Oferty(id_oferty),
    FOREIGN KEY (id_zakupu) REFERENCES Zakupy(id_zakupu)
);



INSERT INTO Klienci (client_login) VALUES
('aniakow'),
('marcinpol'),
('zosiawik'),
('tomaszbar'),
('jarekdom'),
('kasiasok');

INSERT INTO Sklepy (nazwa) VALUES
('We Wroclawiu'),
('W Warszawoe'),
('W Krakowie'),
('W Gdansku'),
('W Limanowej'),
('W Poznaniu');

INSERT INTO Produkty (nazwa) VALUES
('Chleb'),
('Mleko'),
('Jabłko'),
('Ser'),
('Woda'),
('Masło'),
('Jajka');

INSERT INTO Oferty (cena, id_produktu, id_sklepu) VALUES
(4.50, 1, 1),  -- Chleb we Wroclawiu
(3.99, 1, 2),  -- Chleb w Warszawie
(3.20, 2, 1),  
(5.99, 4, 3),  
(2.50, 5, 4),  
(6.99, 3, 2),  
(8.50, 6, 5),  
(12.99, 7, 6); 

INSERT INTO Zakupy (data, czas, id_sklepu, id_klienta) VALUES
('2025-03-05', '10:15:00', 1, 1),  -- aniakow we wroclawiu
('2025-03-06', '14:30:00', 2, 2),  -- marcin w warszawie
('2025-03-07', '18:45:00', 3, 3), 
('2025-03-08', '09:20:00', 1, 4),  
('2025-03-08', '16:10:00', 4, 1),  
('2025-03-09', '12:30:00', 5, 5),  
('2025-03-10', '17:45:00', 6, 6);  

INSERT INTO Nabycia (ilosc, id_oferty, id_zakupu) VALUES
(2, 1, 1),  -- ania 2 chleby w zakupach nr 1
(1, 3, 1),  -- ania 1 mleko tez w zakupach nr 1
(3, 6, 2),  
(1, 4, 3),  
(4, 1, 4),  
(2, 5, 5),  
(1, 7, 6),  
(3, 8, 7); 




--------------------------------------------------------------------
-- cena <= 0
INSERT INTO Oferty (cena, id_produktu, id_sklepu) VALUES (0, 1, 1);

-- ilosc <= 0
INSERT INTO Nabycia (ilosc, id_oferty, id_zakupu) VALUES (0, 1, 1);

-- id_produktu 100 nie ma
INSERT INTO Oferty (cena, id_produktu, id_sklepu) VALUES (9.99, 100, 1);

-- id_klienta 100 nie ma
INSERT INTO Zakupy (data, czas, id_sklepu, id_klienta) VALUES ('2025-03-15', '11:30:00', 1, 100);

-- id_zakupu 100 nie ma
INSERT INTO Nabycia (ilosc, id_oferty, id_zakupu) VALUES (3, 1, 100);

--duplikat wartosci
INSERT INTO Klienci(client_login) VALUES ('aniakow');