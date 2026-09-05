//==============================================================================
//
//              ETblTable component property editors
//
//             Copyright 2000-2001 AidAim Software.
//
//==============================================================================

{$I ETblVer.inc}

unit ETblEdit;

interface

uses
 Classes, Db, Dialogs, Forms, SysUtils,
 EasyTable, ETblFldLinks,
{directory open dialog}
 ETblFolderDialog,
{Author:	Poul Bak}
{Copyright © 1999-2000 : BakSoft-Denmark (Poul Bak). All rights reserved.}
{http://home11.inet.tele.dk/BakSoft/}
{Mailto: baksoft-denmark@dk2net.dk}
 {$IFDEF D6H}
  DesignIntf, DesignEditors, FMTBcd, Variants
 {$ELSE}
  DSGNINTF
 {$ENDIF}
 ;

 type
 // file open dialog - for selecting table name
 TDirectoryProperty = class (TStringProperty)
   public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
   end; //TDirectoryProperty

{ TEasyTableFieldLinkProperty }

  TEasyTableFieldLinkProperty = class(TFieldLinkProperty)
  private
    FTable: TEasyTable;
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
    property IndexBased: Boolean read GetIndexBased;
    property IndexDefs: TIndexDefs read GetIndexDefs;
    property IndexFieldNames: AnsiString read GetIndexFieldNames write SetIndexFieldNames;
    property IndexName: AnsiString read GetIndexName write SetIndexName;
    property MasterFields: AnsiString read GetMasterFields write SetMasterFields;

    procedure Edit; override;
  end;
  // dbstring property
  TDBStringProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValueList(List: TStrings); virtual;
    procedure GetValues(Proc: TGetStrProc); override;
  end;
  // editor for indexFieldNames property
  TIndexFieldNamesProperty = class(TDBStringProperty)
  public
    procedure GetValueList(List: TStrings); override;
  end;
  // editor for indexName property
  TIndexNameProperty = class(TDBStringProperty)
  public
    procedure GetValueList(List: TStrings); override;
  end;
  // editor for TableName property
  TTableNameProperty = class(TDBStringProperty)
  public
    procedure GetValueList(List: TStrings); override;
  end;
  // editor for DatabaseName property
  TDatabaseNameProperty = class(TDBStringProperty)
  public
    procedure GetValueList(List: TStrings); override;
  end;

 // file open dialog - for selecting database file name
 TDatabaseFileNameProperty = class (TStringProperty)
   public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
   end;

 // TEasySessionNameProperty
 TEasySessionNameProperty = class(TDBStringProperty)
   public
      procedure GetValueList(List: TStrings); override;
   end;


function GetPropertyValue(Instance: TPersistent; const PropName: AnsiString): TPersistent;


implementation

uses TypInfo;

//------------------------------------------------------------------------------
// file name editor (extension is subtracted from name)
//------------------------------------------------------------------------------
procedure TDirectoryProperty.Edit;
var fb : TPBFolderDialog;
begin
 fb := TPBFolderDialog.Create(Application);
 fb.Flags := [ShowPath];
// fb.BrowseFlags := [bfDirsOnly];
 fb.Folder := GetStrValue;
 if (fb.Execute) then
  begin
   SetStrValue(fb.Folder);
  end;
 fb.Free;
end; // TDirectoryProperty.Edit
 
 
//------------------------------------------------------------------------------
// file name editor's attributes (paDialog - for ... button in design mode) 
//------------------------------------------------------------------------------
function TDirectoryProperty.GetAttributes: TPropertyAttributes;
begin 
  Result := [paDialog, paRevertable];
end; //TDirectoryProperty.GetAttributes 
	
 
{ TEasyTableFieldLinkProperty }
 
procedure TEasyTableFieldLinkProperty.Edit; 
var 
  Table: TEasyTable;
  s : AnsiString;
begin
  Table := DataSet as TEasyTable; 
  FTable := TEasyTable.Create(nil); 
  try 
    FTable.DatabaseName := Table.DatabaseName;
    FTable.TableName := Table.TableName; 
    FTable.Open;
    if Table.IndexFieldNames <> '' then
     FTable.IndexFieldNames := Table.IndexFieldNames 
    else
     FTable.IndexName := Table.IndexName; 
    FTable.MasterFields := Table.MasterFields;
    inherited Edit; 
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
//     aaWriteToLog('changed: '+s);
    end;
//   else
//     aaWriteToLog('not changed'); 
  finally
    FTable.Free; 
//     aaWriteToLog('bugs');
  end;
end;
	
procedure TEasyTableFieldLinkProperty.GetFieldNamesForIndex(List: TStrings); 
var
  i: Integer; 
begin 
  for i := 0 to FTable.IndexFieldCount - 1 do
   if (FTable.IndexFields[i] <> nil) then 
    List.Add(FTable.IndexFields[i].FieldName); 
end;
	
function TEasyTableFieldLinkProperty.GetIndexBased: Boolean;
begin 
 Result := true;
//  Result := not IProviderSupport(FTable).PSIsSQLBased; 
end; 
	
function TEasyTableFieldLinkProperty.GetIndexDefs: TIndexDefs; 
begin
  Result := FTable.IndexDefs; 
end; 
 
function TEasyTableFieldLinkProperty.GetIndexFieldNames: AnsiString; 
begin
  Result := FTable.IndexFieldNames;
end; 
	
function TEasyTableFieldLinkProperty.GetIndexName: AnsiString; 
begin
  Result := FTable.IndexName; 
end; 
	
function TEasyTableFieldLinkProperty.GetMasterFields: AnsiString;
begin
  Result := FTable.MasterFields; 
end;
	
procedure TEasyTableFieldLinkProperty.SetIndexFieldNames(const Value: AnsiString); 
begin 
  FTable.IndexFieldNames := Value; 
	
end;
	
procedure TEasyTableFieldLinkProperty.SetIndexName(const Value: AnsiString);
begin 
//  if Value = SPrimary then
//    FTable.IndexName := '' else 
    FTable.IndexName := Value; 
end; 
	
procedure TEasyTableFieldLinkProperty.SetMasterFields(const Value: AnsiString); 
begin 
  FTable.MasterFields := Value;
end; 
	
	
{ TDBStringProperty }
	
function TDBStringProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList, paMultiSelect]; 
end; 
 
