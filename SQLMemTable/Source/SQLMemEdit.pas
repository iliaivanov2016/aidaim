//==============================================================================
//
//              SQLMemTable component property editors
//
//             Copyright 2000-2010 AidAim Software.
//
//==============================================================================

{$I SQLMemVer.inc}

unit SQLMemEdit;

interface

uses
 Classes, DB, Controls,
{$IFDEF MSWINDOWS}
 Dialogs, Forms,
{$ENDIF}
{$IFDEF LINUX}
 QDialogs, QForms,
{$ENDIF}
 SysUtils,
 SQLMemFldLinks, SQLMemMain, SQLMemConst,
 SQLMemDatabaseDesigner,
 SQLMemSQLDesigner,
 {$IFDEF D6H}
  DesignIntf, DesignEditors, Variants
 {$ELSE}
  DSGNINTF
 {$ENDIF}
 {$IFDEF DEBUG_LOG}
 ,SQLMemDebug
 {$ENDIF}
 ;

 type


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemFieldLinkProperty
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemFieldLinkProperty = class(TSQLMemBaseFieldLinkProperty)
  private
    FTable: TSQLMemTable;
  protected
    procedure GetFieldNamesForIndex(List: TStrings); override;
    function GetIndexBased: Boolean; override;
    function GetIndexDefs: TIndexDefs; override;
    function GetIndexFieldNames: AnsiString; override;
    function GetIndexName: AnsiString; override;
    function GetMasterFields: AnsiString; override;
    procedure SetIndexFieldNames(const Value: AnsiString); override;
    procedure SetIndexName(const Value: AnsiString); override;
    procedure SetMasterFields(const Value: AnsiString); override;
  public
    procedure Edit; override;

    property IndexBased: Boolean read GetIndexBased;
    property IndexDefs: TIndexDefs read GetIndexDefs;
    property IndexFieldNames: AnsiString read GetIndexFieldNames write SetIndexFieldNames;
    property IndexName: AnsiString read GetIndexName write SetIndexName;
    property MasterFields: AnsiString read GetMasterFields write SetMasterFields;

  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDBStringProperty
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemDBStringProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValueList(List: TStrings); virtual;
    procedure GetValues(Proc: TGetStrProc); override;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemIndexFieldNamesProperty
//
////////////////////////////////////////////////////////////////////////////////


  // editor for indexFieldNames property
  TSQLMemIndexFieldNamesProperty = class(TSQLMemDBStringProperty)
  public
    procedure GetValueList(List: TStrings); override;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemIndexNameProperty
//
////////////////////////////////////////////////////////////////////////////////


  // editor for indexName property
  TSQLMemIndexNameProperty = class(TSQLMemDBStringProperty)
  public
    procedure GetValueList(List: TStrings); override;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTableNameProperty
//
////////////////////////////////////////////////////////////////////////////////


  // editor for TableName property
  TSQLMemTableNameProperty = class(TSQLMemDBStringProperty)
  public
    procedure GetValueList(List: TStrings); override;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDatabaseNameProperty
//
////////////////////////////////////////////////////////////////////////////////


  // editor for DatabaseName property
  TSQLMemDatabaseNameProperty = class(TSQLMemDBStringProperty)
  public
    procedure GetValueList(List: TStrings); override;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDatabaseFileNameProperty
//
////////////////////////////////////////////////////////////////////////////////


