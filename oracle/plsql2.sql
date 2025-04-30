SET SERVEROUTPUT ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

-- usuwanie
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE Myszy CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_polowania';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    FOR kot IN (SELECT pseudo FROM Kocury) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE Rejestr_' || kot.pseudo;
        EXCEPTION 
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

---------------------------------- sekwencja -----------------------------------

CREATE SEQUENCE seq_polowania START WITH 1 INCREMENT BY 1;


--------------------------------- tabela myszy ---------------------------------

BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE Myszy (
        nr_myszy            NUMBER        CONSTRAINT m_pk PRIMARY KEY,
        lowca               VARCHAR2(15)  CONSTRAINT m_lowca_fk REFERENCES Kocury(pseudo),
        zjadacz             VARCHAR2(15)  CONSTRAINT m_zjadacz_fk REFERENCES Kocury(pseudo),
        waga_myszy          NUMBER(3)     CONSTRAINT m_waga_check CHECK (waga_myszy BETWEEN 15 AND 40),
        data_zlowienia      DATE          NOT NULL,
        data_wydania        DATE,
        CONSTRAINT m_daty   CHECK (data_zlowienia <= data_wydania)
    )';
END;
/


---------------------------- indywidualne rejestry -----------------------------

BEGIN
    FOR kot IN (SELECT pseudo FROM Kocury) LOOP
        EXECUTE IMMEDIATE 'CREATE TABLE Rejestr_' || kot.pseudo ||
            '( nr_myszy NUMBER(10) CONSTRAINT pk_rej_' || kot.pseudo || ' PRIMARY KEY,' ||
            'waga_myszy NUMBER(3) CONSTRAINT ch_waga_myszy_' || kot.pseudo || ' CHECK (waga_myszy BETWEEN 15 AND 40),' ||
            'data_zlowienia DATE NOT NULL)';
    END LOOP;
END;
/


--------------------------- zarzadzanie polowaniami ----------------------------

CREATE OR REPLACE PACKAGE ZarzadzaniePolowaniami AS
    PROCEDURE GenerujDaneHistoryczne;
    PROCEDURE DodajUpolowanaMysz(p_lowca VARCHAR2, p_data DATE);
    PROCEDURE WykonajPrzydzial;
END ZarzadzaniePolowaniami;
/

