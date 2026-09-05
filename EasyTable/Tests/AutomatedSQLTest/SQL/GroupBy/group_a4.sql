select jt1.FString, Min(jt1.FInteger) s1
from jt1,Jt2
where (jt1.FInteger = jt2.FInteger) 
GROUP BY jt1.FString
order by jt1.FString, s1;
#DBISAM
select jt1.FString, Min(jt1.FInteger) s1
from jt1,Jt2
where (jt1.FInteger = jt2.FInteger) 
GROUP BY jt1.FString
order by jt1.FString, s1