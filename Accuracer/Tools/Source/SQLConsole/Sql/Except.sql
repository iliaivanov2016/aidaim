SELECT * FROM customer_Range
EXCEPT CORRESPONDING BY (Company)
SELECT * FROM customer_Filter