CREATE OR REPLACE PACKAGE BODY ZarzadzaniePolowaniami AS    

    -- generowanie danych historycznych
    PROCEDURE GenerujDaneHistoryczne IS
        data_start DATE := TO_DATE('2004-01-01','YYYY-MM-DD');
        data_koniec DATE := TRUNC(SYSDATE) - 1;
        termin_wyplaty DATE;
        
        TYPE tab_pseudo IS TABLE OF Kocury.pseudo%TYPE;
        TYPE tab_przydz IS TABLE OF NUMBER;
        TYPE tab_mysz IS TABLE OF Myszy%ROWTYPE INDEX BY BINARY_INTEGER;
        
        v_pseudo tab_pseudo := tab_pseudo();
        v_przydzialy tab_przydz := tab_przydz();
        v_wykorzystane_przydzialy tab_przydz := tab_przydz();
        v_myszy tab_mysz;
        
        v_nr_myszy NUMBER := 0;
        v_suma_mysz NUMBER;
        v_aktualny_kot PLS_INTEGER := 1;
        v_najedzeni PLS_INTEGER := 0;
    BEGIN
        LOOP
            EXIT WHEN data_start >= data_koniec;
            
            IF data_start < NEXT_DAY(LAST_DAY(data_start), 'WEDNESDAY') - 7 
            THEN termin_wyplaty := LEAST(NEXT_DAY(LAST_DAY(data_start), 'WEDNESDAY') - 7, data_koniec);
            ELSE termin_wyplaty := LEAST(NEXT_DAY(LAST_DAY(ADD_MONTHS(data_start, 1)), 'WEDNESDAY') - 7, data_koniec);
            END IF;
            
            -- pobranie kotow i przedzialwo
            SELECT pseudo, NVL(przydzial_myszy,0) + NVL(myszy_extra,0)
            BULK COLLECT INTO v_pseudo, v_przydzialy
            FROM Kocury
            WHERE w_stadku_od <= termin_wyplaty
            ORDER BY funkcja, w_stadku_od;
            
            -- wykorzystane przydzialy
            v_wykorzystane_przydzialy.EXTEND(v_pseudo.COUNT);
            FOR i IN 1..v_pseudo.COUNT LOOP
                v_wykorzystane_przydzialy(i) := 0;
            END LOOP;
            
            DBMS_OUTPUT.PUT_LINE('Liczba aktywnych kotów: ' || v_pseudo.COUNT);
            
            -- obliczenie sumy myszy dla przedzialu
            SELECT SUM(NVL(przydzial_myszy,0) + NVL(myszy_extra,0))
            INTO v_suma_mysz
            FROM Kocury
            WHERE w_stadku_od <= termin_wyplaty;
            
            DBMS_OUTPUT.PUT_LINE('Suma myszy do wygenerowania: ' || v_suma_mysz);
            
            v_aktualny_kot := 1;
            v_najedzeni := 0;
            
            FOR i IN 1..v_suma_mysz LOOP
                v_nr_myszy := v_nr_myszy + 1;
                
                -- szukanie kota z dostepnym przydzialem
                WHILE v_wykorzystane_przydzialy(v_aktualny_kot) >= v_przydzialy(v_aktualny_kot)
                      AND v_najedzeni < v_pseudo.COUNT 
                LOOP
                    v_aktualny_kot := CASE 
                        WHEN v_aktualny_kot = v_pseudo.COUNT THEN 1 
                        ELSE v_aktualny_kot + 1 
                    END;
                    v_najedzeni := v_najedzeni + 1;
                END LOOP;
                
                -- rekord myszy
                v_myszy(v_nr_myszy).nr_myszy := seq_polowania.NEXTVAL;
                
                -- losowy lowca
                v_myszy(v_nr_myszy).lowca := v_pseudo(
                    TRUNC(DBMS_RANDOM.VALUE(1, v_pseudo.COUNT + 1))
                );
                
                -- przydzielenie zjadacza
                IF v_najedzeni = v_pseudo.COUNT THEN
                    v_myszy(v_nr_myszy).zjadacz := 'TYGRYS';
                ELSE
                    v_myszy(v_nr_myszy).zjadacz := v_pseudo(v_aktualny_kot);
                    v_wykorzystane_przydzialy(v_aktualny_kot) := 
                        v_wykorzystane_przydzialy(v_aktualny_kot) + 1;
                END IF;
                
                -- ustalenie wagi
                v_myszy(v_nr_myszy).waga_myszy := CASE 
                    WHEN v_myszy(v_nr_myszy).lowca = 'TYGRYS' THEN TRUNC(DBMS_RANDOM.VALUE(25, 40))
                    ELSE TRUNC(DBMS_RANDOM.VALUE(15, 30))
                END;
                
                -- data zlowienia
                v_myszy(v_nr_myszy).data_zlowienia := data_start + 
                    MOD(TRUNC(DBMS_RANDOM.VALUE(0, termin_wyplaty - data_start)), 7);
                
                v_myszy(v_nr_myszy).data_wydania := termin_wyplaty;
            END LOOP;
            
            data_start := termin_wyplaty + 1;
        END LOOP;
        
        -- wstawienie myszy do bazy
        FORALL i IN 1..v_myszy.COUNT
            INSERT INTO Myszy VALUES v_myszy(i);
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Wygenerowano i zapisano ' || v_myszy.COUNT || ' myszy.');
    END;

    -- dodawanie opolowanych myszy
    PROCEDURE DodajUpolowanaMysz(p_lowca VARCHAR2, p_data DATE) IS
        TYPE t_wagi IS TABLE OF NUMBER(3);
        TYPE t_ids IS TABLE OF NUMBER(10);
        
        v_wagi t_wagi;
        v_ids t_ids;
        v_pseudo VARCHAR2(15) := UPPER(p_lowca);
        v_kot_istnieje NUMBER;
        v_w_stadku_od DATE;
        
        e_niepoprawny_kot EXCEPTION;
        e_niepoprawna_data EXCEPTION;
        e_kot_nie_w_stadku EXCEPTION;
    BEGIN
        -- walidacja
        IF TRUNC(p_data) > TRUNC(SYSDATE) THEN
            RAISE e_niepoprawna_data;
        END IF;
        
        SELECT COUNT(*) INTO v_kot_istnieje
        FROM Kocury WHERE pseudo = v_pseudo;
        
        IF v_kot_istnieje = 0 THEN
            RAISE e_niepoprawny_kot;
        END IF;
        
        SELECT w_stadku_od INTO v_w_stadku_od
        FROM Kocury 
        WHERE pseudo = v_pseudo;
        
        IF TRUNC(p_data) < TRUNC(v_w_stadku_od) THEN
            RAISE e_kot_nie_w_stadku;
        END IF;
        
        -- pobranie myszy z indywidualnego konta
        EXECUTE IMMEDIATE
            'SELECT nr_myszy, waga_myszy FROM Rejestr_' || v_pseudo ||
            ' WHERE TRUNC(data_zlowienia) = TRUNC(:1)'
            BULK COLLECT INTO v_ids, v_wagi
            USING p_data;
            
        -- przeniesienie myszy na glowne konto
        FORALL i IN 1..v_ids.COUNT
            INSERT INTO Myszy(nr_myszy, lowca, waga_myszy, data_zlowienia)
            VALUES (v_ids(i), v_pseudo, v_wagi(i), TRUNC(p_data));
            
        -- usuniecie myszy z indywidualnego konta
        EXECUTE IMMEDIATE
            'DELETE FROM Rejestr_' || v_pseudo || ' WHERE TRUNC(data_zlowienia) = TRUNC(:1)'
            USING p_data;
            
        COMMIT;
        
    EXCEPTION
        WHEN e_niepoprawny_kot THEN
            RAISE_APPLICATION_ERROR(-20001, 'nie ma kota: ' || v_pseudo);
        WHEN e_niepoprawna_data THEN
            RAISE_APPLICATION_ERROR(-20002, 'data z przyszlosci');
        WHEN e_kot_nie_w_stadku THEN
            RAISE_APPLICATION_ERROR(-20004, 'kot ' || v_pseudo || ' nie byl jeszcze w stadku w dniu ' || TO_CHAR(p_data, 'YYYY-MM-DD'));
    END;

    -- wyplata
    PROCEDURE WykonajPrzydzial IS
        TYPE t_przydzial IS RECORD (
            pseudo Kocury.pseudo%TYPE,
            przydzial PLS_INTEGER
        );
        TYPE t_tab_przydzialow IS TABLE OF t_przydzial INDEX BY PLS_INTEGER;  
        TYPE t_myszy IS TABLE OF Myszy%ROWTYPE;
        TYPE t_update_info IS RECORD (
            nr_myszy Myszy.nr_myszy%TYPE,
            zjadacz Kocury.pseudo%TYPE
        );
        TYPE t_tab_updates IS TABLE OF t_update_info INDEX BY PLS_INTEGER;    
        
        v_przydzialy t_tab_przydzialow;
        v_myszy t_myszy;
        v_updates t_tab_updates;
        v_termin DATE := TRUNC(NEXT_DAY(LAST_DAY(SYSDATE)-7, 'WEDNESDAY'));
        v_current_kot PLS_INTEGER := 1;
        v_najedzeni PLS_INTEGER := 0;
        v_ilosc_kotow PLS_INTEGER;
        v_juz_przydzielono PLS_INTEGER;
        
        e_juz_przydzielono EXCEPTION;
        e_brak_myszy EXCEPTION;
        
    BEGIN
        SELECT COUNT(*) INTO v_juz_przydzielono
        FROM Myszy 
        WHERE data_wydania = v_termin;
        
        IF v_juz_przydzielono > 0 THEN
            RAISE e_juz_przydzielono;
        END IF;
        
        -- pobranie kotow i przydzialow
        FOR r_kot IN (
            SELECT pseudo, NVL(przydzial_myszy,0) + NVL(myszy_extra,0) as przydzial
            FROM Kocury
            CONNECT BY PRIOR pseudo = szef
            START WITH szef IS NULL
            ORDER BY level
        ) LOOP
            v_ilosc_kotow := NVL(v_ilosc_kotow, 0) + 1;
            v_przydzialy(v_ilosc_kotow).pseudo := r_kot.pseudo;
            v_przydzialy(v_ilosc_kotow).przydzial := r_kot.przydzial;
        END LOOP;
        
        -- pobranie dost?pnych myszy
        SELECT *
        BULK COLLECT INTO v_myszy
        FROM Myszy
        WHERE data_wydania IS NULL
        ORDER BY data_zlowienia;
        
        IF v_myszy.COUNT = 0 THEN
            RAISE e_brak_myszy;
        END IF;
        
        -- przydzielanie myszy
        FOR i IN 1..v_myszy.COUNT LOOP
            WHILE v_przydzialy(v_current_kot).przydzial = 0 
                  AND v_najedzeni < v_ilosc_kotow 
            LOOP
                v_current_kot := CASE 
                    WHEN v_current_kot = v_ilosc_kotow THEN 1 
                    ELSE v_current_kot + 1 
                END;
                v_najedzeni := v_najedzeni + 1;
            END LOOP;
            
            -- zjadacz
            v_updates(i).nr_myszy := v_myszy(i).nr_myszy;
            v_updates(i).zjadacz := CASE 
                WHEN v_najedzeni = v_ilosc_kotow THEN 'TYGRYS'
                ELSE v_przydzialy(v_current_kot).pseudo
            END;
            
            -- aktualizacja przydzialu
            IF v_najedzeni < v_ilosc_kotow THEN
                v_przydzialy(v_current_kot).przydzial := v_przydzialy(v_current_kot).przydzial - 1;
            END IF;
        END LOOP;
        
        -- Masowa aktualizacja
        FORALL i IN 1..v_myszy.COUNT
            UPDATE Myszy
            SET zjadacz = v_updates(i).zjadacz,
                data_wydania = v_termin
            WHERE nr_myszy = v_updates(i).nr_myszy;
            
        COMMIT;
    
        EXCEPTION
            WHEN e_juz_przydzielono THEN
                RAISE_APPLICATION_ERROR(-20003, 'przydzial na dzien ' || TO_CHAR(v_termin, 'YYYY-MM-DD') || 
                                              ' zostal juz wykonany');
            WHEN e_brak_myszy THEN
                RAISE_APPLICATION_ERROR(-20005, 'brak myszek');
            WHEN OTHERS THEN
                ROLLBACK;
                RAISE;
