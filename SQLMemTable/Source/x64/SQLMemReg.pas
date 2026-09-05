unit SQLMemReg;

{$I SQLMemVer.inc}

interface

procedure Register; // register SQLMemTable components in group SQLMemTable

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

// SQLMemTable units
 {$IFDEF DEBUG_LOG}
      SQLMemDebug,
 {$ENDIF}
      SQLMemMain,
      SQLMemTypes,
      SQLMemEdit,
      SQLMemDatabaseDesigner
{$IFDEF SERVER_VERSION}
      ,SQLMemServer
{$ENDIF}
      ;

//------------------------------------------------------------------------------
// registration
//------------------------------------------------------------------------------
procedure Register;
begin
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemReg.Register started');
{$ENDIF}

  RegisterComponents('SQLMemTable', [TSQLMemTable]);
  RegisterComponents('SQLMemTable', [TSQLMemQuery]);
  RegisterComponents('SQLMemTable', [TSQLMemDatabase]);
  {$IFNDEF SQLMEMTABLE}
    //
  {$ENDIF}

  //--- dataset ---
  RegisterPropertyEditor(TypeInfo(AnsiString), TSQLMemDataset, 'DatabaseName',
       TSQLMemDatabaseNameProperty);
{$IFNDEF SQLMEMTABLE}
  RegisterPropertyEditor(TypeInfo(AnsiString),TSQLMemDataSet,'SessionName',
                         TSQLMemSessionNameProperty);
{$IFDEF MSWINDOWS}
  RegisterPropertyEditor(TypeInfo(String), TSQLMemDatabase, 'DatabaseFileName',
       TSQLMemDatabaseFileNameProperty);
{$IFDEF D12H}
  RegisterPropertyEditor(TypeInfo(String), TSQLMemDatabase, 'DatabaseFileNameUnicode',
      TSQLMemDatabaseFileNameProperty);
{$ELSE}
  RegisterPropertyEditor(TypeInfo(String), TSQLMemDatabase, 'DatabaseFileNameAnsi',
      TSQLMemDatabaseFileNameProperty);
{$ENDIF}
{$ENDIF}

  RegisterPropertyEditor(TypeInfo(AnsiString),TSQLMemDatabase,'SessionName',
                         TSQLMemSessionNameProperty);
{$ENDIF}
{$IFDEF SERVER_VERSION}
  RegisterComponents('SQLMemTable', [TSQLMemServer]);
  RegisterPropertyEditor(TypeInfo(AnsiString), TSQLMemServer, 'ConfigFileName',
       TSQLMemServerConfigFileNameProperty);
//  RegisterComponents('SQLMemTable', [TSQLMemAntifreeze]);
{$ENDIF}
  RegisterComponents('SQLMemTable', [TSQLMemBatchMove]);
  //--- table ---
  RegisterPropertyEditor(TypeInfo(WideString), TSQLMemTable, 'TableName',
       TSQLMemTableNameProperty);
  RegisterPropertyEditor(TypeInfo(WideString), TSQLMemTable, 'MasterFields',
        TSQLMemFieldLinkProperty);
  RegisterPropertyEditor(TypeInfo(WideString), TSQLMemTable, 'IndexName', TSQLMemIndexNameProperty);
  RegisterPropertyEditor(TypeInfo(WideString), TSQLMemTable, 'IndexFieldNames', TSQLMemIndexFieldNamesProperty);
  // sql
  RegisterPropertyEditor(TypeInfo(TSQLMemWideStringList), TSQLMemQuery, 'SQL',
       TSQLMemSQLProperty);
  // database designer
  RegisterComponentEditor(TSQLMemDatabase, TSQLMemDatabaseDesigner);

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemReg.Register finished');
{$ENDIF}
end; // Register

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemReg initialization');
{$ENDIF}

end.
