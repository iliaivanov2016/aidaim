select jt1.FString,jt1.ID as ID1,jt2.ID ID2,jt3.ID ID3
from 
(jt1 left join Jt2 On (jt1.FString = jt2.FString))  
left Join jt3 On  (jt1.FInteger = jt3.FInteger) 
where jt1.id > 50
order by jt1.FString,jt1.ID,jt2.ID,jt3.ID

