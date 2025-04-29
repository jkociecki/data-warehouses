TRUNCATE TABLE Myszy;
/



CREATE OR REPLACE FUNCTION znajdz_ostatnia_srode(p_data IN DATE) RETURN DATE IS
    v_temp_data DATE;
BEGIN
    v_temp_data := LAST_DAY(p_data);
    RETURN NEXT_DAY(v_temp_data - 7, 'ŚRODA');
END;

    
DECLARE
    -- Daty do symulacji
    v_data_start        DATE := TO_DATE('2004-01-01', 'YYYY-MM-DD');
    v_data_koniec      DATE := TO_DATE('2024-01-20', 'YYYY-MM-DD');
    v_ostatnia_sroda   DATE;
    
    -- Liczniki i zmienne tymczasowe
    v_myszy_miesiac    NUMBER;
    v_myszy_na_kota   NUMBER;
    v_licznik_myszy   PLS_INTEGER := 0;
    v_indeks_zjadacza PLS_INTEGER;
    
    -- Definicje typów kolekcji
    TYPE t_rekord_kot IS RECORD (
        pseudo        Myszy.lowca%TYPE,
        przydział    NUMBER
    );
    TYPE t_tabela_koty IS TABLE OF t_rekord_kot;
    
    TYPE t_rekord_mysz IS RECORD (
        nr_myszy       Myszy.nr_myszy%TYPE,
        lowca         Myszy.lowca%TYPE,
        zjadacz       Myszy.zjadacz%TYPE,
        waga_myszy    Myszy.waga_myszy%TYPE,
        data_zlowienia Myszy.data_zlowienia%TYPE,
        data_wydania   Myszy.data_wydania%TYPE
    );
    TYPE t_tabela_myszy IS TABLE OF t_rekord_mysz INDEX BY PLS_INTEGER;
    
    -- Kolekcje
    v_koty            t_tabela_koty;
    v_myszy           t_tabela_myszy;

    -- Funkcja pomocnicza do znalezienia ostatniej środy


BEGIN
    WHILE v_data_start < v_data_koniec LOOP
        -- Oblicz następną środę
        v_ostatnia_sroda := LEAST(
            znajdz_ostatnia_srode(
                CASE 
                    WHEN v_data_start < znajdz_ostatnia_srode(v_data_start) - 7 
                    THEN v_data_start 
                    ELSE ADD_MONTHS(v_data_start, 1)
                END
            ),
            v_data_koniec
        );

        -- Pobierz koty i ich przydziały
        SELECT pseudo,
               NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)
        BULK COLLECT INTO v_koty
        FROM Kocury k
        WHERE w_stadku_od < v_ostatnia_sroda;

        -- Oblicz całkowitą liczbę myszy do rozdzielenia
        SELECT SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))
        INTO v_myszy_miesiac
        FROM Kocury
        WHERE w_stadku_od < v_ostatnia_sroda;

        -- Oblicz myszy na kota
        v_myszy_miesiac := CEIL(v_myszy_miesiac / v_koty.COUNT);
        v_indeks_zjadacza := 1;

        -- Generuj rekordy myszy
        FOR i IN 1 .. (v_myszy_miesiac * v_koty.COUNT) LOOP
            v_licznik_myszy := v_licznik_myszy + 1;
            
            -- Podstawowe dane myszy
            v_myszy(v_licznik_myszy).nr_myszy := v_licznik_myszy;
            v_myszy(v_licznik_myszy).lowca := v_koty(MOD(i - 1, v_koty.COUNT) + 1).pseudo;
            v_myszy(v_licznik_myszy).waga_myszy := TRUNC(DBMS_RANDOM.VALUE(10, 85));
            v_myszy(v_licznik_myszy).data_zlowienia := v_data_start + 
                MOD(v_licznik_myszy, v_ostatnia_sroda - v_data_start + 1);

            -- Obsługa przydziału myszy
            IF v_ostatnia_sroda != v_data_koniec THEN
                v_myszy(v_licznik_myszy).data_wydania := v_ostatnia_sroda;
                
                -- Przydziel na podstawie przydziału
                IF v_koty(v_indeks_zjadacza).przydział > 0 THEN
                    v_myszy(v_licznik_myszy).zjadacz := v_koty(v_indeks_zjadacza).pseudo;
                    v_koty(v_indeks_zjadacza).przydział := v_koty(v_indeks_zjadacza).przydział - 1;
                ELSE
                    v_indeks_zjadacza := v_indeks_zjadacza + 1;
                    IF v_indeks_zjadacza > v_koty.COUNT THEN
                        v_indeks_zjadacza := TRUNC(DBMS_RANDOM.VALUE(1, v_koty.COUNT));
                    END IF;
                    v_myszy(v_licznik_myszy).zjadacz := v_koty(v_indeks_zjadacza).pseudo;
                END IF;
            END IF;
        END LOOP;

        -- Przejdź do następnego okresu
        v_data_start := v_ostatnia_sroda + 1;
    END LOOP;

    -- Masowe wprowadzenie wszystkich rekordów
    FORALL i IN 1 .. v_myszy.COUNT
        INSERT INTO Myszy (
            nr_myszy, lowca, zjadacz, waga_myszy, 
            data_zlowienia, data_wydania
        )
        VALUES (
            seq_nr_myszy.NEXTVAL,
            v_myszy(i).lowca,
            v_myszy(i).zjadacz,
            v_myszy(i).waga_myszy,
            v_myszy(i).data_zlowienia,
            v_myszy(i).data_wydania
        );
        
    COMMIT;
