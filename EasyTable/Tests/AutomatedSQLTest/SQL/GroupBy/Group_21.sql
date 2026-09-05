#try
SELECT Avg(ID) name,FInteger,FString 
from jt1
GROUP BY name,FInteger,FString
ORDER BY FString