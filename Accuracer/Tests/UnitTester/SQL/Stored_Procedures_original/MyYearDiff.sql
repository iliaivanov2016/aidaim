---------------------------------------------------------------------------------------------------------
-- return difference of Years extracted from 2 DATETIME values (v2 - v1)
---------------------------------------------------------------------------------------------------------
CREATE FUNCTION MyYearDiff(InDateTime1,InDateTime2: DATETIME): INTEGER;
begin
  Result := MyYear(InDateTime2) - MyYear(InDateTime1);
end;
