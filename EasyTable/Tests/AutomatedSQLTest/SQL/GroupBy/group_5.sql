SELECT Count(*) Counter, FInteger,FString 
from jt1
GROUP BY FInteger,FString
ORDER BY Counter desc, FInteger, FString