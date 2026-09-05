SELECT Contact, Customer.CustNo, Company, Orders.OrderNo, Orders.CustNo
FROM Customer NATURAL LEFT JOIN Orders 
WHERE State IS NOT NULL
ORDER BY Contact,Orders.CustNo,Orders.OrderNo
