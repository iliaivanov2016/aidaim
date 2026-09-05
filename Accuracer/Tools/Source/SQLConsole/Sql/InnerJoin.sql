SELECT Contact, Customer.CustNo, Company, Orders.OrderNo, Orders.CustNo
FROM Customer INNER JOIN Orders 
ON (Customer.CustNo = Orders.CustNo)
WHERE Contact LIKE 'E%'
ORDER BY Contact,Orders.CustNo,Orders.OrderNo