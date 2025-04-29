-- zadanie 17
SELECT pseudo, przydzial_myszy, nazwa
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE B.teren IN ('POLE', 'CALOSC') AND K.przydzial_myszy > 50
ORDER BY 2 DESC;

-- zadnanie 18
SELECT K1.imie, K1.w_stadku_od
FROM Kocury K1 JOIN Kocury K2 ON K2.imie = 'JACEK'
WHERE K1.w_stadku_od < K2.w_stadku_od
ORDER BY 2 DESC;

--zadanie 19a
SELECT K1.imie, K1.funkcja, K2.imie "SZEF 1", K3.imie "SZEF 2", K4.imie "SZEF 3"
FROM Kocury K1 
LEFT JOIN Kocury K2 ON K1.szef = K2.pseudo
LEFT JOIN Kocury K3 ON K2.szef = K3.pseudo
LEFT JOIN Kocury K4 ON K3.szef = K4.pseudo
WHERE K1.funkcja IN ('MILUSIA', 'KOT'); 

--zadanie 19b
SELECT *
FROM
(
  SELECT CONNECT_BY_ROOT imie "Imie", imie, CONNECT_BY_ROOT funkcja "funkcja", LEVEL "L"
  FROM Kocury
  CONNECT BY PRIOR szef = pseudo
  START WITH funkcja IN ('KOT', 'MILUSIA')
) 
PIVOT (MIN(imie) FOR L IN (2 szef1, 3 szef2, 4 szef3));

--zadanie 19c
SELECT imie, funkcja, RTRIM(REVERSE(RTRIM(SYS_CONNECT_BY_PATH((imie), ' | '), imie)), '| ') "IMIONA KOLEJNYCH SZEFÓW"
FROM Kocury
WHERE funkcja = 'KOT'
      OR funkcja = 'MILUSIA'
CONNECT BY PRIOR pseudo = szef
START WITH szef IS NULL;

-- zadanie 20
SELECT K.imie, B.nazwa, W.imie_wroga, W.stopien_wrogosci, WK.data_incydentu
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
JOIN Wrogowie_kocurow WK ON WK.pseudo = K.pseudo
JOIN Wrogowie W ON W.imie_wroga = WK.imie_wroga
WHERE K.plec = 'D' AND WK.data_incydentu > '2007-01-01'
ORDER BY 1;

--zadanie 21
SELECT B.nazwa, COUNT(DISTINCT K.pseudo)
FROM Kocury K JOIN Wrogowie_kocurow WK ON K.pseudo = WK.pseudo
JOIN Bandy B ON K.nr_bandy = B.nr_bandy
GROUP BY B.nazwa; 

--zadanie 22
SELECT MIN(funkcja) "Funkcja", pseudo, COUNT(pseudo) "Liczba wrogow"
FROM Kocury
NATURAL JOIN Wrogowie_kocurow
GROUP BY pseudo
HAVING COUNT(pseudo)>1;

--zadanie 23
SELECT imie, (przydzial_myszy + myszy_extra) * 12, 'powyzej 864'
FROM Kocury
WHERE (przydzial_myszy + myszy_extra)* 12 > 864 AND myszy_extra IS NOT NULL
UNION
SELECT imie, (przydzial_myszy + myszy_extra)* 12, '864'
FROM Kocury
WHERE (przydzial_myszy + myszy_extra)* 12 = 864 AND myszy_extra IS NOT NULL
UNION
SELECT imie, (przydzial_myszy + myszy_extra)* 12, 'ponizej 864'
FROM Kocury
WHERE (przydzial_myszy + myszy_extra)* 12 < 864 AND myszy_extra IS NOT NULL
ORDER BY 2 DESC;


--zadanie 24a
SELECT B.nr_bandy, B.nazwa, B.teren
FROM Bandy B LEFT JOIN Kocury K ON B.nr_bandy = K.nr_bandy
WHERE K.pseudo IS NULL;

--zadanie 24b
SELECT B.nr_bandy, B.nazwa, B.teren
FROM Bandy B LEFT JOIN Kocury K ON B.nr_bandy = K.nr_bandy
MINUS
SELECT B.nr_bandy, B.nazwa, B.teren
FROM Bandy B JOIN Kocury K ON B.nr_bandy = K.nr_bandy;

--zadanie 25
SELECT imie, funkcja, przydzial_myszy
FROM Kocury
WHERE przydzial_myszy >=
                    ALL(SELECT 3 * przydzial_myszy
                    FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
                    WHERE K.funkcja = 'MILUSIA'
                    AND B   .teren IN ('SAD', 'CALOSC'));
                         
