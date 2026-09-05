select * from jt1 where id IN 
(SELECT ID from jt2 where jt2.id = 5)
