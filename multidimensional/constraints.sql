ALTER TABLE KOCIECKI.FACT_SALES
ADD 
	CONSTRAINT
	fk_productID FOREIGN KEY (ProductID) REFERENCES KOCIECKI.DIM_PRODUCT(ProductID),
	CONSTRAINT 
	fk_customerID FOREIGN KEY (CustomerID) REFERENCES KOCIECKI.DIM_CUSTOMER(CustomerID),
	CONSTRAINT
	fk_salesPersonID FOREIGN KEY (SalesPersonID) REFERENCES KOCIECKI.DIM_SALESPERSON(SalesPersonID);


-- Test 1: Duplikat PK w DIM_CUSTOMER 
INSERT INTO KOCIECKI.DIM_CUSTOMER (CustomerID, FirstName, LastName)
VALUES (1, 'a', 'a');

-- Test 2: Nieistniejący ProductID w FACT_SALES (naruszenie FK)
INSERT INTO KOCIECKI.FACT_SALES 
(ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate,OrderQty, UnitPrice, UnitPriceDiscount, LineTotal) 
VALUES (-1,1, NULL, 1, 1, 1, 1010, 1, 1010);

-- Test 3: Nieistniejący CustomerID w FACT_SALES (naruszenie FK)
INSERT INTO KOCIECKI.FACT_SALES 
( ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate,OrderQty, UnitPrice, UnitPriceDiscount, LineTotal) 
VALUES (1, -1, 1, 1, 1, 2, 1, 1, 1);

-- Test 4: Nieistniejący SalesPersonID w FACT_SALES (naruszenie FK)
INSERT INTO KOCIECKI.FACT_SALES ( ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate,OrderQty, UnitPrice, UnitPriceDiscount, LineTotal)
VALUES ( 1, 1, -1, 1, 1, 1, 1, 1, 1);