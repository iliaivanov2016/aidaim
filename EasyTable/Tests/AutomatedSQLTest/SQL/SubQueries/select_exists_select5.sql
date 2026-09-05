select * from jt1 where NOT EXISTS (SELECT ID from jt2 where jt2.id > 0);
