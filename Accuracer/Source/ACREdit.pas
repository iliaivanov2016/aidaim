//==============================================================================
//
//              Accuracer component property editors
//
//             Copyright 2000-2010 AidAim Software.
//
//==============================================================================

{$I ACRVer.inc}

unit ACREdit;

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
 ACRFldLinks, ACRMain, ACRConst,
 ACRDatabaseDesigner,
 ACRSQLDesigner,
 {$IFDEF D6H}
  DesignIntf, DesignEditors, Variants
 {$ELSE}
  DSGNINTF
 {$ENDIF}
 {$IFDEF DEBUG_LOG}
 ,ACRDebug
 {$ENDIF}
 ;

 type


////////////////////////////////////////////////////////////////////////////////
//
// TACRFieldLinkProperty
//
////////////////////////////////////////////////////////////////////////////////


  TACRFieldLinkProperty = class(TACRBaseFieldLinkProperty)
  private
    FTable: TACRTable;
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
// TACRDBStringProperty
//
////////////////////////////////////////////////////////////////////////////////


  TACRDBStringProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValueList(List: TStrings); virtual;
    procedure GetValues(Proc: TGetStrProc); override;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRIndexFieldNamesProperty
//
////////////////////////////////////////////////////////////////////////////////


  // editor for indexFieldNames property
  TACRIndexFieldNamesProperty = class(TACRDBStringProperty)
  public
    procedure GetValueList(List: TStrings); override;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRIndexNameProperty
//
////////////////////////////////////////////////////////////////////////////////


  // editor for indexName property
  TACRIndexNameProperty = class(TACRDBStringProperty)
  public
    procedure GetValueList(List: TStrings); override;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRTableNameProperty
//
////////////////////////////////////////////////////////////////////////////////


  // editor for TableName property
  TACRTableNameProperty = class(TACRDBStringProperty)
  public
    procedure GetValueList(List: TStrings); override;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRDatabaseNameProperty
//
////////////////////////////////////////////////////////////////////////////////


  // editor for DatabaseName property
  TACRDatabaseNameProperty = class(TACRDBStringProperty)
  public
    procedure GetValueList(List: TStrings); override;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRDatabaseFileNameProperty
//
////////////////////////////////////////////////////////////////////////////////