END;

END ZarzadzaniePolowaniami;
/

------------------------------------ testy -------------------------------------

-- generowanie danych historycznych
BEGIN
    ZarzadzaniePolowaniami.GenerujDaneHistoryczne;
END;
/

-- dane testowe dla tagisa
INSERT INTO Rejestr_TYGRYS VALUES(seq_polowania.NEXTVAL, 35, SYSDATE);
INSERT INTO Rejestr_TYGRYS VALUES(seq_polowania.NEXTVAL, 28, SYSDATE);
INSERT INTO Rejestr_TYGRYS VALUES(seq_polowania.NEXTVAL, 30, SYSDATE);

select * from Rejestr_TYGRYS;

-- przeniesienie myszy z indywidualnego konta
BEGIN
    ZarzadzaniePolowaniami.DodajUpolowanaMysz('TYGRYS', SYSDATE);
END;
/

-- wykonanie przydzialu
BEGIN
    ZarzadzaniePolowaniami.WykonajPrzydzial;
END;
/

-- sprawdzenie wynikow
SELECT COUNT(*) as "Liczba wszystkich myszy" FROM Myszy;

SELECT TO_CHAR(data_zlowienia, 'YYYY-MM') as miesiac,
       COUNT(*) as liczba_myszy,
       ROUND(AVG(waga_myszy), 2) as srednia_waga_myszy
FROM Myszy
GROUP BY TO_CHAR(data_zlowienia, 'YYYY-MM')
ORDER BY miesiac;

select * from Myszy order by data_wydania desc;

SELECT lowca, COUNT(*) as zlapal
FROM Myszy
GROUP BY lowca
ORDER BY zlapal DESC;
