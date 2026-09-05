SELECT LastInvoiceDate, now as CurDate
FROM customer
WHERE LastInvoiceDate < ToDate('12/16/2002 11:10:30 am','MM/DD/YYYY hh:nn:ss ampm')