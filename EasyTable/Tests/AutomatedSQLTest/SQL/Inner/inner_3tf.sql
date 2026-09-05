select jt1.ID
from jt1 j1 join Jt2 as j2 on (j1.FInteger = j2.FInteger) 
     join jt3 j3 on (j1.FInteger = j3.FInteger)
where j2.FString = j3.FString
order by j1.ID

