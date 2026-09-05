SELECT jt1.id
from jt1,jt2
WHERE (jt1.FString = jt2.FString) 
GROUP BY jt1.id
ORDER BY jt1.id