--zadanie 26
WITH BandyAvg AS (
    SELECT funkcja, CEIL(AVG(przydzial_myszy + NVL(myszy_extra, 0))) AS avg_myszy
    FROM Kocury
    WHERE funkcja <> 'szefunio'
    GROUP BY funkcja
)
SELECT funkcja, avg_myszy
FROM BandyAvg
WHERE avg_myszy = (SELECT MAX(avg_myszy) FROM BandyAvg)
   OR avg_myszy = (SELECT MIN(avg_myszy) FROM BandyAvg);


-- zadanie 27 a
SELECT pseudo, przydzial_myszy + NVL(myszy_extra, 0)
FROM Kocury K
WHERE :n > 
      (SELECT COUNT(pseudo) 
       FROM Kocury 
       WHERE przydzial_myszy + NVL(myszy_extra, 0) > K.przydzial_myszy + NVL(K.myszy_extra, 0))
ORDER BY 2 DESC;

-- zadanie 27 b
WITH TOPN AS (SELECT *
FROM(
    SELECT przydzial_myszy + NVL(myszy_extra, 0) as zjada
    FROM Kocury
    ORDER BY 1 DESC
    )
WHERE ROWNUM <= :n)

SELECT pseudo, zjada 
FROM Kocury K JOIN TOPN T ON (K.przydzial_myszy + NVL(K.myszy_extra, 0)) = T.zjada;

--zadanie 27 c
SELECT K1.pseudo, MIN(K1.przydzial_myszy + NVL(K1.myszy_extra, 0))
FROM Kocury K1 JOIN Kocury K2 
ON K1.przydzial_myszy + NVL(K1.myszy_extra, 0) <= K2.przydzial_myszy + NVL(K2.myszy_extra, 0)
GROUP BY K1.pseudo
HAVING COUNT(DISTINCT NVL(K2.przydzial_myszy,0) +NVL(K2.myszy_extra,0)) <= 6
ORDER BY 2 DESC;


-- zadanie 27 d
SELECT pseudo, "ZJADA"
FROM 
(
    SELECT pseudo, (NVL(przydzial_myszy,0) + NVL(myszy_extra,0)) "ZJADA", 
            DENSE_RANK() OVER (ORDER BY NVL(przydzial_myszy,0) + NVL(myszy_extra,0) DESC ) rank
    FROM Kocury
)
WHERE rank <= :n;


--zadanie 28
SELECT TO_CHAR(year) "ROK", ile "LICZBA WYSTAPIEN"
FROM
(
    SELECT year, ile, mean, dis, RANK() OVER (ORDER BY dis ASC) AS rank
    FROM
    (
        SELECT year, ile, (AVG(ile) OVER ()) as mean,  ABS(ile - (AVG(ile) OVER ())) as dis
        FROM
            (
            SELECT 
                TO_CHAR(EXTRACT(YEAR FROM w_stadku_od)) as year, 
                COUNT(pseudo) AS ile
            FROM Kocury
            GROUP BY EXTRACT(YEAR FROM w_stadku_od)
            )
    ) WHERE ile < mean
) WHERE rank = 1
UNION
SELECT 'SREDNIA', ROUND(AVG(COUNT(EXTRACT(YEAR FROM w_stadku_od))), 7) "AVG"
FROM Kocury
GROUP BY EXTRACT(YEAR FROM w_stadku_od)
UNION
SELECT TO_CHAR(year), ile
FROM
(
    SELECT year, ile, mean, dis, RANK() OVER (ORDER BY dis ASC) AS rank
    FROM
    (
        SELECT year, ile, (AVG(ile) OVER ()) as mean,  ABS(ile - (AVG(ile) OVER ())) as dis
        FROM
            (
            SELECT 
                TO_CHAR(EXTRACT(YEAR FROM w_stadku_od)) as year, 
                COUNT(pseudo) AS ile
            FROM Kocury
            GROUP BY EXTRACT(YEAR FROM w_stadku_od)
            )
    ) WHERE ile > mean
) WHERE rank = 1
ORDER BY 2;  

--zadanie 29 a
SELECT K1.imie, MAX(K1.przydzial_myszy), MAX(K1.nr_bandy), AVG(K2.przydzial_myszy + NVL(K2.myszy_extra, 0))
FROM Kocury K1 JOIN Kocury K2 ON K1.nr_bandy = K2.nr_bandy
WHERE K1.plec = 'M'
GROUP BY K1.imie
HAVING MAX(K1.przydzial_myszy + NVL(K1.myszy_extra, 0)) <= AVG(K2.przydzial_myszy);

