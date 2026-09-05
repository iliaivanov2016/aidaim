SELECT * FROM customer_Range
INTERSECT CORRESPONDING BY (Company)
SELECT * FROM customer_Filter