END;
/
SELECT COUNT(*) FROM Myszy;



 WITH MiesięcznePrzydzialy AS (
    SELECT 
        TRUNC(data_wydania, 'MM') as miesiac,
        COUNT(*) as liczba_zlovonych,
        (
            SELECT NVL(SUM(przydzial_myszy + NVL(myszy_extra,0)), 0)
            FROM Kocury k
            WHERE k.w_stadku_od <= LAST_DAY(TRUNC(m.data_wydania, 'MM'))
        ) as przydzial_calkowity
    FROM Myszy m
    GROUP BY TRUNC(data_wydania, 'MM')
)
SELECT 
    TO_CHAR(miesiac, 'YYYY-MM') as miesiac,
    liczba_zlovonych,
    przydzial_calkowity,
    CASE 
        WHEN liczba_zlovonych = przydzial_calkowity THEN 'OK'
        ELSE 'BŁĄD!'
    END as status
FROM MiesięcznePrzydzialy
ORDER BY miesiac;

-- Tworzenie tabel dla kotów
CREATE OR REPLACE PROCEDURE utworz_tabele_kotow AS
BEGIN
    FOR kot IN (SELECT pseudo FROM Kocury) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'CREATE TABLE Myszy_kota_' || kot.pseudo || '(' ||
                'nr_myszy NUMBER(7) CONSTRAINT myszy_kota_pk_' || kot.pseudo || ' PRIMARY KEY,' ||
                'waga_myszy NUMBER(3) CONSTRAINT waga_myszy_' || kot.pseudo || ' CHECK (waga_myszy BETWEEN 10 AND 85),' ||
                'data_zlowienia DATE CONSTRAINT data_zlowienia_nn_' || kot.pseudo ||' NOT NULL,' ||
                'status VARCHAR2(10) DEFAULT ''NOWA'' CHECK (status IN (''NOWA'', ''PRZYDZIELONA'')))';
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -955 THEN  -- tabela już istnieje
                    NULL;
                ELSE
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/

-- Procedura do usuwania tabel kotów
CREATE OR REPLACE PROCEDURE usun_tabele_kotow AS
BEGIN
    FOR kot IN (SELECT pseudo FROM Kocury) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE Myszy_kota_' || kot.pseudo;
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -942 THEN  -- tabela nie istnieje
                    NULL;
                ELSE
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/

CREATE OR REPLACE PROCEDURE dodaj_na_stan(pseudoKota Kocury.pseudo%TYPE, dataZlowienia DATE)
AS
    TYPE tablicaWag IS TABLE OF NUMBER(3);
    wagiMyszy tablicaWag := tablicaWag();
    TYPE tablicaNrMyszy IS TABLE OF NUMBER(7);
    numeryMyszy tablicaNrMyszy := tablicaNrMyszy();
    liczbaKotow NUMBER(2);
    brakKota EXCEPTION;
    nieprawidlowaData EXCEPTION;
    brakMyszy EXCEPTION;
