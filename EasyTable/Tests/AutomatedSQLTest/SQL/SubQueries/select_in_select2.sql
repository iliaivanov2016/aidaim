select * from jt1 where (id NOT IN 
(SELECT ID from jt2 where jt2.id = 5)) 
and (jt1.id > 15)