procedure TDBStringProperty.GetValueList(List: TStrings); 
begin
end;
	
procedure TDBStringProperty.GetValues(Proc: TGetStrProc); 
var 
  I: Integer; 
  Values: TStringList; 
begin
  Values := TStringList.Create; 
  try
    GetValueList(Values); 
    for I := 0 to Values.Count - 1 do Proc(Values[I]);
  finally
    Values.Free;
  end;
end;


function GetIndexDefs(Component: TPersistent): TIndexDefs;
var
  DataSet: TEasyTable;
  a : Boolean;
begin
  DataSet := Component as TEasyTable;
  a := DataSet.Active;
  if (not a) then
   DataSet.OpenTable;
  Result := GetPropertyValue(DataSet, 'IndexDefs') as TIndexDefs;
  if Assigned(Result) then
  begin
    Result.Updated := False;
    Result.Update;
  end;
  if (not a) then
   DataSet.CloseTable;
end;

{ TIndexNameProperty }

procedure TIndexNameProperty.GetValueList(List: TStrings);
begin
  GetIndexDefs(GetComponent(0)).GetItemNames(List);
end;

{ TIndexFieldNamesProperty }

procedure TIndexFieldNamesProperty.GetValueList(List: TStrings);
var
  I, J: Integer;
  IndexDefs: TIndexDefs;
  bAdd: boolean;
begin
  IndexDefs := GetIndexDefs(GetComponent(0));
//  IndexDefs.Updated := false;
//  IndexDefs.Update;
//aaWriteToLog('count = '+inttostr(IndexDefs.Count));
  for I := 0 to IndexDefs.Count - 1 do
    with IndexDefs[I] do
      if (Fields <> '') then
       begin
        bAdd := true;
        for J := 0 to List.Count-1 do
         if (AnsiLowerCase(List.Strings[J]) = AnsiLowerCase(Fields)) then
          begin
           bAdd := false;
           break;
          end;
        if (bAdd) then
         List.Add(Fields);
       end;
end;

{ TTableNameProperty }

procedure TTableNameProperty.GetValueList(List: TStrings);
var
  Table: TEasyTable;
begin
  Table := TEasyTable(GetComponent(0));
  Table.DBSession.GetTableNames(Table.DatabaseName,
                                Table.DatabaseFileName,
                                List);
end;


{ TDatabaseNameProperty }

procedure TDatabaseNameProperty.GetValueList(List: TStrings);
begin
 TEasyDataset(GetComponent(0)).GetDatabaseNameList(List);
end;


//------------------------------------------------------------------------------
// file name editor (extension is subtracted from name)
//------------------------------------------------------------------------------
procedure TDatabaseFileNameProperty.Edit;
var td : TOpenDialog;
begin
 td := TOpenDialog.Create(Application);
 td.Options := [ofFileMustExist];
 td.Filter := 'EasyTable database (*'+DatabaseFileExtension+')|*'+DatabaseFileExtension;
 if (td.Execute) then
   SetStrValue(td.FileName);
 td.Free;
end; // Edit


//------------------------------------------------------------------------------
// file name editor's attributes (paDialog - for ... button in design mode)
//------------------------------------------------------------------------------
function TDatabaseFileNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end; // GetAttributes


//------------------------------------------------------------------------------
//  TEasySession names
//------------------------------------------------------------------------------
procedure TEasySessionNameProperty.GetValueList(List: TStrings);
begin
   Sessions.GetSessionNames(List);
end;

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


end.
