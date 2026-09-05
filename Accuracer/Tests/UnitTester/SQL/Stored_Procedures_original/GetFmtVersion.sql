----------------------------------------------------------------------------------------------------------------------
-- return 'version X.XX' constant
----------------------------------------------------------------------------------------------------------------------
CREATE FUNCTION GetFmtVersion(Version: DOUBLE): WIDECHAR(12);
BEGIN
--	Result := Format("%s%1.2f" ,GetStringConstant,Version);
END;
