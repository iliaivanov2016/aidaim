SELECT LastInvoiceDate, now as CurDate
FROM customer
WHERE LastInvoiceDate < now
