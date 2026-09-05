---------------------------------------------------------------------------------------------------------
-- return 'Even' / 'Odd' 
---------------------------------------------------------------------------------------------------------
CREATE FUNCTION GetEvenOdd1(Num: Integer): CHAR(4);
BEGIN
  IF ((Num mod 2) = 0) THEN
   BEGIN
    RESULT := 'Even';
   END
  ELSE
   BEGIN
    RESULT := 'Odd';
   END;  
END;
