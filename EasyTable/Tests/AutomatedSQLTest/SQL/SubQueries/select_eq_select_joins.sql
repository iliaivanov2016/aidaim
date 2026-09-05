select jt1.id, jt1.fstring, jt1.finteger, jt3.finteger FROM 
jt1,jt3 
WHERE (jt1.id = 
(SELECT ID from jt2 where (jt2.id = 1))) AND
(jt1.id = jt3.id) 
