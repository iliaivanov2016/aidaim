SELECT FInteger, ID, (1.0 * Finteger / ID) AS percentage 
FROM jt1
ORDER BY ID

#Paradox

SELECT FInteger, ID, (1.0 * Finteger / ID) AS percentage
FROM jt1
ORDER BY ID
