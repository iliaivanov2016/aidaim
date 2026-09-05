DROP TABLE T1 CASCADE;

CREATE TABLE T1 (
	FString STRING (30),
	FInteger INTEGER,
	FDateTime DATETIME
);
INSERT INTO T1 VALUES (
	'France',
	1,
	TODATE('2/16/2011 17:47:50:859','M/D/YYYY H24:N:S:Z')
);
INSERT INTO T1 VALUES (
	'England',
	2,
	TODATE('2/16/2011 17:47:50:859','M/D/YYYY H24:N:S:Z')
);
INSERT INTO T1 VALUES (
	'Russia',
	3,
	TODATE('2/16/2011 17:47:50:859','M/D/YYYY H24:N:S:Z')
);
INSERT INTO T1 VALUES (
	'Estonia',
	4,
	TODATE('2/16/2011 17:47:50:859','M/D/YYYY H24:N:S:Z')
);
INSERT INTO T1 VALUES (
	'Portugal',
	5,
	TODATE('2/16/2011 17:47:50:859','M/D/YYYY H24:N:S:Z')
);


Create Function GetDateFromYear(INValue:Integer):DateTime;
var
tempDate:String;
Begin
Result := Null;
If INValue Is Not Null Then
Begin
tempDate := '31-12-' + Cast(INValue, String);
Result := ToDate(tempDate, 'dd-mm-yyyy');
End;
End;

Create Function GetAgeFromYear(INBirthDate:DateTime; INYear:Integer; INLocYears:String):String;
var
tempDate:DateTime;
Begin
Result := Null;
tempDate := GetDateFromYear(INYear);
If (INBirthDate Is Not Null) And (tempDate Is Not Null) Then
Begin
Result := Cast(DateDiff(YEAR, INBirthDate, tempDate), String) + ' ' + INLocYears;
End;
End;

Create Function GetCountryAge(INCountryName:String; INBirthDate:DateTime; INYear:Integer; INLocYears:String):String;
var
tempAge:String;
tempString:String;
Begin
tempAge := Null;
tempString := Null;
tempAge := GetAgeFromYear(INBirthDate, INYear, INLocYears);
If (INCountryName Is Not Null) and (Length(INCountryName) > 0) Then tempString := INCountryName;
If tempAge Is Not Null Then
Begin
If (tempString Is Not Null) and (Length(tempString) > 0) Then
tempString := tempString + ' (' + tempAge + ')'
Else
tempString := tempAge;
End;
Result := tempString;
End;