--zadanie 29b
SELECT K.imie, K.przydzial_myszy, BA.nr_bandy, BA.bavg
FROM Kocury K JOIN (
                    SELECT nr_bandy, avg(przydzial_myszy + NVL(myszy_extra, 0)) as bavg
                    FROM Kocury
                    GROUP BY nr_bandy
                    ) BA
            ON K.nr_bandy = BA.nr_bandy
WHERE K.przydzial_myszy + NVL(K.myszy_extra, 0) <= BA.bavg AND K.plec = 'M'; 

--zadanie 29c
SELECT K.imie, K.przydzial_myszy, K.nr_bandy, 
    (
    SELECT AVG(przydzial_myszy + NVL(myszy_extra, 0))
     FROM Kocury
     WHERE K.nr_bandy = nr_bandy
     )
FROM Kocury K
WHERE przydzial_myszy + NVL(myszy_extra, 0) <= 
    (
     SELECT AVG(przydzial_myszy + NVL(myszy_extra, 0))
     FROM Kocury
     WHERE K.nr_bandy = nr_bandy
     )
AND plec = 'M';

--zadanie 30
SELECT imie, w_stadku_od, '<-- najmlodszy stazem w bandzie ' || nazwa
FROM
(
    SELECT B.nazwa, K.imie, K.w_stadku_od ,MIN(K.w_stadku_od) OVER (PARTITION BY B.nr_bandy) as mins
    FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
)
WHERE w_stadku_od = mins
UNION
SELECT imie, w_stadku_od, '<-- najstarszy stazem w bandzie ' || nazwa
FROM
(
    SELECT B.nazwa, K.imie, K.w_stadku_od ,MAX(K.w_stadku_od) OVER (PARTITION BY B.nr_bandy) as mins
    FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
)
WHERE w_stadku_od = mins
UNION
SELECT imie, w_stadku_od, ' '
FROM
(
    SELECT B.nazwa, K.imie, K.w_stadku_od ,
        MIN(K.w_stadku_od) OVER (PARTITION BY B.nr_bandy) as mins,
        MAX(K.w_stadku_od) OVER (PARTITION BY B.nr_bandy) as maxs
    FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
)
WHERE w_stadku_od <> mins AND w_stadku_od <> maxs;


--zadanie 31
CREATE VIEW Bandy_stat(nazwa_bandy, sre_spoz, max_spoz, min_spoz, koty, koty_z_dod)
AS  
    SELECT nazwa, AVG(przydzial_myszy), MAX(przydzial_myszy), MIN(przydzial_myszy), COUNT(pseudo), COUNT(myszy_extra)
    FROM Kocury NATURAL JOIN Bandy
    GROUP BY nazwa;

SELECT K.pseudo, K.imie, K.funkcja, 'OD ' || BS.min_spoz|| ' DO ' || BS.max_spoz, K.w_stadku_od
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy 
              JOIN Bandy_stat BS ON BS.nazwa_bandy = B.nazwa
WHERE pseudo = :pseudo;


--zadanie 32
SELECT K.pseudo, B.nazwa, przydzial_myszy "Przed podwyzka", NVL(myszy_extra, 0) "Extra przed"
FROM kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE B.nazwa IN ('CZARNI RYCERZE' , 'LACIACI MYSLIWI')
    AND (SELECT COUNT(w_stadku_od) 
         FROM kocury 
         WHERE K.nr_bandy = nr_bandy AND K.w_stadku_od > w_stadku_od) < 3;
         
         
UPDATE Kocury
SET 
    przydzial_myszy = CASE 
                        WHEN plec = 'D' THEN przydzial_myszy + (SELECT MIN(przydzial_myszy) FROM Kocury) * 0.10
                        ELSE przydzial_myszy + 10
                      END,
    myszy_extra = NVL(myszy_extra, 0) + (SELECT AVG(NVL(myszy_extra, 0))
                                         FROM Kocury K2
                                         WHERE K2.nr_bandy = Kocury.nr_bandy) * 0.15;


SELECT K.pseudo, B.nazwa, przydzial_myszy "Po podwyzce", NVL(myszy_extra, 0) "Extra po"
FROM kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE B.nazwa IN ('CZARNI RYCERZE' , 'LACIACI MYSLIWI')
    AND (SELECT COUNT(w_stadku_od) 
         FROM kocury 
         WHERE K.nr_bandy = nr_bandy AND K.w_stadku_od > w_stadku_od) < 3;
        
ROLLBACK;    


