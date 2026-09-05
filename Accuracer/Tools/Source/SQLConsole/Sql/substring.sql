SELECT CustNo, company, LTRIM(SUBSTRING(company, POS(UPPER('The'), UPPER(company))+LENGTH('The')))
FROM customer
WHERE
POS(UPPER('The'), UPPER(company)) > 0
