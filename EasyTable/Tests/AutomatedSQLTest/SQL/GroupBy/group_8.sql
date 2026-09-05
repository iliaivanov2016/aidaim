SELECT jt1.fstring,count(jt2.fstring) cnt
from jt1,jt2
WHERE (jt1.fstring = jt2.fstring) or (jt1.FSTRING like jt2.FSTRING + '%')
GROUP BY jt1.fstring
ORDER BY jt1.fstring