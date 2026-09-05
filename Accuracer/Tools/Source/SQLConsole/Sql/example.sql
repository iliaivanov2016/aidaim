SELECT First_Name,Last_Name,t2.* FROM clients_MasterDetail t1,holdings_MasterDetail t2
WHERE (t1.acct_nbr = t2.acct_nbr)
ORDER BY First_name,Last_name
