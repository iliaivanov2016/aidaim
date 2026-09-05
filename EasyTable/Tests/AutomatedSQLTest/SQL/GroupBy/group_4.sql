SELECT Avg(ID) name,FInteger,FString 
from jt1
GROUP BY FInteger,FString
ORDER BY name,FString