select * from jt1 where FInteger in 
(SELECT distinct FInteger from jt2 where (jt2.id <> 5))
