select JT3.FSTRING, jt1.ID as ID1,jt2.ID ID2,jt3.ID ID3
from jt1,Jt2,jt3
where (jt1.FInteger = jt2.FInteger) and (jt1.FInteger = jt3.FInteger) and (jt3.FString < 'K')
order by jt3.FString desc,jt1.ID,jt2.ID,jt3.ID

