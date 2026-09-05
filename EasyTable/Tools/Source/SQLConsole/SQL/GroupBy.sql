SELECT CustNo, SUM(ItemsTotal)
FROM Orders
GROUP BY CustNo