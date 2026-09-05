select jt1.finteger fi1,jt2.FInteger fi2,jt1.ID id1,jt2.ID id2,jt1.FString str1,jt2.FString str2
from jt1 Left Join Jt2 
On (jt1.FInteger = jt2.FInteger) 
where (jt2.FString < 'K')
order by jt1.fInteger,jt2.FInteger,jt1.ID,jt2.ID
