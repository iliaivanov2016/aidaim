SELECT CustNo, Contact, Company, City, Country
INTO NewCustomer
FROM Customer
WHERE Contact LIKE 'E%'
ORDER BY Country, City, Company, Contact