{$IFNDEF SQLMEMTABLE}
 // file open dialog - for selecting database file name
 TACRDatabaseFileNameProperty = class (TStringProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
 end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRServerConfigFileNameProperty
//
////////////////////////////////////////////////////////////////////////////////


 TACRServerConfigFileNameProperty = class (TACRDatabaseFileNameProperty)
  public
    procedure Edit; override;
 end;

////////////////////////////////////////////////////////////////////////////////
//
// TACRSessionNameProperty
//
////////////////////////////////////////////////////////////////////////////////


 // TACRSessionNameProperty
 TACRSessionNameProperty = class(TACRDBStringProperty)
   public
      procedure GetValueList(List: TStrings); override;
   end;
{$ENDIF}



////////////////////////////////////////////////////////////////////////////////
//
// TACRDatabaseDesigner
//
////////////////////////////////////////////////////////////////////////////////


 TACRDatabaseDesigner = class(TComponentEditor)
   public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
 end;

////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLDesigner
//
////////////////////////////////////////////////////////////////////////////////


 TACRSQLDesigner = class(TComponentEditor)
   public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
 end;



////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLProperty
//
////////////////////////////////////////////////////////////////////////////////


 // file open dialog - for selecting database file name
 TACRSQLProperty = class (TStringProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
 end;


function GetPropertyValue(Instance: TPersistent; const PropName: AnsiString): TPersistent;


implementation

uses TypInfo;



////////////////////////////////////////////////////////////////////////////////
//
// TACRFieldLinkProperty
//
////////////////////////////////////////////////////////////////////////////////


procedure TACRFieldLinkProperty.GetFieldNamesForIndex(List: TStrings);
var
  i: Integer;
begin
  for i := 0 to FTable.IndexFieldCount - 1 do
    List.Add(FTable.IndexFields[i].FieldName);
end;

function TACRFieldLinkProperty.GetIndexBased: Boolean;
begin
  Result := True;
end;

function TACRFieldLinkProperty.GetIndexDefs: TIndexDefs;
begin
  Result := FTable.IndexDefs;
end;

function TACRFieldLinkProperty.GetIndexFieldNames: AnsiString;
begin
  Result := FTable.IndexFieldNames;
end;

function TACRFieldLinkProperty.GetIndexName: AnsiString;
begin
  Result := FTable.IndexName;
end;

function TACRFieldLinkProperty.GetMasterFields: AnsiString;
begin
  Result := FTable.MasterFields;
end;

procedure TACRFieldLinkProperty.SetIndexFieldNames(const Value: AnsiString);
begin
  FTable.IndexFieldNames := Value;
end;

procedure TACRFieldLinkProperty.SetIndexName(const Value: AnsiString);
begin
  FTable.IndexName := Value;
end;

procedure TACRFieldLinkProperty.SetMasterFields(const Value: AnsiString);
begin
  FTable.MasterFields := Value;
end;

procedure TACRFieldLinkProperty.Edit;
var
  Table:  TACRTable;
  s :     AnsiString;
begin
  Table := DataSet as TACRTable;
  FTable := TACRTable.Create(nil);
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
aaWriteToLog('TACRFieldLinkProperty.Edit 0');
{$ENDIF}
    FTable.Open;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRFieldLinkProperty.Edit 1');
{$ENDIF}
    if (Table.IndexFieldNames <> '') then
     FTable.IndexFieldNames := Table.IndexFieldNames
    else
     FTable.IndexName := Table.IndexName;
    FTable.MasterFields := Table.MasterFields;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRFieldLinkProperty.Edit 2');
{$ENDIF}
    inherited Edit;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRFieldLinkProperty.Edit 3');
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
aaWriteToLog('TACRFieldLinkProperty.Edit 4');
{$ENDIF}
  finally
    FTable.Free;
  end;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRFieldLinkProperty.Edit finish');
{$ENDIF}
end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRDBStringProperty
//
////////////////////////////////////////////////////////////////////////////////


function TACRDBStringProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList, paMultiSelect];
end;

procedure TACRDBStringProperty.GetValueList(List: TStrings);
begin
end;

procedure TACRDBStringProperty.GetValues(Proc: TGetStrProc);
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
  DataSet: TACRTable;
  a : Boolean;
begin
  DataSet := Component as TACRTable;
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
// TACRIndexFieldNamesProperty
//
////////////////////////////////////////////////////////////////////////////////


procedure TACRIndexFieldNamesProperty.GetValueList(List: TStrings);
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
// TACRIndexNameProperty
//
////////////////////////////////////////////////////////////////////////////////


procedure TACRIndexNameProperty.GetValueList(List: TStrings);
begin
  GetIndexDefs(GetComponent(0)).GetItemNames(List);
end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRTableNameProperty
//
////////////////////////////////////////////////////////////////////////////////


procedure TACRTableNameProperty.GetValueList(List: TStrings);
var
  Table: TACRTable;
begin
  if (List <> nil) then
   begin
    List.Clear;
    Table := TACRTable(GetComponent(0));
    if (Table <> nil) then
     if (Table.DBSession <> nil) then
      begin
       Table.DBSession.GetTableNames(Table.DatabaseName,Table.InMemory,Table.Temporary,List);
      end;
   end;
end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRDatabaseNameProperty
//
////////////////////////////////////////////////////////////////////////////////


procedure TACRDatabaseNameProperty.GetValueList(List: TStrings);
var
  Table: TACRTable;
begin
  Table := TACRTable(GetComponent(0));
  Table.DBSession.GetDatabaseNames(List);
end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRDatabaseFileNameProperty
//
////////////////////////////////////////////////////////////////////////////////


{$IFNDEF SQLMEMTABLE}
//------------------------------------------------------------------------------
// file name editor (extension is subtracted from name)
//------------------------------------------------------------------------------
procedure TACRDatabaseFileNameProperty.Edit;
var td : TOpenDialog;
begin
 td := TOpenDialog.Create(Application);
 td.Options := [ofPathMustExist];
 td.DefaultExt := ACRDatabaseFileExtension;
 td.Filter := 'Accuracer database (*'+ACRDatabaseFileExtension+')|*'+
              ACRDatabaseFileExtension +
              '|'+'Any files (*.*)|*.*';
 td.FilterIndex := 0;
 if (td.Execute) then
   SetStrValue(td.FileName);
 td.Free;
end; // Edit


//------------------------------------------------------------------------------
// file name editor's attributes (paDialog - for ... button in design mode)
//------------------------------------------------------------------------------
function TACRDatabaseFileNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end; // GetAttributes



////////////////////////////////////////////////////////////////////////////////
//
// TACRServerConfigFileNameProperty
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// file name editor (extension is subtracted from name)
//------------------------------------------------------------------------------
procedure TACRServerConfigFileNameProperty.Edit;
{$IFDEF SERVER_VERSION}
var td : TOpenDialog;
{$ENDIF}
begin
{$IFDEF SERVER_VERSION}
 td := TOpenDialog.Create(Application);
 td.Options := [ofPathMustExist];
 td.DefaultExt := ACRDatabaseFileExtension;
 td.Filter := 'Accuracer server config file (*'+ACRServerConfigFileExtension+')|*'+
              ACRServerConfigFileExtension +
              '|'+'Any files (*.*)|*.*';
 td.FilterIndex := 0;
 if (td.Execute) then
   SetStrValue(td.FileName);
 td.Free;
{$ENDIF}
end; // Edit


////////////////////////////////////////////////////////////////////////////////
//
// TACRSessionNameProperty
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
//  TACRSession names
//------------------------------------------------------------------------------
procedure TACRSessionNameProperty.GetValueList(List: TStrings);
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
// TACRDatabaseDesigner
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// execute menu
//------------------------------------------------------------------------------
procedure TACRDatabaseDesigner.ExecuteVerb(Index: Integer);
var des: TACRFormDatabaseDesigner;
begin
  des := TACRFormDatabaseDesigner.Create(nil);
  des.Database := TACRDatabase(Component);
  des.ShowModal;
end; // ExecuteVerb


//------------------------------------------------------------------------------
// get menu items
//------------------------------------------------------------------------------
function TACRDatabaseDesigner.GetVerb(Index: Integer): string;
begin
  Result := '&Database Designer';
end; // GetVerb


//------------------------------------------------------------------------------
// get number of menu items
//------------------------------------------------------------------------------
function TACRDatabaseDesigner.GetVerbCount: Integer;
begin
  Result := 1;
end; // GetVerbCount


////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLDesigner
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// execute menu
//------------------------------------------------------------------------------
procedure TACRSQLDesigner.ExecuteVerb(Index: Integer);
var des: TACRfmSQLDesigner;
begin
  des := TACRfmSQLDesigner.Create(nil);
  des.SetQuery(TACRQuery(Component));
  des.ShowModal;
end; // ExecuteVerb


//------------------------------------------------------------------------------
// get menu items
//------------------------------------------------------------------------------
function TACRSQLDesigner.GetVerb(Index: Integer): string;
begin
  Result := '&SQL Designer';
end; // GetVerb


//------------------------------------------------------------------------------
// get number of menu items
//------------------------------------------------------------------------------
function TACRSQLDesigner.GetVerbCount: Integer;
begin
  Result := 1;
end; // GetVerbCount


////////////////////////////////////////////////////////////////////////////////
//
// TACRSQLProperty
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// edit
//------------------------------------------------------------------------------
procedure TACRSQLProperty.Edit;
var des: TACRfmSQLDesigner;
    q:   TACRQuery;
    c:   TPersistent;
begin
  c := GetComponent(0);
  if (c is TACRQuery) then
   q := TACRQuery(c)
  else
   q := nil; 
  des := TACRfmSQLDesigner.Create(nil);
  des.SetQuery(q);
  des.ShowModal;
end; // Edit


//------------------------------------------------------------------------------
// get attributes
//------------------------------------------------------------------------------
function TACRSQLProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end;


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACREdit initialization');
{$ENDIF}

end.
