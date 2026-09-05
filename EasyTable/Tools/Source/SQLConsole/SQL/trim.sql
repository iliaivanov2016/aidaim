SELECT CustNo, company, TRIM('   ' + company + '   ')
FROM customer
