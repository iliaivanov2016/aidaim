SELECT * FROM orders 
WHERE CustNo NOT IN 
 (SELECT DISTINCT CustNo FROM customer WHERE (Company LIKE 'S%') and (CustNo < 2500))
 ORDER BY CustNo