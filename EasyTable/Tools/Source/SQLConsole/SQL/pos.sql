SELECT CustNo, company 
FROM customer
WHERE
POS(upper('The'), upper(company)) > 0
