select ID, FInteger F1, FString F2 
from jt1,JT2 Table2 
where (jt1.FInteger = Table2.FInteger) 
order by F2 desc, id
