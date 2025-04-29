--zadanie 1
SELECT imie_wroga "WROG", opis_incydentu "PRZEWINA"
FROM Wrogowie_Kocurow
WHERE data_incydentu >= '2009.01.01' AND data_incydentu <= '2009.12.31';

--zadanie 2
SELECT imie "IMIE", funkcja "FUNKCJA", w_stadku_od "Z NAMI OD"
FROM kocury
WHERE w_stadku_od >= '2005.9.01' AND w_stadku_od <= '2007.07.31' AND plec = 'D';

--zadanie 3
SELECT imie_wroga "IMIE WROGA", gatunek "GATUNEK", stopien_wrogosci "STOPIEN WROGOSCI"
FROM wrogowie
WHERE lapowka IS NULL
ORDER BY stopien_wrogosci;

--zadanie 4
SELECT imie || ' zwany ' || pseudo || ' (fun. ' || funkcja || ' ) lowi myszki w bandzie ' || nr_bandy || ' od ' || w_stadku_od 
"WSZYSTKO O KOCURACH"
FROM kocury
WHERE plec = 'M'
ORDER BY w_stadku_od DESC, pseudo;

--zadanie 5
SELECT pseudo, 
REGEXP_REPLACE(REGEXP_REPLACE(pseudo,'A','#',1,1), 'L', '%', 1, 1) 
AS "PO WYMIANIE A NA # oraz L na %"
FROM kocury
WHERE pseudo LIKE '%A%' AND pseudo LIKE '%L%'; 

--zadanie 6
SELECT imie, w_stadku_od "w stadku", ROUND(przydzial_myszy * 0.9) "zjadal",
ADD_MONTHS(w_stadku_od, 6) "Podwyzka", przydzial_myszy "zjada"
FROM kocury
WHERE MONTHS_BETWEEN('2024-07-17', w_stadku_od) / 12 >= 15
AND EXTRACT(MONTH FROM w_stadku_od) >= 3 AND EXTRACT(MONTH FROM w_stadku_od) <= 9;

--zadanie 7
SELECT imie, przydzial_myszy * 3 "MYSZY KWARTALNE", NVL(myszy_extra * 3, 0) "KWARTALNE DODATKI"
FROM kocury
WHERE przydzial_myszy > 2 * NVL(myszy_extra, 0) and przydzial_myszy > 55;

--zadanie 8
SELECT imie,
    CASE 
    WHEN przydzial_myszy * 12 + NVL(myszy_extra, 0) * 12 = 660 THEN 'LIMIT'
    WHEN przydzial_myszy * 12  + NVL(myszy_extra, 0) * 12 < 660 THEN 'PONIZEJ 660'
    ELSE TO_CHAR(przydzial_myszy * 12 + NVL(myszy_extra, 0) * 12)
    END AS "ZJADA ROCZNIE"
FROM kocury
ORDER BY imie;    

--zadanie 9
SELECT pseudo, TO_CHAR(w_stadku_od, 'YYYY-MM-DD') "W STADKU", 
CASE
    WHEN (EXTRACT(DAY FROM w_stadku_od) <= 15 AND NEXT_DAY(LAST_DAY(TO_DATE('2024-10-31')), 3) - 7 >= TO_DATE('2024-10-31')) THEN NEXT_DAY(LAST_DAY(TO_DATE('2024-10-31')), 3) - 7
    WHEN (EXTRACT(DAY FROM w_stadku_od) > 15 AND NEXT_DAY(LAST_DAY(ADD_MONTHS(TO_DATE('2024-10-31'), 1)), 3) - 7 >= TO_DATE('2024-10-31')) THEN NEXT_DAY(LAST_DAY(ADD_MONTHS(TO_DATE('2024-10-31'), 1)), 3) - 7
    ELSE NEXT_DAY(LAST_DAY(ADD_MONTHS(TO_DATE('2024-10-31'), 1)), 3) - 7
    END "WYPLATA"
FROM Kocury;
  
--zadanie 10
SELECT pseudo, 
CASE
    WHEN COUNT(*) = 1 THEN 'UNKALNY'
    ELSE 'NIEUNIKALNY'
END AS "UNIKALNOSC"    
FROM kocury
GROUP BY pseudo;

SELECT szef,
    CASE
        WHEN COUNT(*) = 1 THEN 'UNIKALNY'
        ELSE 'NIEUNIKALNY'
    END AS unikalnosc
FROM kocury
WHERE szef IS NOT NULL
GROUP BY szef;


--zadanie 11
SELECT kocury.pseudo, COUNT(kocury.pseudo)
FROM (kocury JOIN wrogowie_kocurow ON kocury.pseudo = wrogowie_kocurow.pseudo)
GROUP BY kocury.pseudo
HAVING COUNT(kocury.pseudo) >= 2;


--zadanie 12
SELECT 'LICZBA KOTOW = ' || COUNT(pseudo) 
|| ' lowi jako ' || funkcja || ' i zjada max. ' || MAX(przydzial_myszy + NVL(myszy_extra, 0))
|| ' myszy miesiecznie' " " 
FROM kocury
WHERE plec = 'D' 
GROUP BY funkcja
HAVING funkcja != 'szefunio' AND AVG(przydzial_myszy + NVL(myszy_extra,0)) >= 50;

--zadanie 13
SELECT nr_bandy, plec, MIN(przydzial_myszy)
FROM kocury
GROUP BY nr_bandy, plec;

--zadanie 14
SELECT LEVEL "Poziom", pseudo "Pseudonim", funkcja "Funkcja", nr_bandy "Nr bandy"
FROM Kocury
WHERE plec  = 'M'
CONNECT BY PRIOR pseudo = szef
START WITH funkcja = 'BANDZIOR';

--zadanie 15
SELECT 
RPAD('==>', LENGTH('==>') * (LEVEL - 1), '==>' ) || TO_CHAR(LEVEL - 1) 
|| RPAD('  ', LENGTH('  ') * (LEVEL * 3), '  ') || IMIE AS "HIERARCHIA", 
NVL(szef, 'SAM SOBIE PANEM') AS "PSEUDO SZEFA",
funkcja
FROM Kocury
WHERE myszy_extra IS NOT NULL
CONNECT BY PRIOR pseudo = szef
START WITH szef IS NULL;

--zadanie 16
SELECT RPAD('   ', LENGTH('   ') * (LEVEL - 1), '   ') || pseudo AS "DROGA SLUZBOWA" 
FROM kocury
CONNECT BY PRIOR szef = pseudo
START WITH
    plec = 'M'
    AND MONTHS_BETWEEN('2024-07-17', w_stadku_od) / 12 > 15
    AND myszy_extra is NULL;
    