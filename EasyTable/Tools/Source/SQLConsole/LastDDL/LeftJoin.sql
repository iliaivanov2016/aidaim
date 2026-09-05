SELECT First_Name,Last_Name,t2.* FROM 
clients_MasterDetail t1 LEFT JOIN holdings_MasterDetail t2
ON (t1.acct_nbr = t2.acct_nbr)
ORDER BY First_name,Last_name
