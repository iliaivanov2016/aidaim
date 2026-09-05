---------------------------------------------------------------------------------------------------------
-- return Year extracted from DATETIME as INTEGER
---------------------------------------------------------------------------------------------------------
CREATE FUNCTION MyYear(InDateTime: DATETIME): INTEGER;
begin
  Result := EXTRACT(YEAR, InDateTime);
end;
