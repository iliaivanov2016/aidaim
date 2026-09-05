select * from jt1 where id in 
(
SELECT distinct id from jt1 where (jt1.id < 5)
)
