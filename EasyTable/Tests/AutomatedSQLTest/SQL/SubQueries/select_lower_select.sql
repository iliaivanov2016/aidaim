select * from jt1 where id < 
(SELECT ID from jt2 where jt2.id = 5)
