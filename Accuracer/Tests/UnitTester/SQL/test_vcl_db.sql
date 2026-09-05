-- all data is made up by the author for testing purposes
-- it has nothing common with real life

-- dept table: departments of the small automobile sales centre
DROP TABLE dept;
CREATE TABLE dept (
	ID 	Autoinc,
	Name 	Char(20) NOT NULL,
	PRIMARY KEY (ID)
);
CREATE INDEX Idx1 ON dept (Name);
INSERT INTO dept(Name) VALUES ('New cars department');
INSERT INTO dept(Name) VALUES ('Used cars department');


-- emp table: employees working in departments of the small automobile sales centre
DROP TABLE emp;
CREATE TABLE emp (
	ID 		Autoinc,
	Name 		Char(20),
	Surname 	Char(20),
	Salary		Money,
	Gender		Char(1),
	Birthday	Timestamp,
	DeptID		Integer,
	PRIMARY KEY (ID)
);
CREATE INDEX Idx1 ON emp (Name);
CREATE INDEX Idx2 ON emp (Surname);
CREATE INDEX Idx3 ON emp (DeptID);
-- 1
INSERT INTO emp (Name,Surname,Salary,Gender,Birthday,DeptID) VALUES (
'Mike','Tompson',35000,'M','11/08/1973',1
);
-- 2
INSERT INTO emp (Name,Surname,Salary,Gender,Birthday,DeptID) VALUES (
'Marta','Bernstein',25000,'F','06/17/1984',1
);
-- 3
INSERT INTO emp (Name,Surname,Salary,Gender,Birthday,DeptID) VALUES (
'Ann','Nikolson',12000,'F','08/30/1993',1
);
-- 4
INSERT INTO emp (Name,Surname,Salary,Gender,Birthday,DeptID) VALUES (
'Ann','Swensson',10000,'F','04/25/1990',2
);
-- 5
INSERT INTO emp (Name,Surname,Salary,Gender,Birthday,DeptID) VALUES (
'Laura','Bright',13000,'F','12/31/1987',2
);
-- 6
INSERT INTO emp (Name,Surname,Salary,Gender,Birthday,DeptID) VALUES (
'Steve','Masters',30000,'M','02/26/1965',2
);

-- orders table: cars sold by the employees 
DROP TABLE orders;
CREATE TABLE orders (
	ID 			Autoinc,
	Car 			Char(50) NOT NULL,
	Mileage		Integer NULL,
        Prod_Year       Word,
	Sale_date	Timestamp,
	Sale_price	Money,
	Buy_date	Timestamp,
	Buy_price	Money,
	EmpID		Integer,
	PRIMARY KEY (ID)
);
CREATE INDEX Idx1 ON orders (Car);
CREATE INDEX Idx2 ON orders (Prod_Year);
CREATE INDEX Idx3 ON orders (EmpID);
CREATE INDEX Idx4 ON orders (Prod_Year);
-- 1
INSERT INTO orders (Car,Mileage,Prod_Year,Sale_date,Sale_price,Buy_date,Buy_price,EmpID) VALUES(
'BMW X5',NULL,2009,'01/23/2010',42000,'12/29/2009',38000,1
);
-- 2
INSERT INTO orders (Car,Mileage,Prod_Year,Sale_date,Sale_price,Buy_date,Buy_price,EmpID) VALUES(
'Audi A4',NULL,2009,'01/21/2010',35000,'12/27/2009',31500,2
);
-- 3
INSERT INTO orders (Car,Mileage,Prod_Year,Sale_date,Sale_price,Buy_date,Buy_price,EmpID) VALUES(
'Ford Focus',NULL,2010,'01/12/2010',17200,'01/10/2010',15700,3
);
-- 4
INSERT INTO orders (Car,Mileage,Prod_Year,Sale_date,Sale_price,Buy_date,Buy_price,EmpID) VALUES(
'Lexus rx350',NULL,2010,'02/15/2010',79000,'02/01/2010',71300,1
);
-- 5 - used cars
INSERT INTO orders (Car,Mileage,Prod_Year,Sale_date,Sale_price,Buy_date,Buy_price,EmpID) VALUES(
'Ford Explorer',27000,2008,'02/06/2010',38000,'02/01/2010',35400,4
);
-- 6 - used cars
INSERT INTO orders (Car,Mileage,Prod_Year,Sale_date,Sale_price,Buy_date,Buy_price,EmpID) VALUES(
'Chevrolet Captiva',36100,2006,'01/17/2010',28500,'12/17/2009',24300,5
);
-- 7 - used cars
INSERT INTO orders (Car,Mileage,Prod_Year,Sale_date,Sale_price,Buy_date,Buy_price,EmpID) VALUES(
'Chevrolet TrailBlazer',54300,2005,'02/25/2010',29000,'02/08/2010',24800,6
);
-- 8 - used cars
INSERT INTO orders (Car,Mileage,Prod_Year,Sale_date,Sale_price,Buy_date,Buy_price,EmpID) VALUES(
'Volkswagen Touareg ',15000,2008,'02/13/2010',88000,'12/24/2009',77000,6
);
