select * 
from jt1,Jt2
where (jt1.FInteger = jt2.FInteger) 
order by FInteger, ID, jt2.ID

