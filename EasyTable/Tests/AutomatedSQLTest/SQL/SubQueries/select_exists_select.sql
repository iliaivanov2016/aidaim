select * from jt1 where EXISTS (SELECT ID from jt2 where jt2.id > 0);
