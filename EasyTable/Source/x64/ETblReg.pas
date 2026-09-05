//==============================================================================
//
//              EasyTable component registration
//
//             Copyright 2000-2001 AidAim Software.
//
//==============================================================================

{$I ETblVer.inc}

unit ETblReg;

interface

procedure Register; // register TEasyTable in group Data Access

implementation

uses Classes, TypInfo, Controls,
{$IFDEF D6H}
 DesignIntf,
 {$ELSE}
 Dsgnintf,
 {$ENDIF}
 EasyTable, ETblEdit;

//------------------------------------------------------------------------------
// registration
//------------------------------------------------------------------------------
procedure Register;
begin
  RegisterComponents('EasyTable', [TEasyTable]);
  RegisterComponents('EasyTable', [TEasyDatabase]);
{$IFDEF FULL_VERSION}
  RegisterComponents('EasyTable', [TEasySession]);
  RegisterComponents('EasyTable', [TEasyQuery]);

  //--- dataset ---
  RegisterPropertyEditor(TypeInfo(AnsiString),TEasyDatabase,'SessionName',
                         TEasySessionNameProperty);
  RegisterPropertyEditor(TypeInfo(AnsiString),TEasyDataSet,'SessionName',
                         TEasySessionNameProperty);
{$ENDIF}
  //--- table ---
  RegisterPropertyEditor(TypeInfo(AnsiString), TEasyTable, 'TableName',
       TTableNameProperty);
  RegisterPropertyEditor(TypeInfo(AnsiString), TEasyTable, 'DatabaseName',
       TDatabaseNameProperty);
  RegisterPropertyEditor(TypeInfo(AnsiString), TEasyTable, 'DatabaseFileName',
       TDatabaseFileNameProperty);
  RegisterPropertyEditor(TypeInfo(AnsiString), TEasyTable, 'MasterFields',
        TEasyTableFieldLinkProperty);
  RegisterPropertyEditor(TypeInfo(AnsiString), TEasyTable, 'IndexName', TIndexNameProperty);
  RegisterPropertyEditor(TypeInfo(AnsiString), TEasyTable, 'IndexFieldNames', TIndexFieldNamesProperty);

{$IFDEF FULL_VERSION}
  //--- query ---
  RegisterPropertyEditor(TypeInfo(AnsiString), TEasyQuery, 'DatabaseFileName',
       TDatabaseFileNameProperty);
  RegisterPropertyEditor(TypeInfo(AnsiString), TEasyQuery, 'DatabaseName',
       TDatabaseNameProperty);
{$ENDIF}
  //--- database ---
  RegisterPropertyEditor(TypeInfo(AnsiString), TEasyDatabase, 'Directory',
      TDirectoryProperty);
  RegisterPropertyEditor(TypeInfo(AnsiString), TEasyDatabase, 'DatabaseFileName',
       TDatabaseFileNameProperty);
end; // Register

end.
