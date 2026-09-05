SELECT * from Jpeg
WHERE ID = (SELECT MIN(ID) from jpeg)