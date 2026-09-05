select TOP 10 * 
from jt1,Jt2
where (jt1.FInteger = jt2.FInteger) 
order by jt1.ID,jt2.ID;
#DBISAM
select * 
from jt1,Jt2
where (jt1.FInteger = jt2.FInteger) 
order by jt1.ID,jt2.ID
TOP 10 
