select *
from jt1 Inner Join Jt2 
On (jt1.FString = jt2.FString) 
order by jt2.FString desc, jt1.ID, jt2.ID

