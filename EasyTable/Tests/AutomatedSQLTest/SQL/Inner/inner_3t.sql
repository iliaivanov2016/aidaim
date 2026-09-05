select jt1.ID as ID1,jt2.ID ID2,jt3.ID ID3
from jt1,Jt2,jt3
where (jt1.FInteger = jt2.FInteger) and (jt1.FInteger = jt3.FInteger)
order by jt1.ID,jt2.ID,jt3.ID

