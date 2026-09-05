unit ACRReg;

{$I ACRVer.inc}

interface

procedure Register; // register Accuracer components in group Accuracer

implementation

uses  Classes, TypInfo,
{$IFDEF MSWINDOWS}
      Controls,
{$ENDIF}
{$IFDEF D6H}
      DesignIntf,
 {$ELSE}
      Dsgnintf,
 {$ENDIF}

// Accuracer units
 {$IFDEF DEBUG_LOG}
      ACRDebug,
 {$ENDIF}
      ACRMain,
      ACRTypes,
      ACREdit,
      ACRDatabaseDesigner
{$IFDEF SERVER_VERSION}
      ,ACRServer
{$ENDIF}
      ;

//------------------------------------------------------------------------------
// registration
//------------------------------------------------------------------------------
procedure Register;
begin
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRReg.Register started');
{$ENDIF}

  RegisterComponents('Accuracer', [TACRTable]);
  RegisterComponents('Accuracer', [TACRQuery]);
  RegisterComponents('Accuracer', [TACRDatabase]);
  {$IFNDEF SQLMEMTABLE}
    RegisterComponents('Accuracer', [TACRSession]);
  {$ENDIF}

  //--- dataset ---
  RegisterPropertyEditor(TypeInfo(AnsiString), TACRDataset, 'DatabaseName',
       TACRDatabaseNameProperty);
{$IFNDEF SQLMEMTABLE}
  RegisterPropertyEditor(TypeInfo(AnsiString),TACRDataSet,'SessionName',
                         TACRSessionNameProperty);
{$IFDEF MSWINDOWS}
  RegisterPropertyEditor(TypeInfo(String), TACRDatabase, 'DatabaseFileName',
       TACRDatabaseFileNameProperty);
{$IFDEF D12H}
  RegisterPropertyEditor(TypeInfo(String), TACRDatabase, 'DatabaseFileNameUnicode',
      TACRDatabaseFileNameProperty);
{$ELSE}
  RegisterPropertyEditor(TypeInfo(String), TACRDatabase, 'DatabaseFileNameAnsi',
      TACRDatabaseFileNameProperty);
{$ENDIF}
{$ENDIF}

  RegisterPropertyEditor(TypeInfo(AnsiString),TACRDatabase,'SessionName',
                         TACRSessionNameProperty);
{$ENDIF}
{$IFDEF SERVER_VERSION}
  RegisterComponents('Accuracer', [TACRServer]);
  RegisterPropertyEditor(TypeInfo(AnsiString), TACRServer, 'ConfigFileName',
       TACRServerConfigFileNameProperty);
//  RegisterComponents('Accuracer', [TACRAntifreeze]);
{$ENDIF}
  RegisterComponents('Accuracer', [TACRBatchMove]);
  //--- table ---
  RegisterPropertyEditor(TypeInfo(WideString), TACRTable, 'TableName',
       TACRTableNameProperty);
  RegisterPropertyEditor(TypeInfo(WideString), TACRTable, 'MasterFields',
        TACRFieldLinkProperty);
  RegisterPropertyEditor(TypeInfo(WideString), TACRTable, 'IndexName', TACRIndexNameProperty);
  RegisterPropertyEditor(TypeInfo(WideString), TACRTable, 'IndexFieldNames', TACRIndexFieldNamesProperty);
  // sql
  RegisterPropertyEditor(TypeInfo(TACRWideStringList), TACRQuery, 'SQL',
       TACRSQLProperty);
  // database designer
  RegisterComponentEditor(TACRDatabase, TACRDatabaseDesigner);

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRReg.Register finished');
{$ENDIF}
end; // Register

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRReg initialization');
{$ENDIF}

end.