{$IFNDEF SQLMEMTABLE}
 // file open dialog - for selecting database file name
 TSQLMemDatabaseFileNameProperty = class (TStringProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
 end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemServerConfigFileNameProperty
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemServerConfigFileNameProperty = class (TSQLMemDatabaseFileNameProperty)
  public
    procedure Edit; override;
 end;

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSessionNameProperty
//
////////////////////////////////////////////////////////////////////////////////


 // TSQLMemSessionNameProperty
 TSQLMemSessionNameProperty = class(TSQLMemDBStringProperty)
   public
      procedure GetValueList(List: TStrings); override;
   end;
{$ENDIF}



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDatabaseDesigner
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemDatabaseDesigner = class(TComponentEditor)
   public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
 end;

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLDesigner
//
////////////////////////////////////////////////////////////////////////////////


 TSQLMemSQLDesigner = class(TComponentEditor)
   public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
 end;



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLProperty
//
////////////////////////////////////////////////////////////////////////////////


 // file open dialog - for selecting database file name
 TSQLMemSQLProperty = class (TStringProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
 end;


function GetPropertyValue(Instance: TPersistent; const PropName: AnsiString): TPersistent;


implementation

uses TypInfo;



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemFieldLinkProperty
//
////////////////////////////////////////////////////////////////////////////////


procedure TSQLMemFieldLinkProperty.GetFieldNamesForIndex(List: TStrings);
var
  i: Integer;
begin
  for i := 0 to FTable.IndexFieldCount - 1 do
    List.Add(FTable.IndexFields[i].FieldName);
end;

function TSQLMemFieldLinkProperty.GetIndexBased: Boolean;
begin
  Result := True;
end;

function TSQLMemFieldLinkProperty.GetIndexDefs: TIndexDefs;
begin
  Result := FTable.IndexDefs;
end;

function TSQLMemFieldLinkProperty.GetIndexFieldNames: AnsiString;
begin
  Result := FTable.IndexFieldNames;
end;

function TSQLMemFieldLinkProperty.GetIndexName: AnsiString;
begin
  Result := FTable.IndexName;
end;

function TSQLMemFieldLinkProperty.GetMasterFields: AnsiString;
begin
  Result := FTable.MasterFields;
end;

procedure TSQLMemFieldLinkProperty.SetIndexFieldNames(const Value: AnsiString);
begin
  FTable.IndexFieldNames := Value;
end;

procedure TSQLMemFieldLinkProperty.SetIndexName(const Value: AnsiString);
begin
  FTable.IndexName := Value;
end;

procedure TSQLMemFieldLinkProperty.SetMasterFields(const Value: AnsiString);
begin
  FTable.MasterFields := Value;
end;

procedure TSQLMemFieldLinkProperty.Edit;
var
  Table:  TSQLMemTable;
  s :     AnsiString;
begin
  Table := DataSet as TSQLMemTable;
  FTable := TSQLMemTable.Create(nil);
  try
    FTable.DatabaseName := Table.DatabaseName;
    FTable.InMemory := Table.InMemory;
    FTable.Temporary := Table.Temporary;
    FTable.TableName := Table.TableName;
    FTable.ReadOnly := Table.ReadOnly;
    FTable.FieldDefs.Assign(Table.FieldDefs);
    FTable.IndexDefs.Assign(Table.IndexDefs);
    FTable.AdvFieldDefs.Assign(Table.AdvFieldDefs);
    FTable.AdvIndexDefs.Assign(Table.AdvIndexDefs);

{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TSQLMemFieldLinkProperty.Edit 0');
{$ENDIF}
    FTable.Open;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TSQLMemFieldLinkProperty.Edit 1');
{$ENDIF}
    if (Table.IndexFieldNames <> '') then
     FTable.IndexFieldNames := Table.IndexFieldNames
    else
     FTable.IndexName := Table.IndexName;
    FTable.MasterFields := Table.MasterFields;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TSQLMemFieldLinkProperty.Edit 2');
{$ENDIF}
    inherited Edit;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TSQLMemFieldLinkProperty.Edit 3');
{$ENDIF}
   if Changed then
    begin
      Table.MasterFields := FTable.MasterFields;
      if FTable.IndexFieldNames <> '' then
       begin
        // index field names
        Table.IndexFieldNames := FTable.IndexFieldNames;
        s := FTable.IndexFieldNames;
       end
      else
       begin
        // index name
        Table.IndexName := FTable.IndexName;
        s := FTable.IndexName;
       end;
    end;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TSQLMemFieldLinkProperty.Edit 4');
{$ENDIF}
  finally
    FTable.Free;
  end;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TSQLMemFieldLinkProperty.Edit finish');
{$ENDIF}
end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDBStringProperty
//
////////////////////////////////////////////////////////////////////////////////


function TSQLMemDBStringProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList, paMultiSelect];
end;

procedure TSQLMemDBStringProperty.GetValueList(List: TStrings);
begin
end;

procedure TSQLMemDBStringProperty.GetValues(Proc: TGetStrProc);
var
  I:      Integer;
  Values: TStringList;
begin
  Values := TStringList.Create;
  try
    GetValueList(Values);
    for I := 0 to Values.Count - 1 do
      Proc(Values[I]);
  finally
    Values.Free;
  end;
end;


function GetIndexDefs(Component: TPersistent): TIndexDefs;
var
  DataSet: TSQLMemTable;
  a : Boolean;
begin
  DataSet := Component as TSQLMemTable;
  a := DataSet.Active;
  if (not a) then
   DataSet.Open;
  Result := GetPropertyValue(DataSet, 'IndexDefs') as TIndexDefs;
  if Assigned(Result) then
  begin
    Result.Updated := False;
    Result.Update;
  end;
  if (not a) then
   DataSet.Close;
end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemIndexFieldNamesProperty
//
////////////////////////////////////////////////////////////////////////////////


procedure TSQLMemIndexFieldNamesProperty.GetValueList(List: TStrings);
var
  I: Integer;
  IndexDefs: TIndexDefs;
begin
  IndexDefs := GetIndexDefs(GetComponent(0));
  for I := 0 to IndexDefs.Count - 1 do
    with IndexDefs[I] do
      if (Options * [ixExpression, ixDescending] = []) and (Fields <> '') then
        List.Add(Fields);
end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemIndexNameProperty
//
////////////////////////////////////////////////////////////////////////////////


procedure TSQLMemIndexNameProperty.GetValueList(List: TStrings);
begin
  GetIndexDefs(GetComponent(0)).GetItemNames(List);
end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTableNameProperty
//
////////////////////////////////////////////////////////////////////////////////


procedure TSQLMemTableNameProperty.GetValueList(List: TStrings);
var
  Table: TSQLMemTable;
begin
  if (List <> nil) then
   begin
    List.Clear;
    Table := TSQLMemTable(GetComponent(0));
    if (Table <> nil) then
     if (Table.DBSession <> nil) then
      begin
       Table.DBSession.GetTableNames(Table.DatabaseName,Table.InMemory,Table.Temporary,List);
      end;
   end;
end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDatabaseNameProperty
//
////////////////////////////////////////////////////////////////////////////////


procedure TSQLMemDatabaseNameProperty.GetValueList(List: TStrings);
var
  Table: TSQLMemTable;
begin
  Table := TSQLMemTable(GetComponent(0));
  Table.DBSession.GetDatabaseNames(List);
end;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDatabaseFileNameProperty
//
////////////////////////////////////////////////////////////////////////////////


{$IFNDEF SQLMEMTABLE}
//------------------------------------------------------------------------------
// file name editor (extension is subtracted from name)
//------------------------------------------------------------------------------
procedure TSQLMemDatabaseFileNameProperty.Edit;
var td : TOpenDialog;
begin
 td := TOpenDialog.Create(Application);
 td.Options := [ofPathMustExist];
 td.DefaultExt := SQLMemDatabaseFileExtension;
 td.Filter := 'SQLMemTable database (*'+SQLMemDatabaseFileExtension+')|*'+
              SQLMemDatabaseFileExtension +
              '|'+'Any files (*.*)|*.*';
 td.FilterIndex := 0;
 if (td.Execute) then
   SetStrValue(td.FileName);
 td.Free;
end; // Edit


//------------------------------------------------------------------------------
// file name editor's attributes (paDialog - for ... button in design mode)
//------------------------------------------------------------------------------
function TSQLMemDatabaseFileNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end; // GetAttributes



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemServerConfigFileNameProperty
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// file name editor (extension is subtracted from name)
//------------------------------------------------------------------------------
procedure TSQLMemServerConfigFileNameProperty.Edit;
{$IFDEF SERVER_VERSION}
var td : TOpenDialog;
{$ENDIF}
begin
{$IFDEF SERVER_VERSION}
 td := TOpenDialog.Create(Application);
 td.Options := [ofPathMustExist];
 td.DefaultExt := SQLMemDatabaseFileExtension;
 td.Filter := 'SQLMemTable server config file (*'+SQLMemServerConfigFileExtension+')|*'+
              SQLMemServerConfigFileExtension +
              '|'+'Any files (*.*)|*.*';
 td.FilterIndex := 0;
 if (td.Execute) then
   SetStrValue(td.FileName);
 td.Free;
{$ENDIF}
end; // Edit


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSessionNameProperty
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
//  TSQLMemSession names
//------------------------------------------------------------------------------
procedure TSQLMemSessionNameProperty.GetValueList(List: TStrings);
begin
  Sessions.GetSessionNames(List);
end;
{$ENDIF}

{ Utility Functions }

function GetPropertyValue(Instance: TPersistent; const PropName: AnsiString): TPersistent;
var
  PropInfo: PPropInfo;
begin
  Result := nil;
  PropInfo := TypInfo.GetPropInfo(Instance.ClassInfo, PropName);
  if (PropInfo <> nil) and (PropInfo^.PropType^.Kind = tkClass) then
    Result := TObject(GetOrdProp(Instance, PropInfo)) as TPersistent;
end;

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemDatabaseDesigner
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// execute menu
//------------------------------------------------------------------------------
procedure TSQLMemDatabaseDesigner.ExecuteVerb(Index: Integer);
var des: TSQLMemFormDatabaseDesigner;
begin
  des := TSQLMemFormDatabaseDesigner.Create(nil);
  des.Database := TSQLMemDatabase(Component);
  des.ShowModal;
end; // ExecuteVerb


//------------------------------------------------------------------------------
// get menu items
//------------------------------------------------------------------------------
function TSQLMemDatabaseDesigner.GetVerb(Index: Integer): string;
begin
  Result := '&Database Designer';
end; // GetVerb


//------------------------------------------------------------------------------
// get number of menu items
//------------------------------------------------------------------------------
function TSQLMemDatabaseDesigner.GetVerbCount: Integer;
begin
  Result := 1;
end; // GetVerbCount


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLDesigner
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// execute menu
//------------------------------------------------------------------------------
procedure TSQLMemSQLDesigner.ExecuteVerb(Index: Integer);
var des: TSQLMemfmSQLDesigner;
begin
  des := TSQLMemfmSQLDesigner.Create(nil);
  des.SetQuery(TSQLMemQuery(Component));
  des.ShowModal;
end; // ExecuteVerb


//------------------------------------------------------------------------------
// get menu items
//------------------------------------------------------------------------------
function TSQLMemSQLDesigner.GetVerb(Index: Integer): string;
begin
  Result := '&SQL Designer';
end; // GetVerb


//------------------------------------------------------------------------------
// get number of menu items
//------------------------------------------------------------------------------
function TSQLMemSQLDesigner.GetVerbCount: Integer;
begin
  Result := 1;
end; // GetVerbCount


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemSQLProperty
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// edit
//------------------------------------------------------------------------------
procedure TSQLMemSQLProperty.Edit;
var des: TSQLMemfmSQLDesigner;
    q:   TSQLMemQuery;
    c:   TPersistent;
begin
  c := GetComponent(0);
  if (c is TSQLMemQuery) then
   q := TSQLMemQuery(c)
  else
   q := nil; 
  des := TSQLMemfmSQLDesigner.Create(nil);
  des.SetQuery(q);
  des.ShowModal;
end; // Edit


//------------------------------------------------------------------------------
// get attributes
//------------------------------------------------------------------------------
function TSQLMemSQLProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end;


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemEdit initialization');
{$ENDIF}

end.