-- zadanie 33a 
SELECT DECODE(plec, 'Kotka', nazwa, '') "NAZWA BANDY", plec, ile, szefunio, bandzior, lowczy, lapacz, kot, milusia, dzielczy, suma
    FROM(SELECT nazwa,
            DECODE(plec, 'D', 'Kotka', 'Kocur') plec,
            TO_CHAR(COUNT(PSEUDO)) ile,
            TO_CHAR(SUM(DECODE(FUNKCJA,'SZEFUNIO', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) szefunio,
            TO_CHAR(SUM(DECODE(FUNKCJA, 'BANDZIOR', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) bandzior,
            TO_CHAR(SUM(DECODE(FUNKCJA, 'LOWCZY', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) lowczy,
            TO_CHAR(SUM(DECODE(FUNKCJA, 'LAPACZ', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) lapacz,
            TO_CHAR(SUM(DECODE(FUNKCJA, 'KOT', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) kot,
            TO_CHAR(SUM(DECODE(FUNKCJA, 'MILUSIA', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) milusia,
            TO_CHAR(SUM(DECODE(FUNKCJA, 'DZIELCZY', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) dzielczy,
            TO_CHAR(SUM(NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0))) suma
        FROM Kocury
        JOIN BANDY B on KOCURY.NR_BANDY = B.NR_BANDY
        GROUP BY nazwa, plec
        ORDER BY 1, 2 DESC)
        
        UNION ALL
        
        SELECT 'ZJADA RAZEM', ' ', ' ',
             TO_CHAR(SUM(DECODE(FUNKCJA, 'SZEFUNIO', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) szefunio,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'BANDZIOR', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) bandzior,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'LOWCZY', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) lowczy,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'LAPACZ', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) lapacz,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'KOT', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) kot,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'MILUSIA', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) milusia,
             TO_CHAR(SUM(DECODE(FUNKCJA, 'DZIELCZY', NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0),0))) dzielczy,
             TO_CHAR(SUM(NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0))) suma
        FROM KOCURY;
        
        
        
-- zadanie 33b 
SELECT *
FROM
(
  SELECT TO_CHAR(DECODE(plec, 'D', nazwa, ' ')) "NAZWA BANDY",
        TO_CHAR(DECODE(plec, 'D', 'Kotka', 'Kocor')) "PLEC",
        TO_CHAR(ile) "ILE",
        TO_CHAR(NVL(szefunio, 0)) "SZEFUNIO",
        TO_CHAR(NVL(bandzior,0)) "BANDZIOR",
        TO_CHAR(NVL(lowczy,0)) "LOWCZY",
        TO_CHAR(NVL(lapacz,0)) "LAPACZ",
        TO_CHAR(NVL(kot,0)) "KOT",
        TO_CHAR(NVL(milusia,0)) "MILUSIA",
        TO_CHAR(NVL(dzielczy,0)) "DZIELCZY",
        TO_CHAR(NVL(suma,0)) "SUMA"
  FROM
  (
        SELECT nazwa, plec, funkcja, NVL(przydzial_myszy,0) + NVL(myszy_extra, 0) liczba
        FROM Kocury JOIN Bandy ON Kocury.nr_bandy= Bandy.nr_bandy
  ) 
  PIVOT 
  (
        SUM(liczba)
        FOR funkcja
        IN ('SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy,
            'LAPACZ' lapacz, 'KOT' kot, 'MILUSIA' milusia, 'DZIELCZY' dzielczy)
  ) 
  JOIN 
  (
        SELECT nazwa "N", plec "P", COUNT(pseudo) ile, SUM(przydzial_myszy + NVL(myszy_extra, 0)) suma
        FROM Kocury K JOIN Bandy B ON K.nr_bandy= B.nr_bandy
        GROUP BY nazwa, plec
        ORDER BY nazwa, plec
  ) 
  ON N = nazwa AND P = plec
)

UNION ALL

SELECT  'ZJADA RAZEM',' ',' ',
        TO_CHAR(NVL(szefunio, 0)),
        TO_CHAR(NVL(bandzior, 0)),
        TO_CHAR(NVL(lowczy, 0)),
        TO_CHAR(NVL(lapacz, 0)),
        TO_CHAR(NVL(kot, 0)),
        TO_CHAR(NVL(milusia, 0)),
        TO_CHAR(NVL(dzielczy, 0)),
        TO_CHAR(NVL(suma, 0))
FROM
(
  SELECT funkcja, NVL(przydzial_myszy,0) + NVL(myszy_extra, 0) liczba
  FROM Kocury
) 
PIVOT 
(
    SUM(liczba)
    FOR funkcja
    IN ('SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy, 'LAPACZ' lapacz,
    'KOT' kot, 'MILUSIA' milusia, 'DZIELCZY' dzielczy)
) 
NATURAL JOIN (SELECT SUM(NVL(przydzial_myszy,0) + NVL(myszy_extra, 0)) suma
              FROM Kocury);