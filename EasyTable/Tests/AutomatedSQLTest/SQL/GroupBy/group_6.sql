SELECT jt1.FString,COUNT(jt1.FInteger) cnt,Min(jt2.FInteger) minimum
from jt1,jt2
WHERE (jt1.FString = jt2.FString) or (jt1.FString like jt2.FString +'%')
GROUP BY jt1.FSTRING
ORDER BY jt1.FSTRING