BEGIN
    IF dataZlowienia > SYSDATE OR dataZlowienia = NEXT_DAY(LAST_DAY(dataZlowienia) - 7, 'ŚRODA') THEN
        RAISE nieprawidlowaData; END IF;

    SELECT COUNT(K.pseudo) INTO liczbaKotow FROM KOCURY K WHERE K.pseudo = UPPER(pseudoKota);
    IF liczbaKotow = 0 THEN RAISE brakKota; END IF;

    EXECUTE IMMEDIATE 'SELECT nr_myszy, waga_myszy FROM Myszy_kota_' || pseudoKota || ' WHERE data_zlowienia = ''' || dataZlowienia || ''''
        BULK COLLECT INTO numeryMyszy, wagiMyszy;
    IF numeryMyszy.COUNT = 0 THEN
        RAISE brakMyszy;
    END IF;

    FORALL indeks IN 1..numeryMyszy.COUNT
        INSERT INTO Myszy VALUES (numeryMyszy(indeks), UPPER(pseudoKota), NULL, wagiMyszy(indeks), dataZlowienia, NULL);

    EXECUTE IMMEDIATE 'DELETE FROM Myszy_kota_' || pseudoKota || ' WHERE data_zlowienia = ''' || dataZlowienia || '''';
EXCEPTION
    WHEN brakKota THEN
        DBMS_OUTPUT.PUT_LINE('Nie znaleziono kota o pseudonimie Myszy_kota_' || UPPER(pseudoKota));
    WHEN nieprawidlowaData THEN
        DBMS_OUTPUT.PUT_LINE('Nieprawidlowa data');
    WHEN brakMyszy THEN
        DBMS_OUTPUT.PUT_LINE('Brak myszy w podanej dacie');
END;
/


INSERT INTO Myszy_kota_Bolek VALUES (1, 20, TO_DATE('2025-01-20', 'YYYY-MM-DD'));
INSERT INTO Myszy_kota_Bolek VALUES (2, 25, TO_DATE('2025-01-20', 'YYYY-MM-DD'));
INSERT INTO Myszy_kota_Bolek VALUES (3, 30, TO_DATE('2025-01-20', 'YYYY-MM-DD'));
INSERT INTO Myszy_kota_Bolek VALUES (4, 35, TO_DATE('2025-01-20', 'YYYY-MM-DD'));

BEGIN
    dodaj_na_stan('Bolek', TO_DATE('2025-01-20', 'YYYY-MM-DD'));
END;
/

-- Wykonanie przydziału
CREATE OR REPLACE PROCEDURE WykonajPrzydzial AS
    v_termin DATE := znajdz_ostatnia_srode(SYSDATE);
    TYPE tab_kot IS TABLE OF Kocury%ROWTYPE;
    v_koty tab_kot;
    v_przydzielono NUMBER;
    v_liczba_myszy NUMBER;  -- Nowa zmienna
    
    e_juz_wykonano EXCEPTION;
    e_brak_myszy EXCEPTION;  -- Nowy wyjątek
BEGIN
    -- Sprawdź, czy już była wypłata (przydział myszy)
    SELECT COUNT(*) INTO v_przydzielono
    FROM Myszy
    WHERE data_wydania = v_termin;
    
    IF v_przydzielono > 0 THEN
        RAISE e_juz_wykonano;
    END IF;

    -- Sprawdź, czy są myszy do przydziału
    SELECT COUNT(*) INTO v_liczba_myszy
    FROM Myszy
    WHERE data_wydania IS NULL;

    IF v_liczba_myszy = 0 THEN
        RAISE e_brak_myszy;
    END IF;
    
    -- Pobierz koty w kolejności hierarchii
    SELECT * BULK COLLECT INTO v_koty
    FROM Kocury
    CONNECT BY PRIOR pseudo = szef
    START WITH szef IS NULL
    ORDER BY level;
    
    -- Przydziel myszy według hierarchii
    FOR i IN 1..v_koty.COUNT LOOP
        UPDATE MYSZY
        SET zjadacz = v_koty(i).pseudo,
            data_wydania = v_termin
        WHERE data_wydania IS NULL 
        AND ROWNUM <= NVL(v_koty(i).przydzial_myszy,0) + NVL(v_koty(i).myszy_extra,0);
    END LOOP;
    
EXCEPTION
    WHEN e_juz_wykonano THEN
        RAISE_APPLICATION_ERROR(-20003, 'Wypłata już została wykonana');
    WHEN e_brak_myszy THEN
        RAISE_APPLICATION_ERROR(-20005, 'Brak myszy do przydziału');
END;
/

BEGIN
    WykonajPrzydzial();
END;    
ROLLBACK;
