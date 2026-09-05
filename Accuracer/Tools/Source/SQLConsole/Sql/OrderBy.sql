SELECT CustNo, Contact, Company, City, Country
FROM Customer
ORDER BY Country DESC, City DESC NOCASE, Company NOCASE, Contact
