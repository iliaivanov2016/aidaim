{$I ETblVer.inc}

unit ETblRelationalAlgebra;

interface

{DEFINE DEBUG_FLAG}

uses math,classes, windows, db, sysutils,
{$IFDEF DEBUG_FLAG}
 aaDebug,
{$ENDIF}
 ETblConst, ETblExcept, ETblCommon, ETblEngine;

type

 TETblFieldLink = record
  FieldName:  AnsiString; // table field name
  FieldType:  TFieldType;
  FieldSize:  Integer;
  DisplayName:  AnsiString; // result field name
  AO:       Pointer; // was TEasyAO type, CB4 bug fix
  Dataset:  TDataset;
  FieldNo:  Integer;
  IsHidden: Boolean;
  IsExpression: Boolean;  // Expression or field?
  IsAggregate:  Boolean;  // Expression is aggregate (contains agg. functions)?
  Expr:     TObject;      // TETblExpression
//  TableName:      AnsiString; // table1
//  TablePseudonym: AnsiString; // t1
 end;

 // fields (exprs) list in select
 TETblSelectListItem = record
  TableName: AnsiString;    // 'table1.' | 't1'
  AllFields: Boolean;   // 'table1.*' ?
  FieldName: AnsiString;    // field1
  IsExpression: Boolean; // field or expr?
  ValueExpr: TObject;   // TETblExpression
  Pseudonym: AnsiString;    // field1 as f1
 end;

 // array of fields
 TETblFields = class
 public
   Items:         array of TETblSelectListItem; // fields
   ItemCount:     integer;                      // length
   // creates
   constructor Create;
   // adds item to the end
   procedure Append(var Item: TETblSelectListItem);
 end;


 // base class for relational algebra operations
 TEasyAO = class (TObject)
 public
  FIsRootAO:    Boolean;
  FIsAOTable:   Boolean;
  FIsAOGroupBy: Boolean;
  FFilterExpr: TObject; // TETblExpression
  FTopRowCount: integer;
  FFirstRowNo:   integer;
 protected
  FResultInMemory:            Boolean; // for SELECT INTO optimization
  FResultTableName:           AnsiString; // for SELECT INTO optimization
  FResultDatabaseFileName:    AnsiString; // for SELECT INTO optimization
  FTableName:   AnsiString;
  FTableAlias:  AnsiString;
  FIsMaterialized:  Boolean;
  FResultDataset: TDataSet; // result dataset
  FResultFieldsOrder: TaaIntArray;
  FFieldCount:  Integer;
  FLeftAONull:  Boolean;
  FRightAONull: Boolean;
  FIndexFieldNames, FDescFields, FCaseInsensitiveFields: AnsiString;
  FDistinctFields:  AnsiString;
  FExpressionsExists: Boolean;
 protected
  FFieldLinks:  array of TETblFieldLink;
 procedure InternalCreate(
                      LeftAO: TEasyAO = nil;
                      RightAO: TEasyAO = nil;
                      TableName: AnsiString = '';
                      TableAlias: AnsiString = ''
                      );
  // navigating
  procedure InternalFirst; virtual;
  procedure InternalNext; virtual;
  function InternalGetEof: Boolean; virtual;
  function InternalGetRecordCount: Integer; virtual;
  procedure First; virtual;
  procedure Next; virtual;
  function GetEof: Boolean; virtual;
  function GetRecordCount: Integer; virtual;

  // sets names to FieldLinks list and renames duplicate names
  procedure SetFieldNames; virtual;
  // materializes AO
  procedure DoMaterialize; virtual;
 public
  FLeftAO,FRightAO: TEasyAO;
  destructor Destroy; override;
  // gets all result records
  procedure Execute(IsRootAO : Boolean = false); virtual;


  // filter record
  procedure FilterRecord(DataSet: TDataSet; var Accept: Boolean);
  // sets filter
  procedure SetFilter(FilterExpr: TObject); virtual;
  // for SELECT INTO optimization
  procedure SetResultTable(
                            InMemory:         Boolean;
                            TableName:        AnsiString;
                            DatabaseFileName: AnsiString
                           );
  // sets Top row count
  procedure SetTopRowCount(FirstRowNo, TopRowCount: integer); virtual;
  // sets projection for other TEasyAO
  procedure SetResultFields(var FieldRefs: array of TETblSelectListItem;
                            bDistinct: Boolean); virtual;
  // mapping function - returns number of found fields and found field No
  // also optionally unhides fields in AO
  function FieldExists(
                  FieldName, TableName: AnsiString;
                  Unhide: Boolean;
                  FieldNumbers: TaaIntArray = nil;
                  UnhideChildrenOnly: Boolean = false                  ): Integer; virtual;
  // returns FieldName from AOTable for specified internal field
  function GetFieldName(FieldNo: Integer; bOriginal: Boolean = true): AnsiString; virtual;
  // returns value (copy or direct pointer)
  procedure GetFieldValue(
                        var value: TETblDataValue;
                        FieldNo: Integer;
                        bCopy: Boolean = false;
                        AccessToHidden: boolean = false
                        ); virtual;
  // returns field size
  function GetFieldSize(FieldNo: integer): integer;
  // returns field type
  function GetFieldType(FieldNo: integer): TFieldType;

  // sets index
  procedure InternalSetIndex; virtual;
  procedure SetIndex(IndexFieldNames, DescFields, CaseInsensitiveFields: AnsiString);
    virtual;
  // return SessionName, DatabaseName
  procedure GetDbInfo(var SessionName: AnsiString; var DatabaseName: AnsiString);
  // check duplicated table pseudonyms
  procedure CheckDuplicatedTablePseudonyms(Pseudonyms: TStringList = nil);

  property IsMaterialized: Boolean read FIsMaterialized;
  property FieldCount: Integer read FFieldCount;
  property RecordCount: Integer read GetRecordCount;
  property ResultDataset: TDataSet read FResultDataset;
  property Eof: Boolean read GetEof;
 end;

 // table
 TEasyAOTable = class (TEasyAO)
 public
  constructor Create(
                      TableName:  AnsiString;
                      TableAlias: AnsiString;
                      DatabaseName: AnsiString = ''; // or
                      DatabaseFileName: AnsiString = '';
                      SessionName: AnsiString = ''; //
                      bInMemory: Boolean = false;
                      Password: AnsiString = ''
                      );
  // sets projection
  procedure SetResultFields(var FieldRefs: array of TETblSelectListItem;
                      bDistinct: Boolean); override;

  property IsMaterialized;
  property FieldCount;
  property RecordCount;
  property ResultDataset;
  property Eof;
 end;


 // joins and dekart
 TEasyAOJoin = class (TEasyAO)
 private
  FDekart:    Boolean;
  FUnionJoin: Boolean;
  FOuterJoin: Boolean;
  FInnerJoin: Boolean;
  FJoinType:  TETblJoinType;
  FFields1:   TaaIntArray;
  FFields2:   TaaIntArray;

  // inner / outer joins
  FCompareResult: TETblCompareResult;
  FRightRecNo: Integer;
  FEqualStarted:      Boolean; // true if equal values in both AO
  FFirstTimeCalled:   Boolean; // true if Next called First time
  FEof:               Boolean; // Eof is set

 protected
  // records are called Equal if all their join attributes are equal
  procedure CompareRecords;
  procedure InternalFirst; override;
  procedure InternalNext; override;
  function InternalGetEof: Boolean; override;
  function InternalGetRecordCount: Integer; override;
 public
  constructor Create(
                      LeftChild:  TEasyAO;
                      RightChild: TEasyAO;
                      JoinType:   TETblJoinType;
                      IsNatural:  Boolean = False;
                      FieldList1: TETblFields = nil; // join fields
                      FieldList2: TETblFields = nil // field1 = field2
                      );
  destructor Destroy; override;

  property IsMaterialized;
  property FieldCount;
  property RecordCount;
  property ResultDataset;
  property Eof;
  property OuterJoin: Boolean read FOuterJoin;
 end; // TEasyAOJoin

 TEasyAOUnion = class (TEasyAO)
 private
  FEof:        Boolean; // Eof is set
  FUnionType:  TETblUnionType;
  FFields1:    TaaIntArray;
  FFields2:    TaaIntArray;
  FCompareResult:     TETblCompareResult;
  FFirstTimeCalled:   Boolean; // true if Next called First time
  FShowLeft:          Boolean; // if then leftAO records will be added otherwise right
 protected
  // records are called Equal if all their join attributes are equal
  procedure CompareRecords;
  procedure ShowLeftAO;
  procedure ShowRightAO;
  procedure InternalFirst; override;
  procedure InternalNext; override;
  function InternalGetEof: Boolean; override;
  function InternalGetRecordCount: Integer; override;
 public
  constructor Create(
                      LeftChild:  TEasyAO;
                      RightChild: TEasyAO;
                      UnionType:   TETblUnionType;
                      IsCorresponding:  Boolean = False;
                      bDistinct: Boolean = True;
                      FieldList: TETblFields = nil // corresponding fields
                      );
  destructor Destroy; override;

  property IsMaterialized;
  property FieldCount;
  property RecordCount;
  property ResultDataset;
  property Eof;
 end; // TEasyAOUnion - union, intersect, except

 // table expression
 TEasyAOTableExpr = class (TEasyAO)
 protected
  procedure InternalFirst; override;
  procedure InternalNext; override;
  function InternalGetEof: Boolean; override;
  function InternalGetRecordCount: Integer; override;
 public
  constructor Create(
                     Child: TEasyAO
                    );

  property IsMaterialized;
  property FieldCount;
  property RecordCount;
  property ResultDataset;
  property Eof;
 end;

 // table expression
 TEasyAOGroupBy = class (TEasyAO)
 protected
  FTempDataset: TDataset;
  FFirstTimeCalled:   Boolean; // true if Next called First time
  FAllFields: Boolean;
  FFields:    TaaIntArray;
  FCompareResult: TETblCompareResult;
  FGroupFinished: Boolean;
  FEOF:           Boolean;
  // records are called Equal if all their join attributes are equal
  procedure CompareRecords;
  procedure InternalFirst; override;
  procedure InternalNext; override;
  function InternalGetEof: Boolean; override;
  function InternalGetRecordCount: Integer; override;
 public
  // sets projection
  procedure SetResultFields(var FieldRefs: array of TETblSelectListItem;
                      bDistinct: Boolean); override;
  constructor Create(
                     Child: TEasyAO;
                     FieldList: TETblFields = nil // corresponding fields
                    );
  destructor Destroy; override;

  property IsMaterialized;
  property FieldCount;
  property RecordCount;
  property ResultDataset;
  property Eof;
 end;

implementation

uses EasyTable,ETblExpr;

////////////////////////////////////////////////////////////////////////////////
//
// TETblFields
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// creates
//------------------------------------------------------------------------------
constructor TETblFields.Create;
begin
 ItemCount := 0;
end;// Create


//------------------------------------------------------------------------------
// add item to the end
//------------------------------------------------------------------------------
procedure TETblFields.Append(var Item: TETblSelectListItem);
begin
  Inc(ItemCount);
  SetLength(Items, ItemCount);
  Items[ItemCount-1] := Item;
end;// Append


////////////////////////////////////////////////////////////////////////////////
//
// TEasyAO
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
procedure TEasyAO.InternalCreate(
                      LeftAO: TEasyAO = nil;
                      RightAO: TEasyAO = nil;
                      TableName: AnsiString = '';
                      TableAlias: AnsiString = ''
                      );
begin
 FIsMaterialized := False;
 FIsRootAO := false;
 FIsAOTable := false;
 FIsAOGroupBy := false;
 FResultDataset := TEasyTable.Create(nil);
 FTableName := TableName;
 FTableAlias := TableAlias;
 FLeftAO := LeftAO;
 FRightAO := RightAO;
 FResultFieldsOrder := TaaIntArray.Create(0,1,100);
 FFieldCount := 0;
 FLeftAONull := false;
 FRightAONull := false;
 FIndexFieldNames := '';
 FDescFields := '';
 FCaseInsensitiveFields := '';
 FDistinctFields := '';
 FFilterExpr := nil;
 FTopRowCount := -1;
 FFirstRowNo := -1;
 FExpressionsExists := False;
 FResultTableName := '';
 FResultInMemory := False;
 FResultDatabaseFileName := '';
end; // Create


//------------------------------------------------------------------------------
// go to first record
//------------------------------------------------------------------------------
procedure TEasyAO.InternalFirst;
begin
;
end; // First


//------------------------------------------------------------------------------
// go to next record
//------------------------------------------------------------------------------
procedure TEasyAO.InternalNext;
begin
;
end; // Next


//------------------------------------------------------------------------------
// returns true if cursor points to the last record
//------------------------------------------------------------------------------
function TEasyAO.InternalGetEof: Boolean;
begin
 result := false;
end; //


//------------------------------------------------------------------------------
// returns number of records
//------------------------------------------------------------------------------
function TEasyAO.InternalGetRecordCount: Integer;
begin
 result := 0;
 if FIsMaterialized then
  result := FResultDataset.RecordCount;
end; //


//------------------------------------------------------------------------------
// go to first record
//------------------------------------------------------------------------------
procedure TEasyAO.First;
begin
 if FIsMaterialized then
  FResultDataset.First
 else
  InternalFirst;
end; // First


//------------------------------------------------------------------------------
// go to next record
//------------------------------------------------------------------------------
procedure TEasyAO.Next;
begin
 if FIsMaterialized then
  FResultDataset.Next
 else
  InternalNext;
end; // Next


//------------------------------------------------------------------------------
// returns true if cursor points to the last record
//------------------------------------------------------------------------------
function TEasyAO.GetEof: Boolean;
begin
 if FIsMaterialized then
  result := FResultDataset.Eof
 else
  result := InternalGetEof;
end; //


//------------------------------------------------------------------------------
// returns number of records
//------------------------------------------------------------------------------
function TEasyAO.GetRecordCount: Integer;
begin
 if FIsMaterialized then
  result := FResultDataset.RecordCount
 else
  result := InternalGetRecordCount;
end; //


//------------------------------------------------------------------------------
// sets names to FieldLinks list and renames duplicate names
//------------------------------------------------------------------------------
procedure TEasyAO.SetFieldNames;
var i,j,k: integer;
    name,s: AnsiString;
    bOk:  Boolean;
begin
 for i := 0 to FFieldCount-1 do
  FFieldLinks[i].FieldName := GetFieldName(i);
 for i := 0 to FFieldCount-1 do
  begin
   // renaming fields without name (calculated, expressions...)
   if (FFieldLinks[i].FieldName = '') then
    FFieldLinks[i].FieldName :=
     'EXPR'+IntToStr((Cardinal(Random(MAXINT)) + GetTickCount) mod 100000);
  end;
 // remove duplicates
 for i := 1 to FFieldCount-1 do
  begin
   k := 1;
   name := FFieldLinks[i].FieldName;
   repeat
    s := UpperCase(name);
    bOk := true;
    for j := 0 to i-1 do
     if (s = UpperCase(FFieldLinks[j].FieldName)) then
      begin
       bOk := false;
       break;
      end;
    if (bOk) then break;  
    if (k = 1) then
     name := name +'_' + IntToStr(k)
    else
     name := name + IntToStr(k);
    inc(k);
   until bOk;
   FFieldLinks[i].FieldName := name;
  end;
end;

//------------------------------------------------------------------------------
// materializes AO
//------------------------------------------------------------------------------
procedure TEasyAO.DoMaterialize;
var i,j,k:      Integer;
    FieldList:  TStringList;
    AliasList:  TStringList;
    value:      TETblDataValue;
begin
 if (FIsMaterialized) then Exit;
  // prepare field defs
 FieldList := TStringList.Create;
 AliasList := TStringList.Create;
 FResultDataset.FieldDefs.Clear;
 TEasyDataset(FResultDataset).IndexDefs.Clear;

 // result table is a table with applied projection (output fields list)
 if (FResultFieldsOrder.ItemCount <= 0) then
  begin
   // no projection

   // not result table
   for i := 0 to FFieldCount-1 do
    begin
     // field names will be 'Field'+n
// commented by Leo Martin (v.5.20) - expressions can acess hidden fields
     if (FFieldLinks[i].IsHidden) then continue;

     FieldList.Add(FFieldLinks[i].FieldName);
     AliasList.Add('');
     if (FFieldLinks[i].FieldType <> ftAutoInc) then
      FResultDataset.FieldDefs.Add(FFieldLinks[i].FieldName,
       FFieldLinks[i].FieldType,FFieldLinks[i].FieldSize, False)
     else
      FResultDataset.FieldDefs.Add(FFieldLinks[i].FieldName,
       ftInteger,0, False);
    end; // not result table
  end
 else
  begin
   // projection is set

   // prepare visible fields
   for i := 0 to FFieldCount-1 do
    begin
// commented by Leo Martin (v.5.20) - expressions can acess hidden fields
     if (FFieldLinks[i].IsHidden) then continue;
     if (FFieldLinks[i].FieldType <> ftAutoInc) then
      FResultDataset.FieldDefs.Add(FFieldLinks[i].FieldName,
       FFieldLinks[i].FieldType,FFieldLinks[i].FieldSize, False)
     else
      FResultDataset.FieldDefs.Add(FFieldLinks[i].FieldName,
       ftInteger,0, False);
    end;
    // perpare projection
   for i := 0 to FResultFieldsOrder.ItemCount-1 do
    begin
     j := FResultFieldsOrder.Items[i];
     if (FFieldLinks[j].IsHidden) then
      raise ETblException.Create(00024,[FFieldLinks[j].FieldName,FFieldLinks[j].DisplayName,j],nil);
     if (FFieldLinks[j].DisplayName <> '') then
      begin
       FieldList.Add(FFieldLinks[j].FieldName);
       AliasList.Add(FFieldLinks[j].DisplayName);
      end;
    end;
  end; // result table

 // create table
   if (FResultTableName <> '') then
    begin
     TEasyTable(FResultDataset).InMemory := FResultInMemory;
     TEasyTable(FResultDataset).Temporary := False;
     TEasyTable(FResultDataset).TableName := FResultTableName;
     TEasyTable(FResultDataset).DatabaseFileName := FResultDatabaseFileName;
     TEasyTable(FResultDataset).CreateTable;
    end // result table
   else
    begin
     TEasyDataset(FResultDataset).CreateTemporaryTable;
    end; // temporary table

 TEasyDataset(FResultDataset).Open;
 // filling table with data
 First;
 k := 0;
 while Not Eof do
  begin
   inc(k);
   // check TOP n? - apply only when there is no ORDER BY
   if (FIndexFieldNames = '') then
   begin
    // TOP n?
    if (FTopRowCount > -1) then
    begin
     if (TEasyDataset(FResultDataset).RecordCount >= FTopRowCount) then
      break;
    end;
    // TOP first_row
    if (FFirstRowNo > -1) then
    begin
     if (k < FFirstRowNo) then
      begin
       Next;
       continue;
      end;
    end;
   end;

   if (FFilterExpr <> nil) then
    begin
     value := TETblExpression(FFilterExpr).GetDataValue;
     if (value.DataType <> ftBoolean) then
      raise ETblException.Create(00047,[Integer(value.DataType)],nil);
     // check filter
     if (value.IsNull or not pBoolean(value.pData)^) then
      begin
       Next;
       continue;
      end;
    end;
   TEasyDataset(FResultDataset).DirectInsert;

     // not result table
     j := 0;

     for i := 0 to FFieldCount-1 do
      begin
// commented by Leo Martin (v.5.20) - expressions can acess hidden fields
       if (FFieldLinks[i].IsHidden) then continue;
       InitDataValue(value);
       // get field value
       GetFieldValue(value,i,false,true);
       // set value
       TEasyDataset(FResultDataset).SetFieldValue(value,j);
       FinalizeDataValue(value);
       inc(j);
      end; // not result table

   // insert record
//aaStartTime;
   TEasyDataset(FResultDataset).DirectPost;
//aaStopTime;
   // go to next record
//aaStartTime;
   Next;
//aaStopTime;
  end; // enf of inserting records loop
 TEasyDataset(FResultDataset).SetProjection(FieldList,AliasList);
 // move field links to the result dataset
 if (FResultFieldsOrder.ItemCount <= 0) then
  begin
   j := 0;
   // not result table
   for i := 0 to FFieldCount-1 do
    begin
     // field names will be 'Field'+n
// commented by Leo Martin (v.5.20) - expressions can acess hidden fields
     if (FFieldLinks[i].IsHidden) then continue;
     FFieldLinks[i].AO := nil;
     if (FFieldLinks[i].IsExpression) then
      if (FFieldLinks[i].Expr <> nil) then
        TETblExpression(FFieldLinks[i].Expr).Free;
     FFieldLinks[i].IsExpression := False;
     FFieldLinks[i].IsAggregate := False;
     FFieldLinks[i].Expr := nil;
     FFieldLinks[i].Dataset := FResultDataset;
     FFieldLinks[i].FieldNo := j;
     inc(j);
    end; // not result table
  end
 else
  begin
   // projection is set
   for i := 0 to FResultFieldsOrder.ItemCount-1 do
    begin
     j := FResultFieldsOrder.Items[i];
     if (FFieldLinks[j].IsHidden) then
      raise ETblException.Create(00031,[FFieldLinks[j].FieldName,FFieldLinks[j].DisplayName,j],nil);

     FFieldLinks[j].AO := nil;
     if (FFieldLinks[j].IsExpression) then
      if (FFieldLinks[j].Expr <> nil) then
       TETblExpression(FFieldLinks[j].Expr).Free;
     FFieldLinks[j].IsExpression := False;
     FFieldLinks[j].IsAggregate := False;
     FFieldLinks[j].Expr := nil;
     FFieldLinks[j].Dataset := FResultDataset;
     FFieldLinks[j].FieldNo := i;
    end;
  end; // result table

 FieldList.Free;
 AliasList.Free;
 FIsMaterialized := true;
 //---------------------- destroy child operations -----------------------------
 if (FLeftAO <> nil) then
  FLeftAO.Free;
 if (FRightAO <> nil) then
  FRightAO.Free;
 FRightAO := nil;
 FLeftAO := nil;
end; // DoMaterialize


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TEasyAO.Destroy;
{var
  i: integer;}
begin
{ for i := 0 to FFieldCount-1 do
    begin
     if (FFieldLinks[i].IsExpression) then
      if (FFieldLinks[i].Expr <> nil) then
        TETblExpression(FFieldLinks[i].Expr).Free;
     FFieldLinks[i].Expr := nil;
    end;}
 if (FResultDataset <> nil) then
  begin
//   if (not FIsAOTable) and (not FIsRootAO) then
//     TEasyDataset(FResultDataset).DeleteTemporaryTable;
   FResultDataset.Free;
  end;
 if (FResultFieldsOrder <> nil) then
  FResultFieldsOrder.Free;
 if (FLeftAO <> nil) then
  FLeftAO.Free;
 if (FRightAO <> nil) then
  FRightAO.Free;
 if (FFilterExpr <> nil) then
  TETblExpression(FFilterExpr).Free; 
 inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// getting all result records
//------------------------------------------------------------------------------
procedure TEasyAO.Execute(IsRootAO : Boolean = false);
//var i: integer;      
begin
 FIsRootAO := IsRootAO;

 // bug fix by Andrew: moved here in 5.41
 // filter
 if (FFilterExpr<> nil) then
  TETblExpression(FFilterExpr).AssignAO(self);

 if (FLeftAO <> nil) then
  FLeftAO.Execute;
 if (FRightAO <> nil) then
  FRightAO.Execute;

 TEasyDataset(FResultDataset).FreezeVisibleRecords;
 if (FIsAOTable) then
  begin
   if (not FIsRootAO) then
    begin
     TEasyDataset(FResultDataset).SetSQLFilter(FFilterExpr);
     TEasyDataset(FResultDataset).SetSQLTopRowCount(FFirstRowNo, FTopRowCount);
//     FResultDataset.Refresh;
    end;
  end;

 if (FIsAOGroupBy) then
  if (not TEasyAOGroupBy(Self).FAllFields) then
   if (TEasyAOGroupBy(Self).FTempDataset = nil) then
   begin
     TEasyAOGroupBy(Self).FTempDataset := TEasyTable.Create(nil);
     TEasyDataset(TEasyAOGroupBy(Self).FTempDataset).DatabaseFileName :=
      TEasyDataset(FLeftAO.FResultDataset).DatabaseFileName;
     TEasyDataset(TEasyAOGroupBy(Self).FTempDataset).DatabaseName :=
      TEasyDataset(FLeftAO.FResultDataset).DatabaseName;
     TEasyDataset(TEasyAOGroupBy(Self).FTempDataset).SessionName :=
      TEasyDataset(FLeftAO.FResultDataset).SessionName;
     TEasyDataset(TEasyAOGroupBy(Self).FTempDataset).TableName :=
      TEasyDataset(FLeftAO.FResultDataset).TableName;
     TEasyDataset(TEasyAOGroupBy(Self).FTempDataset).Password :=
      TEasyDataset(FLeftAO.FResultDataset).Password;
     TEasyDataset(TEasyAOGroupBy(Self).FTempDataset).InMemory :=
      TEasyDataset(FLeftAO.FResultDataset).InMemory;
     TEasyDataset(TEasyAOGroupBy(Self).FTempDataset).ReadOnly := True;
     try
      TEasyAOGroupBy(Self).FTempDataset.Open;
     except
      raise ETblException.Create(00050,
        [TEasyDataset(TEasyAOGroupBy(Self).FTempDataset).TableName,
         TEasyDataset(TEasyAOGroupBy(Self).FTempDataset).DatabaseName,
         TEasyDataset(TEasyAOGroupBy(Self).FTempDataset).DatabaseFileName,
         Word(TEasyDataset(TEasyAOGroupBy(Self).FTempDataset).InMemory)],nil);
     end;

    TEasyDataset(FLeftAO.FResultDataset).IndexName := '';
    FLeftAO.InternalSetIndex;
     TEasyDataset(TEasyAOGroupBy(Self).FTempDataset).IndexName :=
      TEasyDataset(FLeftAo.FResultDataset).IndexName;
   end; // FIsAOGroupBy

 if (FLeftAO <> nil) then
   TEasyDataset(FLeftAO.FResultDataset).UnfreezeVisibleRecords(True);

 if (FRightAO <> nil) then
   TEasyDataset(FRightAO.FResultDataset).UnfreezeVisibleRecords(True);

 if (not FIsMaterialized) then
  DoMaterialize;
 InternalSetIndex;
end;// Execute


//------------------------------------------------------------------------------
// filter record
//------------------------------------------------------------------------------
procedure TEasyAO.FilterRecord(DataSet: TDataSet; var Accept: Boolean);
var value:      TETblDataValue;
begin
 value := TETblExpression(FFilterExpr).GetDataValue(DataSet);
 if (value.DataType <> ftBoolean) then
  raise ETblException.Create(00048,[Integer(value.DataType)],nil);
 // check filter
 Accept := pBoolean(value.pData)^;
end; // FilterRecord


//------------------------------------------------------------------------------
// set filter
//------------------------------------------------------------------------------
procedure TEasyAO.SetFilter(FilterExpr: TObject);
begin
 FFilterExpr := FilterExpr;
end; // SetFilter


//------------------------------------------------------------------------------
// for SELECT INTO optimization
//------------------------------------------------------------------------------
procedure TEasyAO.SetResultTable(
                            InMemory:         Boolean;
                            TableName:        AnsiString;
                            DatabaseFileName: AnsiString
                               );

begin
  FResultInMemory := InMemory;
  FResultTableName := TableName;
  FResultDatabaseFileName := DatabaseFileName;
end; // SetResultTable


//------------------------------------------------------------------------------
// sets Top row count
//------------------------------------------------------------------------------
procedure TEasyAO.SetTopRowCount(FirstRowNo, TopRowCount: integer);
begin
  FTopRowCount := TopRowCount;
  FFirstRowNo := FirstRowNo;
end;// SetTopRowCount


//------------------------------------------------------------------------------
// sets projection for other TEasyAO
//------------------------------------------------------------------------------
procedure TEasyAO.SetResultFields(var FieldRefs: array of TETblSelectListItem;
                                  bDistinct: Boolean);
var i,j,k,x,res: integer;
    fname,tname: AnsiString;
begin
 j := Length(FieldRefs);
 if (j <= 0) then
  begin
   FieldExists('*','',true,FResultFieldsOrder);
  end
 else
  for i := 0 to j-1 do
   begin
    if (FieldRefs[i].AllFields) then
     fname := '*'
    else
     fname := FieldRefs[i].FieldName;
    tname := FieldRefs[i].TableName;
    if (FieldRefs[i].IsExpression) then
     begin
      inc(FFieldCount);
      SetLength(FFieldLinks,FFieldCount);
      FFieldLinks[FFieldCount-1].Expr := FieldRefs[i].ValueExpr;
      TETblExpression(FFieldLinks[FFieldCount-1].Expr).AssignAO(self);
      // create new field for this expression
      if (FieldRefs[i].Pseudonym <> '') then
       // pseudonim specified
       FFieldLinks[FFieldCount-1].FieldName := FieldRefs[i].Pseudonym
      else
       // random name
       FFieldLinks[FFieldCount-1].FieldName := GetTemporaryName('Expr');
      FFieldLinks[FFieldCount-1].DisplayName := FFieldLinks[FFieldCount-1].FieldName;
      // get field type
      FFieldLinks[FFieldCount-1].FieldType :=
        TETblExpression(FieldRefs[i].ValueExpr).getDataType(self);
      // get field size
      FFieldLinks[FFieldCount-1].FieldSize :=
        TETblExpression(FieldRefs[i].ValueExpr).getDataSize(self);
      // AO
      FFieldLinks[FFieldCount-1].AO := self;
      FFieldLinks[FFieldCount-1].Dataset := nil;
      FFieldLinks[FFieldCount-1].IsHidden := false;
      FFieldLinks[FFieldCount-1].IsExpression := true;
      FFieldLinks[FFieldCount-1].IsAggregate :=
        TEtblExpression(FieldRefs[i].ValueExpr).IsAggregated;
      FExpressionsExists := True;
//      if (FIsAOGroupBy) then
//       if (not FFieldLinks[FFieldCount-1].IsAggregate) then
//        raise ETblException.Create(00053,[FFieldLinks[FFieldCount-1].FieldName,FFieldCount],nil);
      FResultFieldsOrder.Append(FFieldCount-1);
      continue;
     end; // Expression

    res := FieldExists(fname,tname,true,FResultFieldsOrder);
    if (res = 1) then
     begin
      x := FResultFieldsOrder.Items[FResultFieldsOrder.ItemCount-1];
     if (FieldRefs[i].Pseudonym <> '') then
      // set pseudonym
       FFieldLinks[x].DisplayName := FieldRefs[i].Pseudonym
     else
      // use name like it was written in query
      if (fname <> '*') then
        FFieldLinks[x].DisplayName := fname;
     end // res = 0
    else
    if (res = 0) then
      raise ETblException.Create(00033, [fname], nil)
// by Leo Martin - its ok to have one of two fields with same names in
// result dataset
    else
     if (res > 1) then
      if (fname <> '*') then
       begin
        for x := 0 to res-2 do
         FResultFieldsOrder.Delete(FResultFieldsOrder.ItemCount-1);
        x := FResultFieldsOrder.Items[FResultFieldsOrder.ItemCount-1];
        if (FieldRefs[i].Pseudonym <> '') then
         // set pseudonym
         FFieldLinks[x].DisplayName := FieldRefs[i].Pseudonym
        else
         // use name like it was written in query
         if (fname <> '*') then
          FFieldLinks[x].DisplayName := fname;
       end; // DUPLICATE NAMES IN SELECT LIST REMOVED

//       raise ETblException.Create(00034, [fname], nil);
   end;
 for i := 0 to FResultFieldsOrder.ItemCount - 1 do
  begin
   k := FResultFieldsOrder.Items[i];
   if (bDistinct) then
    begin
     if (FDistinctFields = '') then
      FDistinctFields := FFieldLinks[k].FieldName
     else
      FDistinctFields := FDistinctFields + ';' + FFieldLinks[k].FieldName;
    end;

   if (FFieldLinks[k].DisplayName = '') then
    FFieldLinks[k].DisplayName :=
      FFieldLinks[k].FieldName;
  end;

 TEasyDataset(FResultDataset).FDistinctFields := self.FDistinctFields;
// TEasyDataset(FResultDataset).SetDistinct(FDistinctFields);
end;// SetResultFields


//------------------------------------------------------------------------------
// mapping function - returns number of found fields and found field No
// also optionally unhides fields in AO
//------------------------------------------------------------------------------
function TEasyAO.FieldExists(
                  FieldName, TableName: AnsiString;
                  Unhide: Boolean;
                  FieldNumbers: TaaIntArray = nil;
                  UnhideChildrenOnly: Boolean = false
                  ): Integer;
var i,j,k: integer;
    fname: AnsiString;
    tempArray: TaaIntArray;
begin
 result := 0;
 if (FIsAOTable) then
   if (TableName <> '') then
    if (UpperCase(TableName) <> UpperCase(FTableName)) and
      (UpperCase(TableName) <> UpperCase(FTableAlias)) then
     Exit; // another table

 // all fields
   if (FieldName = '*') then
    begin
   // unhide or field numbers
         tempArray := TaaIntArray.Create(0,1,100);
        if (FLeftAO <> nil) then
         FLeftAO.FieldExists(FieldName,TableName,Unhide, tempArray);

   for i := 0 to FFieldCount-1 do
    if (FIsAOTable) or
       ((TableName = FTableName) and (FFieldLinks[i].IsExpression)) or
       ((FLeftAO <> nil) and
          (FFieldLinks[i].AO = FLeftAO) and
          (tempArray.IsValueExists(FFieldLinks[i].FieldNo))) then
     begin
      inc(result);
      if (FieldNumbers <> nil) then
       FieldNumbers.Append(i);
      // group by does not needs in unhiding
      // it will cause hidden fields to be appeared in result dataset
      if (Unhide) and (not UnhideChildrenOnly) then
       if (not FIsAOGroupBy) then
        FFieldLinks[i].IsHidden := false;
     end;
         tempArray.SetSize(0);

        if (FRightAO <> nil) then
    begin
         FRightAO.FieldExists(FieldName,TableName,Unhide, tempArray);
      for i := 0 to FFieldCount-1 do
      if ((FRightAO <> nil) and
            (FFieldLinks[i].AO = FRightAO) and
            (tempArray.IsValueExists(FFieldLinks[i].FieldNo))) then
       begin
        inc(result);
        if (FieldNumbers <> nil) then
         FieldNumbers.Append(i);
        // group by does not needs in unhiding
        // it will cause hidden fields to be appeared in result dataset
        if (Unhide) and (not UnhideChildrenOnly) then
// commented by Leo Martin (5.30) - replaced by UnhideChildren
//         if (not FIsAOGroupBy) then
         FFieldLinks[i].IsHidden := false;
       end;
    end;
   tempArray.Free;
   Exit;
  end; // all fields

 fname := UpperCase(FieldName);
{
 if (FIsAOTable) then
        begin
   // TEasyAOTable
  end // TEasyAOTable
 else
  begin
}
   // not TEasyAOTable
   tempArray := nil;
   if (FieldNumbers <> nil) then
    tempArray := TaaIntArray.Create(0,1,100);
   if (FLeftAO <> nil) then
    begin
     result := result + FLeftAO.FieldExists(FieldName,TableName,Unhide,tempArray);
     if (FieldNumbers <> nil) then
      begin
       for i := 0 to tempArray.ItemCount-1 do
        begin
         k := tempArray.Items[i];
         for j := 0 to FFieldCount-1 do
          if (FFieldLinks[j].AO = FLeftAO) then
           if (FFieldLinks[j].FieldNo = k) then
            begin
             // return FieldNo in current FFieldLinks
             FieldNumbers.Append(j);
             // group by does not needs in unhiding
             // it will cause hidden fields to be appeared in result dataset
             if (Unhide) and (not UnhideChildrenOnly) then
// commented by Leo Martin (5.30) - replaced by UnhideChildren
//               if (not FIsAOGroupBy) then
              FFieldLinks[j].IsHidden := false;
//             break; // exit the loop searching for FieldLinks
            end;
        end;
       tempArray.SetSize(0); // empty temp array
      end; // fieldNumbers exists
    end; // LeftAO
   if (FRightAO <> nil) then
    begin
     result := result + FRightAO.FieldExists(FieldName,TableName,Unhide,tempArray);
     if (FieldNumbers <> nil) then
      begin
       for i := 0 to tempArray.ItemCount-1 do
        begin
         k := tempArray.Items[i];
         for j := 0 to FFieldCount-1 do
          if (FFieldLinks[j].AO = FRightAO) then
           if (FFieldLinks[j].FieldNo = k) then
            begin
             // return FieldNo in current FFieldLinks
             FieldNumbers.Append(j);
             // group by does not needs in unhiding
             // it will cause hidden fields to be appeared in result dataset
             if (Unhide) and (not UnhideChildrenOnly) then
// commented by Leo Martin (5.30) - replaced by UnhideChildren
//               if (not FIsAOGroupBy) then
              FFieldLinks[j].IsHidden := false;
//             break; // exit the loop searching for FieldLinks
            end;
        end;
        tempArray.SetSize(0);
      end; // fieldNumbers exists
    end; // RightAO
   if (tempArray <> nil) then
    tempArray.Free;

   // find field
   for i := 0 to FFieldCount-1 do
    if (UpperCase(FFieldLinks[i].FieldName) = fname) or
       (UpperCase(FFieldLinks[i].DisplayName) = fname) then
     if (TableName = '') or
        (UpperCase(TableName) = UpperCase(FTableName)) or
        (UpperCase(TableName) = UpperCase(FTableAlias)) then
        begin
         // modified by Leo Martin (5.30) - bug in Natural.sql
         if (FieldNumbers <> nil) then
          if (not FieldNumbers.IsValueExists(i)) then
           begin
            FieldNumbers.Append(i);
            inc(result);
           end;
         // group by does not needs in unhiding
         // it will cause hidden fields to be appeared in result dataset
         if (Unhide) and (not UnhideChildrenOnly) then
// commented by Leo Martin (5.30) - replaced by UnhideChildren
//          if (not FIsAOGroupBy) then
          FFieldLinks[i].IsHidden := false;
         break;
        end;

{
  end; // not TEasyAOTable
}
end;// FieldExists



//------------------------------------------------------------------------------
// returns FieldName from AOTable for specified internal field
//------------------------------------------------------------------------------
function TEasyAO.GetFieldName(FieldNo: Integer; bOriginal: Boolean = true): AnsiString;
begin
 if (FieldNo < 0) or (FieldNo >= FieldCount) then
  raise ETblException.Create(00011,[FTableName,FieldNo],nil);
 result := '';
 if (FFieldLinks[FieldNo].Dataset <> nil) then
  begin
   result := FFieldLinks[FieldNo].Dataset.Fields[FFieldLinks[FieldNo].FieldNo].FieldName;
  end
 else
  begin
   if (bOriginal) then
    result := TEasyAO(FFieldLinks[FieldNo].AO).GetFieldName(FFieldLinks[FieldNo].FieldNo)
   else
    result := FFieldLinks[FieldNo].FieldName;
  end;
end; // GetFieldName


//------------------------------------------------------------------------------
// sets index
//------------------------------------------------------------------------------
procedure TEasyAO.InternalSetIndex;
var s: AnsiString;
    i: integer;
begin
 if FIndexFieldNames = '' then
  Exit;

 if (FResultDataset = nil) then
  raise ETblException.Create(00017,[],nil);

 if (TEasyDataset(FResultDataset).IndexName <> '') then
  Exit;

 i := aaFindIndexByFields(TEasyDataset(FResultDataset),FIndexFieldNames,FDescFields,FCaseInsensitiveFields);
 if (i >= 0) then
  begin
   s := TEasyDataset(FResultDataset).IndexDefs.Items[i].Name;
   TEasyDataset(FResultDataset).IndexName := s;
  end
 else
  TEasyDataset(FResultDataset).IndexName :=
    TEasyDataset(FResultDataset).CreateTemporaryIndex(FIndexFieldNames,FDescFields,FCaseInsensitiveFields);
end;


//------------------------------------------------------------------------------
// sets index
//------------------------------------------------------------------------------
procedure TEasyAO.SetIndex(IndexFieldNames, DescFields, CaseInsensitiveFields: AnsiString);
begin
 FIndexFieldNames := IndexFieldNames;
 FDescFields := DescFields;
 FCaseInsensitiveFields := CaseInsensitiveFields;
end; // SetIndex


//------------------------------------------------------------------------------
// returns field value
//------------------------------------------------------------------------------
procedure TEasyAO.GetFieldValue(
                        var value: TETblDataValue;
                        FieldNo: Integer;
                        bCopy: Boolean = false;
                        AccessToHidden: boolean = false);
begin
 if (FieldNo < 0) or (FieldNo >= FieldCount) then
  raise ETblException.Create(00041,[FTableName,FieldNo],nil);
 value.IsNull := true;
 // AO = Dataset = nil
 if (FFieldLinks[FieldNo].Dataset = nil) and (FFieldLinks[FieldNo].AO = nil) then
  raise ETblException.Create(00015,[FTableName,FieldNo],nil);
 // hiden field
 if not AccessToHidden then
  if (FFieldLinks[FieldNo].IsHidden) then
   raise ETblException.Create(00016,[FTableName,FieldNo],nil);

 if (FFieldLinks[FieldNo].IsExpression) then
  begin
   value := TEtblExpression(FFieldLinks[FieldNo].Expr).getDataValue;
  end // Expression
 else
 if (FFieldLinks[FieldNo].Dataset <> nil) then
// try
  TEasyDataset(FFieldLinks[FieldNo].Dataset).GetFieldValue(value,FFieldLinks[FieldNo].FieldNo,bCopy)
// except
//  TEasyDataset(FFieldLinks[FieldNo].Dataset).GetFieldValue(value,FieldNo,bCopy);
//  raise;
// end
 else
  begin
   if (FLeftAONull and (FFieldLinks[FieldNo].AO = FLeftAO)) or
      (FRightAONull and (FFieldLinks[FieldNo].AO = FRightAO)) then
    begin
     // return null value
     Exit;
    end;
  TEasyAO(FFieldLinks[FieldNo].AO).GetFieldValue(value,FFieldLinks[FieldNo].FieldNo,bCopy,AccessToHidden);
  end;

end; // GetFieldValue


//------------------------------------------------------------------------------
// returns field size
//------------------------------------------------------------------------------
function TEasyAO.GetFieldSize(FieldNo: integer): integer;
begin
 if (FieldNo < 0) or (FieldNo >= FieldCount) then
  raise ETblException.Create(00042,[FTableName,FieldNo],nil);
 result := FFieldLinks[FieldNo].FieldSize;
end; // GetFieldSize


//------------------------------------------------------------------------------
// returns field type
//------------------------------------------------------------------------------
function TEasyAO.GetFieldType(FieldNo: integer): TFieldType;
begin
 if (FieldNo < 0) or (FieldNo >= FieldCount) then
  raise ETblException.Create(00045,[FTableName,FieldNo],nil);
 result := FFieldLinks[FieldNo].FieldType;
end; // GetFieldType


////////////////////////////////////////////////////////////////////////////////
//
// TEasyAOTable
//
////////////////////////////////////////////////////////////////////////////////


constructor TEasyAOTable.Create(
                      TableName:  AnsiString;
                      TableAlias: AnsiString;
                      DatabaseName: AnsiString = ''; // or
                      DatabaseFileName: AnsiString = '';
                      SessionName: AnsiString = ''; //
                      bInMemory: Boolean = false;
                      Password: AnsiString = ''
                      );
var i: integer;
begin
 InternalCreate(nil,nil,TableName,TableAlias);
 FIsMaterialized := True;
 FIsAOTable := true;
// TEasyDataset(FResultDataset).ReadOnly := true;
 TEasyDataset(FResultDataset).TableName := TableName;
 TEasyDataset(FResultDataset).InMemory := bInMemory;
 TEasyDataset(FResultDataset).Password := Password;
 TEasyDataset(FResultDataset).SessionName := SessionName;
 if (DatabaseName <> '') then
  TEasyDataset(FResultDataset).DatabaseName := DatabaseName
 else
  if (DatabaseFileName <> '') then
   TEasyDataset(FResultDataset).DatabaseFileName := DatabaseFileName;
 if (TEasyDataset(FResultDataset).InMemory) then
  begin
   // if there is no assigned in-memory database
   if (TEasyDataset(FResultDataset).DBSession.FindDatabase(DatabaseName, DatabaseFileName) = nil) or
    (not TEasyDataset(FResultDataset).DBSession.FindDatabase(DatabaseName, DatabaseFileName).InMemory) then
   TEasyDataset(FResultDataset).DatabaseName := 'MEMORY';
  end;
 try
  FResultDataset.Open;
 except
  raise ETblException.Create(00004,
    [TableName,DatabaseName,DatabaseFileName,Word(bInMemory)],nil);
 end;

 FFieldCount := FResultDataset.FieldCount;
 SetLength(FFieldLinks,FFieldCount);
 for i := 0 to FFieldCount-1 do
  begin
   FFieldLinks[i].AO := nil;
   FFieldLinks[i].Dataset := FResultDataset;
   FFieldLinks[i].FieldNo := i;
   FFieldLinks[i].IsHidden := True;
   FFieldLinks[i].IsExpression := False;
   FFieldLinks[i].IsAggregate  := False;
   FFieldLinks[i].FieldName := FResultDataset.FieldDefs.Items[i].Name;
   FFieldLinks[i].FieldType := FResultDataset.FieldDefs.Items[i].DataType;
   FFieldLinks[i].FieldSize := FResultDataset.FieldDefs.Items[i].Size;
  end;
end; // Create


//------------------------------------------------------------------------------
// sets projection for TEasyAOTable
//------------------------------------------------------------------------------
procedure TEasyAOTable.SetResultFields(var FieldRefs: array of TETblSelectListItem;
          bDistinct: Boolean);
var i,j: integer;
    FieldList: TStringList;
    AliasList: TStringList;
    tableName: AnsiString;
    tableAlias:AnsiString;
    tName:     AnsiString;
begin
 j := Length(FieldRefs);
 if (j <= 0) then
  begin
   inherited SetResultFields(FieldRefs,bDistinct);
   Exit;
  end;
 FieldList := TStringList.Create;
 AliasList := TStringList.Create;
 tableName := UpperCase(FTableName);
 tableAlias := UpperCase(FTableAlias);
 for i := 0 to j-1 do
  begin
   tName := UpperCase(FieldRefs[i].TableName);
   if (tName <> '') then
    if (tableName <> tName) and (tableAlias <> tName) then
     raise ETblException.Create(00014,[tableName,tableAlias,tName],FResultDataset);
   if (FieldRefs[i].AllFields) then
     begin
      // no projection
      FieldList.Free;
      AliasList.Free;
      Exit;
     end;
   FieldList.Add(FieldRefs[i].FieldName);
   AliasList.Add(FieldRefs[i].Pseudonym);
  end;
 inherited SetResultFields(FieldRefs,bDistinct);
 TEasyDataset(FResultDataset).SetProjection(FieldList,AliasList, True);
 FieldList.Free;
 AliasList.Free;
end; // SetResultsFields


////////////////////////////////////////////////////////////////////////////////
//
// TEasyAOJoin
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// records are called Equal if all their join attributes are equal
//------------------------------------------------------------------------------
procedure TEasyAOJoin.CompareRecords;
var i,j,k: integer;
    value1, value2: TETblDataValue;
begin
 FLeftAONull := false;
 FRightAONull := false;
 for i := 0 to FFields1.ItemCount - 1 do
  begin
   InitDataValue(value1);
   InitDataValue(value2);

   // get first value
   j := FFields1.Items[i];
   GetFieldValue(value1,j);

   // get second value
   k := FFields2.Items[i];
   GetFieldValue(value2,k);

   // compare values
   try
    FCompareResult := CompareDataValues(value1,value2,FJoinType);
   except
    on e: ETblException do
     begin
      if (e.NativeError = 00025) then
       raise ETblException.Create(00026, 
        [FFieldLinks[j].FieldName,FFieldLinks[k].FieldName],nil); 
      if (e.NativeError = 00028) then
       raise ETblException.Create(00029, 
        [FFieldLinks[j].FieldName,FFieldLinks[k].FieldName],nil);
     end;
    else 
     raise;
   end; 
	
   FinalizeDataValue(value1); 
   FinalizeDataValue(value2);
 
   if (FCompareResult <> ecrEqual) then 
    begin 
     break;
    end;
  end;
end; // CompareRecords 
 
 
//------------------------------------------------------------------------------
// go to first record 
//------------------------------------------------------------------------------
procedure TEasyAOJoin.InternalFirst;
begin 
 FEof := False;
 if (FDekart) then 
  begin
   FLeftAO.First; 
   FRightAO.First; 
   if (FLeftAO.Eof or FRightAO.Eof) then
    FEof := true; 
  end
 else 
 if (FJoinType = ejtUnion) then
  begin
   // union join 
   ;
  end // union join
 else
  begin
   // inner ot outer join
   FEqualStarted := false; 
   FLeftAO.First;
   FRightAO.First;
   if (FOuterJoin) then
    begin
     if (FLeftAO.Eof and FRightAO.Eof) then 
      FEof := true
     else 
     if ((FJoinType = ejtLeftOuter) and (FLeftAO.Eof)) then
      FEof := true
     else
     if ((FJoinType = ejtRightOuter) and (FRightAO.Eof)) then
      FEof := true; 
    end
   else 
    begin 
     if (FLeftAO.Eof or FRightAO.Eof) then
      FEof := true; 
    end; 
   if (not FEof) then
    begin
     FEqualStarted := false;
     FFirstTimeCalled := true; 
     InternalNext;
    end; 
  end; // inner ot outer join 
end; // First
 
	
//------------------------------------------------------------------------------ 
// go to next record 
//------------------------------------------------------------------------------ 
procedure TEasyAOJoin.InternalNext; 
label m1;
var OldRecNo: Integer;
    bStopAtFirstMoving: Boolean; 
begin
 if (Eof) then Exit; 
 bStopAtFirstMoving := false;
 if (FDekart) then 
  begin 
   FRightAO.Next;
   if (FRightAO.Eof) then
    begin
     FLeftAO.Next; 
     if (not FLeftAO.Eof) then
      FRightAO.First;
    end // Eof 
  end // Dekart 
 else 
 if (FUnionJoin) then
  begin
    // union join
    ;
  end // union join 
 else
  begin 
   // inner or outer 
   // called by first 
   if (FFirstTimeCalled) then
    begin 
     FFirstTimeCalled := false; 
     if (FRightAO.Eof) then
      begin 
       FRightAONull := True;
       FLeftAONull := False;
       Exit;
      end;
     if (FLeftAO.Eof) then
      begin
       FRightAONull := False; 
       FLeftAONull := True; 
       Exit; 
      end; 
     CompareRecords;
     if (FCompareResult = ecrEqual) then
      begin
       FEqualStarted := true; 
       FRightRecNo := FRightAO.ResultDataset.RecNo; 
       Exit; // record is valid - all ok 
      end; 
     if (FOuterJoin) then
      begin 
       if ((FJoinType = ejtFullOuter) or (FJoinType = ejtLeftOuter))
          and 
          ((FCompareResult = ecrLower) or
          (FCompareResult = ecrLeftNull)) then
        begin
         FLeftAONull := false;
         FRightAONull := true;
         Exit; // record is valid - all ok
        end;
       if ((FJoinType = ejtFullOuter) or (FJoinType = ejtRightOuter))
          and
          ((FCompareResult = ecrGreater) or
          (FCompareResult = ecrBothNull) or
          (FCompareResult = ecrRightNull)) then
        begin
         FLeftAONull := true;
         FRightAONull := false;
         Exit; // record is valid - all ok
        end;
       bStopAtFirstMoving := true;
      end; // outer join
    end; // called by first or after materializing current record

   if ((FLeftAO.Eof or FRightAO.Eof) and (not EOF)) then
    begin
     if ((FRightAO.Eof) and (FOuterJoin)) then
      begin
       FLeftAO.Next;
       FRightAONull := True;
       FLeftAONull := False;
       Exit;
      end;
     if ((FLeftAO.Eof) and (FOuterJoin)) then
      begin
       FRightAO.Next;
       FRightAONull := False;
       FLeftAONull := True;
       Exit;
      end;
    end; // left or right AO is at eof

   // if equal records were found at previous call
   if (FEqualStarted) then
    begin
     FRightAO.Next; // FRightAO.Eof will be true only if we were on last record
     if (FRightAO.Eof) then
      begin
        if (FLeftAO.Eof) then
          Exit // Eof reached
        else
         begin
          FLeftAO.Next;
          if (FLeftAO.Eof) then
           Exit; // Eof reached
          CompareRecords;
          if (FCompareResult = ecrEqual) then
           begin
            if (FRightAO.Eof) then
             FRightAO.First;
            FRightAO.ResultDataset.RecNo := FRightRecNo;
            Exit; // record is valid - all ok
           end;
          // we are at the last RightAO record
          // and have some records at LeftAO that
          // were not processed
          if ((FJoinType = ejtLeftOuter) or (FJoinType = ejtFullOuter)) then
           begin
            FEqualStarted := false;
            FLeftAONull := false;
            FRightAONull := true;
            Exit; // record is valid - all ok
           end;
          // there is no records left
          FEof := true;
          Exit;
         end; // left AO moved to next record successfully
      end; // right AO at the last record
     // check new record
     CompareRecords;
     if (FCompareResult = ecrEqual) then
      Exit; // record is valid - all ok
     // rightAO record is greater than leftAO
     FLeftAO.Next;
     if (FLeftAO.Eof) then
      begin
        if ((FJoinType = ejtRightOuter) or (FJoinType = ejtFullOuter)) then
         begin
          FEqualStarted := false;
          FLeftAONull := true;
          FRightAONull := false;
          Exit; // record is valid - all ok
         end;
        // there is no records left
        FEof := true;
        Exit;
      end;
     // save RecNo
     OldRecNo := FRightAO.FResultDataset.RecNo;
     // move right AO to the first equal record
     // check if left AO has records some equal records that were not joined
     // with right AO records
     if (FRightAO.Eof) then
      FRightAO.First;
     FRightAO.FResultDataset.RecNo := FRightRecNo;
     CompareRecords;
     if (FCompareResult = ecrEqual) then
      Exit; // record is valid - all ok
     // we have successfully joined equal records - now let's go forward
     // return to previous position (both ao after last previously "equal" records)
     FRightAO.FResultDataset.RecNo := OldRecNo;
     CompareRecords;
     if (FCompareResult = ecrEqual) then
      begin
       // new found records
       FRightRecNo := FRightAO.FResultDataset.RecNo;
       Exit; // record is valid - all ok
      end;
     // now we have not equal records
     FEqualStarted := false;
     if (FOuterJoin) then
      begin
       if ((FJoinType = ejtFullOuter) or (FJoinType = ejtLeftOuter))
          and
          ((FCompareResult = ecrLower) or
//          (FCompareResult = ecrBothNull) or
          (FCompareResult = ecrLeftNull)) then
        begin
{
         if (FCompareResult = ecrBothNull) then
          begin
           FLeftAONull := true;
           FRightAONull := false;
          end
         else
}
          begin
           FLeftAONull := false;
           FRightAONull := true;
          end;
         Exit; // record is valid - all ok
        end;
       if ((FJoinType = ejtFullOuter) or (FJoinType = ejtRightOuter))
          and
          ((FCompareResult = ecrGreater) or
          (FCompareResult = ecrBothNull) or
          (FCompareResult = ecrRightNull)) then
        begin
         FLeftAONull := true;
         FRightAONull := false;
         Exit; // record is valid - all ok
        end;
       bStopAtFirstMoving := true;
      end; // outer join
    end; // equal records were found at previous call
   // searching for next valid record
   while not Eof do
    begin
     if (FCompareResult = ecrEqual)  then
      raise ETblException.Create(00030);
     if (FLeftAO.Eof) and
        ((FCompareResult = ecrLower) or
         (FCompareResult = ecrLeftNull)) then
      begin
       // there is no right records
       if (FInnerJoin or (FJoinType = ejtLeftOuter)) then
        begin
         FEof := true;
         Exit; // there is no more joined records
        end;
       if (not bStopAtFirstMoving) then
        begin
          FRightAO.Next;
         // if Eof - exiting
         if (FRightAO.Eof) then
           Exit;
        end;
       FLeftAONull := true;
       FRightAONull := false;
       // only not equal records left
       Exit; // record is valid - all ok
      end // LeftAO.Eof
     else
     if (FRightAO.Eof) and
        ((FCompareResult = ecrGreater) or
         (FCompareResult = ecrBothNull) or
         (FCompareResult = ecrRightNull)) then
      begin
       // there is no right records
       if (FInnerJoin or (FJoinType = ejtRightOuter)) then
        begin
         FEof := true;
         Exit; // there is no more records
        end;
       if (not bStopAtFirstMoving) then
        begin
          FLeftAO.Next;
         // if Eof - exiting
         if (FLeftAO.Eof) then
           Exit;
        end;
       FLeftAONull := false;
       FRightAONull := true;
       // only not equal records left
       Exit; // record is valid - all ok
      end // RightAO.Eof
     else
     if ((FCompareResult = ecrLower) or
         (FCompareResult = ecrLeftNull)) then
      begin
       if (bStopAtFirstMoving) then
        if ((FJoinType = ejtLeftOuter) or (FJoinType = ejtFullOuter)) then
         begin
          FLeftAONull := false;
          FRightAONull := true;
          Exit; // record is valid - all ok
         end; // Lower or LeftNull again

       FLeftAO.Next;
       // we are at last record
       if (FLeftAO.Eof) then
        begin
         // next found record will be at result dataset with left part = null
         if ((FJoinType = ejtLeftOuter) or (FJoinType = ejtFullOuter)) then
          bStopAtFirstMoving := true;
         continue;
        end;

       CompareRecords;
       if (FCompareResult = ecrEqual) then
        begin
         FEqualStarted := true;
         FRightRecNo := FRightAO.ResultDataset.RecNo;
         Exit; // record is valid - all ok
        end;
       if (FCompareResult = ecrLower) or
          (FCompareResult = ecrLeftNull) then
        if ((FJoinType = ejtLeftOuter) or (FJoinType = ejtFullOuter)) then
         begin
          FLeftAONull := false;
          FRightAONull := true;
          Exit; // record is valid - all ok
         end; // Lower or LeftNull again
      if (FCompareResult = ecrGreater) then
       bStopAtFirstMoving := true;
//       continue; // check Eof and search again
      end // Lower or LeftNull
     else
      if ((FCompareResult = ecrGreater) or
         (FCompareResult = ecrBothNull) or
         (FCompareResult = ecrRightNull)) then
      begin
       if (bStopAtFirstMoving) then
        if ((FJoinType = ejtRightOuter) or (FJoinType = ejtFullOuter)) then
         begin
          FLeftAONull := true;
          FRightAONull := false;
          Exit; // record is valid - all ok
         end; // Greater, BothNull or RightNull again

       FRightAO.Next;
       // we are at last record
       if (FRightAO.Eof) then
        begin
         // next found record will be at result dataset with right part = null
         if ((FJoinType = ejtRightOuter) or (FJoinType = ejtFullOuter)) then
           bStopAtFirstMoving := true;
         continue;
        end;


       CompareRecords;
       if (FCompareResult = ecrEqual) then
        begin
         FEqualStarted := true;
         FRightRecNo := FRightAO.ResultDataset.RecNo;
         Exit; // record is valid - all ok
        end;
      if ((FCompareResult = ecrGreater) or
         (FCompareResult = ecrBothNull) or
         (FCompareResult = ecrRightNull)) then
        if ((FJoinType = ejtRightOuter) or (FJoinType = ejtFullOuter)) then
         begin
          FLeftAONull := true;
          FRightAONull := false;
          Exit; // record is valid - all ok
         end; // Greater, BothNull or RightNull again
      if ((FCompareResult = ecrLower) or
          (FCompareResult = ecrLeftNull)) then
       bStopAtFirstMoving := true;
//       continue; // check Eof and search again
      end // Greater, BothNull or RightNull
    end; // while not Eof - searching for valid records
  end; // inner or outer
end; // InternalNext


//------------------------------------------------------------------------------
// returns true if cursor points to the last record
//------------------------------------------------------------------------------
function TEasyAOJoin.InternalGetEof: Boolean;
begin
 if (FEof) then
  begin
   result := true;
  end
 else
   result := FLeftAO.Eof and FRightAO.Eof;
end; //


//------------------------------------------------------------------------------
// returns number of records
//------------------------------------------------------------------------------
function TEasyAOJoin.InternalGetRecordCount: Integer;
begin
 result := 0;
 if (FIsMaterialized) then
  result := FResultDataset.RecordCount
 else
 begin
   if (FDekart) then
    begin
     result := FLeftAO.RecordCount * FRightAO.RecordCount;
    end;
 end;
end; // GetRecordCount


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TEasyAOJoin.Create(
                      LeftChild:  TEasyAO;
                      RightChild: TEasyAO;
                      JoinType:   TETblJoinType;
                      IsNatural:  Boolean = False;
                      FieldList1: TETblFields = nil; // join fields
                      FieldList2: TETblFields = nil // field1 = field2
                      );
var i,j,k,l1,l2: integer;
    LeftFields,RightFields: AnsiString;

 procedure FillIndexNames;
 begin
   if (FFieldLinks[j].AO = FLeftAO) then
    begin
      if (LeftFields = '') then
       LeftFields := FLeftAO.FFieldLinks[FFieldLinks[j].FieldNo].FieldName
      else
       LeftFields := LeftFields + ',' + FLeftAO.FFieldLinks[FFieldLinks[j].FieldNo].FieldName;
    end // LeftAO
   else
    begin
      if (RightFields = '') then
       RightFields := FRightAO.FFieldLinks[FFieldLinks[j].FieldNo].FieldName
      else
       RightFields := RightFields + ',' + FRightAO.FFieldLinks[FFieldLinks[j].FieldNo].FieldName;
    end; // RightAO
 end;


begin
 InternalCreate(LeftChild,RightChild);
 FJoinType := JoinType;
 FInnerJoin := (FJoinType = ejtInner);
 FDekart := (FJoinType = ejtCross);
 FOuterJoin := (FJoinType = ejtLeftOuter) or
               (FJoinType = ejtRightOuter) or
               (FJoinType = ejtFullOuter);
 FUnionJoin := (FJoinType = ejtUnion);
 l1 := 0;
 l2 := 0;
 if (not FDekart) and (not IsNatural) then
  begin
   l1 := FieldList1.ItemCount;
   l2 := FieldList2.ItemCount;
   if (l1 <> l2) then
     raise ETblException.Create(00006,[l1,l2],nil);
  end;
 FEof := false;
 FEqualStarted := false;
 FFirstTimeCalled := true;
 FFields1 :=  TaaIntArray.Create(0,1,FLeftAO.FieldCount);
 FFields2 := TaaIntArray.Create(0,1,FRightAO.FieldCount);
 // creating field links for none-union joins
 if (FJoinType <> ejtUnion) then
  begin
   FFieldCount := FLeftAO.FieldCount + FRightAO.FieldCount;
   SetLength(FFieldLinks,FFieldCount);
   // linking left child
   j := FLeftAO.FieldCount-1;
   for i := 0 to j do
    begin
     FFieldLinks[i].FieldNo := i;
     FFieldLinks[i].Dataset := nil;
     FFieldLinks[i].AO := FLeftAO;
     FFieldLinks[i].FieldName := FLeftAO.FFieldLinks[i].FieldName;
     FFieldLinks[i].DisplayName := '';
     FFieldLinks[i].FieldType := FLeftAO.FFieldLinks[i].FieldType;
     FFieldLinks[i].FieldSize := FLeftAO.FFieldLinks[i].FieldSize;
     FFieldLinks[i].IsHidden := FLeftAO.FFieldLinks[i].IsHidden;
     FFieldLinks[i].IsExpression := FLeftAO.FFieldLinks[i].IsExpression;
     FFieldLinks[i].IsAggregate := FLeftAO.FFieldLinks[i].IsAggregate;
    end;
   inc(j);
   // linking right child
   for i := 0 to FRightAO.FieldCount-1 do
    begin
     FFieldLinks[j+i].FieldNo := i;
     FFieldLinks[j+i].Dataset := nil;
     FFieldLinks[j+i].AO := FRightAO;
     FFieldLinks[j+i].FieldName := FRightAO.FFieldLinks[i].FieldName;
     FFieldLinks[j+i].DisplayName := '';
     FFieldLinks[j+i].FieldType := FRightAO.FFieldLinks[i].FieldType;
     FFieldLinks[j+i].FieldSize := FRightAO.FFieldLinks[i].FieldSize;
     FFieldLinks[j+i].IsHidden := FRightAO.FFieldLinks[i].IsHidden;
     FFieldLinks[j+i].IsExpression := FRightAO.FFieldLinks[i].IsExpression;
     FFieldLinks[j+i].IsAggregate := FRightAO.FFieldLinks[i].IsAggregate;
     if (IsNatural) then
      for k := 0 to j-1 do
       if (UpperCase(FFieldLinks[j+i].FieldName) =
            UpperCase(FFieldLinks[k].FieldName)) then
        begin
         FFields1.Append(k);
         FFields2.Append(j+i);
         FFieldLinks[k].IsHidden := false;
         FFieldLinks[j+i].IsHidden := false;
         FLeftAO.FieldExists(FFieldLinks[k].FieldName,'',True,nil);
         FRightAO.FieldExists(FFieldLinks[j+i].FieldName,'',True,nil);
        end; // natural join
    end;
   if (FInnerJoin or FOuterJoin)  then
    begin
     if (not IsNatural) then
      begin
       // creating join fields lists
       for i := 0 to l1-1 do
        begin
         // join fields should not be hidden
         j := FieldExists(
          FieldList1.Items[i].FieldName,
          FieldList1.Items[i].TableName,True,FFields1);
         if (j <> 1) then
           raise ETblException.Create(00020,
            [FieldList1.Items[i].TableName,FieldList1.Items[i].FieldName,i,j],nil);
        end;
       for i := 0 to l2-1 do
        begin
         j := FieldExists(
          FieldList2.Items[i].FieldName,
          FieldList2.Items[i].TableName,True,FFields2);
         if (j <> 1) then
           raise ETblException.Create(00021,
            [FieldList2.Items[i].TableName,FieldList2.Items[i].FieldName,i,j],nil);
        end;
      end; // not natural

     if (FFields1.ItemCount <> FFields2.ItemCount) then
      raise ETblException.Create(00023,[FFields1.ItemCount,FFields2.ItemCount],nil);
     if FFields1.ItemCount <= 0 then
      raise ETblException.Create(00022,[FFields1.ItemCount],nil);
     LeftFields := '';
     RightFields := '';
     // filling Left and Right fields
     for i := 0 to FFields1.ItemCount-1 do
      begin
       j := FFields1.Items[i];
       k := FFields2.Items[i];
       if (FFieldLinks[j].AO = FFieldLinks[k].AO) then
        raise ETblException.Create(00027,[FFieldLinks[j].FieldName,
          FFieldLinks[k].FieldName,j,k],nil)
       else
        if (FFieldLinks[j].AO = FRightAO) then
         begin
          // swap left / right join fields
          FFields1.Items[i] := k;
          FFields2.Items[i] := j;
          j := FFields1.Items[i];
          k := FFields2.Items[i];
         end;
       FillIndexNames;
       j := k;
       FillIndexNames;
      end;
     FLeftAO.SetIndex(LeftFields,'','');
     FRightAO.SetIndex(RightFields,'','');
    end; // inner or outer joins
  end // creating field links for none-union joins
 else
  begin
   // union joins
   ;
  end; // union joins
 SetFieldNames;
 FIsMaterialized := false;
end; // create;


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TEasyAOJoin.Destroy;
begin
 FFields1.Free;
 FFields2.Free;
 inherited Destroy;
end; // destroy


////////////////////////////////////////////////////////////////////////////////
//
// TEasyAOUnion
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// records are called Equal if all their join attributes are equal
//------------------------------------------------------------------------------
procedure TEasyAOUnion.CompareRecords;
var i,j,k: integer;
    value1, value2: TETblDataValue;
begin

 for i := 0 to FFields1.ItemCount - 1 do
  begin
   InitDataValue(value1);
   InitDataValue(value2);

   // get first value
   j := FFields1.Items[i];
   TEasyDataset(FLeftAO.FResultDataset).GetFieldValue(value1,j);

   // get second value
   k := FFields2.Items[i];
   TEasyDataset(FRightAO.FResultDataset).GetFieldValue(value2,k);

   // compare values
   try
    FCompareResult := CompareDataValues(value1,value2);
   except
    on e: ETblException do
     begin
      if (e.NativeError = 00025) then
       raise ETblException.Create(00038,
        [FFieldLinks[j].FieldName,FFieldLinks[k].FieldName],nil);
      if (e.NativeError = 00028) then
       raise ETblException.Create(00039,
        [FFieldLinks[j].FieldName,FFieldLinks[k].FieldName],nil);
     end;
    else
     raise;
   end;

   FinalizeDataValue(value1);
   FinalizeDataValue(value2);
{
   if (FCompareResult <> ecrEqual) then
    begin
     break;
    end;
}
   if (FCompareResult <> ecrEqual) and (FCompareResult <> ecrBothNull) then
    begin
     break;
    end;
  end;
 // NULL values are equal
 if (FCompareResult = ecrBothNull) then
  FCompareResult := ecrEqual
 else
 if (FCompareResult = ecrLeftNull) then
  FCompareResult := ecrLower
 else
 if (FCompareResult = ecrRightNull) then
  FCompareResult := ecrGreater;
end; // CompareRecords


procedure TEasyAOUnion.ShowLeftAO;
var i,k: Integer;
begin
 k := 0;
 for i := 0 to FFieldCount-1 do
  begin
   FFieldLinks[i].Dataset := FLeftAO.FResultDataset;
   FFieldLinks[i].FieldNo := FFields1.Items[k];
   inc(k);
  end;
end; // ShowLeftAO


procedure TEasyAOUnion.ShowRightAO;
var i,k: Integer;
begin
 k := 0;
 for i := 0 to FFieldCount-1 do
  begin
   FFieldLinks[i].Dataset := FRightAO.FResultDataset;
   FFieldLinks[i].FieldNo := FFields2.Items[k];
   inc(k);
  end;
end; // ShowRightAO


//------------------------------------------------------------------------------
// first
//------------------------------------------------------------------------------
procedure TEasyAOUnion.InternalFirst;
begin
 FLeftAO.First;
 FRightAO.First;
 if (FUnionType <> eutUnion) then
  begin
   FFirstTimeCalled := true;
   InternalNext;
  end
 else
  begin
   if (FLeftAO.Eof) and (not FRightAO.Eof) then
    begin
     ShowRightAO;
     FShowLeft := false;
    end;
  end;
end; // InternalFirst


//------------------------------------------------------------------------------
// next
//------------------------------------------------------------------------------
procedure TEasyAOUnion.InternalNext;
begin
 if (Eof) then Exit;
 if (FUnionType = eutUnion) then
  begin
   if (not FShowLeft) then
    FRightAO.Next
   else
    FLeftAO.Next;
   if FShowLeft and (FLeftAO.Eof) and (not FRightAO.Eof) then
    begin
     ShowRightAO;
     FShowLeft := false;
     // switch to the right AO
    end;
  end
 else
 if (FUnionType = eutIntersect) then
  begin
   if (FFirstTimeCalled) then
    begin
     repeat
      CompareRecords;
      if (FCompareResult = ecrLower) then
       FLeftAO.Next;
      if (FCompareResult = ecrGreater) then
        begin
         if (FRightAO.Eof) then
          begin
           FEof := true;
           break;
          end;
         FRightAO.Next;
        end;
     until (FCompareResult = ecrEqual) or Eof; // find equal records
     FFirstTimeCalled := false;
    end // first time called
   else
    begin
     FLeftAO.Next;
     while (not Eof) do
      begin
       CompareRecords;
       if (FCompareResult = ecrEqual) then
        break; // new record found
       if (FCompareResult = ecrLower) then
        FLeftAO.Next;
       if (FCompareResult = ecrGreater) then
        begin
         if (FRightAO.Eof) then
          begin
           FEof := true;
           break;
          end;
         FRightAO.Next;
        end;
      end; // find equal records
    end; // not first time called
  end // intersect
 else
 if (FUnionType = eutExcept) then
  begin
   if (FFirstTimeCalled) then
    begin
     repeat
      CompareRecords;
      if (FCompareResult = ecrEqual) then
       begin
        FLeftAO.Next;
       end;
      if (FCompareResult = ecrLower) then
       begin
        break;
       end; // lower
      if (FCompareResult = ecrGreater) then
       begin
        if (FRightAO.Eof) then
         break;
        FRightAO.Next;
       end; // Greater
     until Eof; // find equal records
     FFirstTimeCalled := false;
    end // first time called
   else
    begin
     // not first time called
     FLeftAO.Next;
     while (not Eof) do
      begin
       CompareRecords;
       if (FCompareResult = ecrEqual) then
        begin
         FLeftAO.Next;
        end; // Equal
      if (FCompareResult = ecrLower) then
       begin
        break;
       end; // Lower
      if (FCompareResult = ecrGreater) then
       begin
        if (FRightAO.Eof) then
         break;
        FRightAO.Next;
       end; // Greater
      end; // find equal records
    end; // not first time called
  end // except
 else
  raise ETblException.Create(00040,[Integer(FUnionType)],nil);
end; // InternalNext



//------------------------------------------------------------------------------
// Eof
//------------------------------------------------------------------------------
function TEasyAOUnion.InternalGetEof: Boolean;
begin
 if (FEof) then
  begin
   result := true;
   Exit;
  end;

 if (FUnionType = eutExcept) or (FUnionType = eutIntersect) then
  result := FLeftAO.Eof
 else
  result := FEof or (FLeftAO.Eof and FRightAO.Eof);
end; // InternalGetEof


//------------------------------------------------------------------------------
// returns recordcount
//------------------------------------------------------------------------------
function TEasyAOUnion.InternalGetRecordCount: Integer;
begin
 result := 0;
 if (FIsMaterialized) then
  result := FResultDataset.RecordCount;
end; // InternalGetRecordCount


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TEasyAOUnion.Create(
                      LeftChild:  TEasyAO;
                      RightChild: TEasyAO;
                      UnionType:   TETblUnionType;
                      IsCorresponding:  Boolean = False;
                      bDistinct: Boolean = True;
                      FieldList: TETblFields = nil // corresponding fields
                      );
var LeftIndexFieldNames,RightIndexFieldNames: AnsiString;

procedure AddFieldToFieldLists(LeftIndex: integer; RightIndex: integer);
var name: AnsiString;
begin
{
      if ((FLeftAO.FResultDataset.Fields[LeftIndex].DataType =
           FRightAO.FResultDataset.Fields[RightIndex].DataType) or
          (
            (FLeftAO.FResultDataset.Fields[LeftIndex].DataType in [ftInteger,ftAutoInc]) and
            (FRightAO.FResultDataset.Fields[RightIndex].DataType in [ftInteger,ftAutoInc])
          )) then
}
      if (getCommonDataType(FLeftAO.FResultDataset.Fields[LeftIndex].DataType,
                            FRightAO.FResultDataset.Fields[RightIndex].DataType) <> ftUnknown) then
       if (((UnionType = eutUnion) and (bDistinct)) or
           IsFieldTypeCanCompriseIndex(
            FLeftAO.FResultDataset.Fields[LeftIndex].DataType)) then
        begin
         inc(FFieldCount);
         SetLength(FFieldLinks,FFieldCount);
         name := FLeftAO.FResultDataset.Fields[LeftIndex].FieldName;
         FFieldLinks[FFieldCount-1].FieldName := name;
         FFieldLinks[FFieldCount-1].DisplayName := name;
         FFieldLinks[FFieldCount-1].FieldType := FLeftAO.FResultDataset.Fields[LeftIndex].DataType;
         FFieldLinks[FFieldCount-1].FieldSize := Max(
                                                  FLeftAO.FResultDataset.Fields[LeftIndex].Size,
                                                  FRightAO.FResultDataset.Fields[RightIndex].Size);
         FFieldLinks[FFieldCount-1].IsHidden := false;
         FFieldLinks[FFieldCount-1].AO := nil;
         FFieldLinks[FFieldCount-1].Dataset := FLeftAO.FResultDataset;
         FFieldLinks[FFieldCount-1].FieldNo := LeftIndex;
         FFieldLinks[FFieldCount-1].IsExpression := False;
         FFieldLinks[FFieldCount-1].IsAggregate := False;

         FFields1.Append(LeftIndex);
         FFields2.Append(RightIndex);
         if (LeftIndexFieldNames = '') then
          LeftIndexFieldNames := name
         else
          LeftIndexFieldNames := LeftIndexFieldNames + ';' +  name;
         if (RightIndexFieldNames = '') then
          RightIndexFieldNames := FRightAO.FResultDataset.Fields[RightIndex].FieldName
         else
          RightIndexFieldNames := RightIndexFieldNames + ';' +
            FRightAO.FResultDataset.Fields[RightIndex].FieldName;
        end;
end; // AddFieldToFieldLists


var i,j,k,n,f1,f2: integer;
    name: AnsiString;
    bNoFields: Boolean;
begin
 InternalCreate(LeftChild,RightChild);
 FIsMaterialized := False;
 FEof := false;
 FFirstTimeCalled := false;
 FLeftAONull := false;
 FRightAONull := false;
 FShowLeft := true;
 FUnionType := UnionType;
 bNoFields := false;
 if (FieldList = nil) then
  bNoFields := true;

 // unfreeze visible records?
 if (TEasyDataset(FLeftAO.FResultDataset).VisibleRecordsFreezed) then
  TEasyDataset(FLeftAO.FResultDataset).UnfreezeVisibleRecords;
 FLeftAO.Execute;
 // unfreeze visible records?
 if (TEasyDataset(FRightAO.FResultDataset).VisibleRecordsFreezed) then
  TEasyDataset(FRightAO.FResultDataset).UnfreezeVisibleRecords;
 FRightAO.Execute;

// added by Leo Martin, 5.40
TEasyDataset(FLeftAO.FResultDataset).SetProjection;
TEasyDataset(FRightAO.FResultDataset).SetProjection;

 LeftIndexFieldNames := '';
 RightIndexFieldNames := '';
 FFields1 :=  TaaIntArray.Create(0,1,FLeftAO.FieldCount);
 FFields2 := TaaIntArray.Create(0,1,FRightAO.FieldCount);
 if bNoFields then
  begin
   // scanning all fields in FLeftAO
   for i := 0 to FLeftAO.FResultDataset.FieldCount-1 do
    begin
     k := -1;
     if (IsCorresponding) then
      begin
       name := UpperCase(FLeftAO.FResultDataset.Fields[i].FieldName);
       for j := 0 to FRightAO.FResultDataset.FieldCount-1 do
        begin
         if (name = UpperCase(FRightAO.FResultDataset.Fields[j].FieldName)) then
          begin
           k := j;
           break;
          end;
        end;
      end // searching for corresponding field
     else
      begin
       if (i < FRightAO.FResultDataset.FieldCount) then
        k := i;
      end; // corresponding fields by number
     if (k >= 0) then
      AddFieldToFieldLists(i,k);
    end; // scanning all fields in FLeftAO
  end // no corresponding fields were specified
 else
  begin
   // scanning FieldList
   n := FieldList.ItemCount;
   if (n <= 0) then
    raise ETblException.Create(00037,[n],nil);
   for i := 0 to n-1 do
    begin
     // store field name
     name := UpperCase(FieldList.Items[i].FieldName);
     // scanning LeftAO
     f1 := -1;
     for j := 0 to FLeftAO.FResultDataset.FieldCount-1 do
      begin
       if (name = UpperCase(FLeftAO.FResultDataset.Fields[j].FieldName)) then
        begin
         f1 := j;
         break;
        end;
      end; // scanning LeftAO
     // scanning RightAO
     f2 := -1;
     for j := 0 to FRightAO.FResultDataset.FieldCount-1 do
      begin
       if (name = UpperCase(FRightAO.FResultDataset.Fields[j].FieldName)) then
        begin
         f2 := j;
         break;
        end;
      end; // scanning RightAO
     if (f1 >= 0) and (f2 >= 0) then
      begin
        AddFieldToFieldLists(f1,f2);
      end; // adding field to the union field list
    end; // scanning FieldList
  end; // corresponding fields were specified
 if (FFields1.ItemCount <> FFields2.ItemCount) then
  raise ETblException.Create(00035,[FFields1.ItemCount,FFields2.ItemCount],nil);
 if (FFields1.ItemCount <= 0) then
  raise ETblException.Create(00036,[FFields1.ItemCount],nil);
 if (UnionType <> eutUnion) then
  begin
   FLeftAO.SetIndex(LeftIndexFieldNames,'','');
   TEasyDataset(FLeftAo.FResultDataset).IndexName := '';
   FLeftAO.InternalSetIndex;
   FRightAO.SetIndex(RightIndexFieldNames,'','');
   TEasyDataset(FRightAo.FResultDataset).IndexName := '';
   FRightAO.InternalSetIndex;
  end;
 if (bDistinct) then
  begin
   TEasyDataset(FResultDataset).SetDistinct(LeftIndexFieldNames);
  end;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TEasyAOUnion.Destroy;
begin
 FFields1.Free;
 FFields2.Free;
 inherited Destroy;
end; // destroy


////////////////////////////////////////////////////////////////////////////////
//
// TEasyAOTableExpr
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// first
//------------------------------------------------------------------------------
procedure TEasyAOTableExpr.InternalFirst;
begin
 FLeftAO.First;
end; // InternalFirst


//------------------------------------------------------------------------------
// next
//------------------------------------------------------------------------------
procedure TEasyAOTableExpr.InternalNext;
begin
 FLeftAO.Next;
end; // InternalNext


//------------------------------------------------------------------------------
// EOF
//------------------------------------------------------------------------------
function TEasyAOTableExpr.InternalGetEof: Boolean;
begin
 result := FLeftAO.EOF;
end; // InternalGetEof


//------------------------------------------------------------------------------
// Record count
//------------------------------------------------------------------------------
function TEasyAOTableExpr.InternalGetRecordCount: Integer;
begin
 result := FLeftAO.RecordCount;
end; // InternalGetRecordCount


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TEasyAOTableExpr.Create(
                     Child: TEasyAO
                    );
var i: integer;
begin
 InternalCreate(Child,nil);
 FIsMaterialized := false;
 FFieldCount := FLeftAO.FieldCount;
 SetLength(FFieldLinks,FFieldCount);
 for i := 0 to FFieldCount-1 do
  begin
   FFieldLinks[i].AO := FLeftAO;
   FFieldLinks[i].Dataset := nil;
   FFieldLinks[i].FieldNo := i;
   FFieldLinks[i].IsHidden := True;
   FFieldLinks[i].FieldName := FLeftAO.FFieldLinks[i].FieldName;
   FFieldLinks[i].FieldType := FLeftAO.FFieldLinks[i].FieldType;
   FFieldLinks[i].FieldSize := FLeftAO.FFieldLinks[i].FieldSize;
   FFieldLinks[i].IsExpression := FLeftAO.FFieldLinks[i].IsExpression;
   FFieldLinks[i].IsAggregate := FLeftAO.FFieldLinks[i].IsAggregate;
  end;
end; // Create


////////////////////////////////////////////////////////////////////////////////
//
// TEasyAOGroupBy
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// records are called Equal if all their join attributes are equal
//------------------------------------------------------------------------------
procedure TEasyAOGroupBy.CompareRecords;
var i,j,k: integer;
    value1, value2: TETblDataValue;
begin

 for i := 0 to FFields.ItemCount - 1 do
  begin
   InitDataValue(value1);
   InitDataValue(value2);

   // get first value
   // changed by Leo Martin & Andrew Harrison in v.5.30
   j := FFields.Items[i];

   FLeftAO.GetFieldValue(value1,j);

   // get second value
   // changed by Leo Martin & Andrew Harrison in v.5.30
   // for getting dataset field number from materialized AO
   k := FLeftAo.FFieldLinks[j].FieldNo;
   TEasyDataset(FTempDataset).GetFieldValue(value2,k);

   // compare values
   try
    FCompareResult := CompareDataValues(value1,value2);
   except
    on e: ETblException do
     begin
      if (e.NativeError = 00025) then
       raise ETblException.Create(00051,
        [FFieldLinks[j].FieldName,FFieldLinks[k].FieldName],nil);
      if (e.NativeError = 00028) then
       raise ETblException.Create(00052,
        [FFieldLinks[j].FieldName,FFieldLinks[k].FieldName],nil);
     end;
    else
     raise;
   end;

   FinalizeDataValue(value1);
   FinalizeDataValue(value2);
   if (FCompareResult <> ecrEqual) and (FCompareResult <> ecrBothNull) then
    begin
     break;
    end;
  end;
 // NULL values are equal
 if (FCompareResult = ecrBothNull) then
  FCompareResult := ecrEqual
 else
 if (FCompareResult = ecrLeftNull) then
  FCompareResult := ecrLower
 else
 if (FCompareResult = ecrRightNull) then
  FCompareResult := ecrGreater;
end; // CompareRecords


//------------------------------------------------------------------------------
// first
//------------------------------------------------------------------------------
procedure TEasyAOGroupBy.InternalFirst;
begin
 FEOF := false;
 FLeftAO.First;

 if (not FAllFields) then
  begin
   // copy filter to temp dataset
   if (FLeftAO.FFilterExpr <> nil) then
    begin
     TEasyDataset(FTempDataset).SetSQLFilter(FLeftAO.FFilterExpr);
     TEasyDataset(FTempDataset).AssignVisibleRecordsList(TEasyDataset(FLeftAO.FResultDataset).visibleRecords);
    end;
  FTempDataset.First;

   // group by with sum bug fix
//   TEasyDataset(FTempDataset).FDirectAccessForGetFieldValue := true;
//   TEasyDataset(FLeftAO.FResultDataset).FDirectAccessForGetFieldValue := true;
  end;

 FFirstTimeCalled := true;
 InternalNext;
end; // InternalFirst


//------------------------------------------------------------------------------
// next
//------------------------------------------------------------------------------
procedure TEasyAOGroupBy.InternalNext;

 procedure Init;
 var i: integer;
 begin
  if (not FExpressionsExists) then Exit;
  for i := 0 to FFieldCount-1 do
   if (FFieldLinks[i].IsAggregate) then
    begin
     TETblExpression(FFieldLinks[i].Expr).Init;
    end;
 end; // initialize expressions

 procedure Accumulate;
 var i: integer;
 begin
  if (not FExpressionsExists) then Exit;
  for i := 0 to FFieldCount-1 do
   if (FFieldLinks[i].IsAggregate) then
    begin
     //TETblExpression(FFieldLinks[i].Expr).Accumulate(self);
     TETblExpression(FFieldLinks[i].Expr).Accumulate;
    end;
 end; // accumulate aggregate expressions

// InternalNext
begin
 if (FAllFields) then
  begin
   if (not FFirstTimeCalled) then
    begin
     FEOF := true;
     Exit;
    end;
   FFirstTimeCalled := false;
   // initialize expression
   Init;
   while not (FLeftAO.FResultDataset.EOF) do
    begin
     Accumulate;
     FLeftAO.Next;
    end;
   FLeftAO.First;
   Exit;
  end;

 // not AllFields
 if (FFirstTimeCalled) then
  begin
   FFirstTimeCalled := false;
   Init;
   if (FLeftAO.EOF) then
    begin
//     if (not FExpressionsExists) then
      FEOF := true;
     Exit;
    end;
   // go to next record
   FTempDataset.Next;
   if (FTempDataset.Eof) then
    begin
     // calculate expressions
     Accumulate;
     // group finished - there is only 1 record in source dataset
     Exit;
    end;
   repeat
    CompareRecords;
    Accumulate;
    if (FCompareResult = ecrEqual) then
     begin
      FLeftAO.Next;
      FTempDataset.Next;
     end;
   until (FLeftAO.EOF) or (FCompareResult <> ecrEqual);
  end // First time called
 else
  begin
   // not first time called
   // move to next group
   FLeftAO.Next;
   FTempDataset.Next;
   Init;
   if (FLeftAO.EOF) then
    begin
     FEOF := true;
     Exit;
    end;
   repeat
    CompareRecords;
    Accumulate;
    if (FCompareResult = ecrEqual) then
     begin
      FLeftAO.Next;
      FTempDataset.Next;
     end;
   until (FLeftAO.EOF) or (FCompareResult <> ecrEqual);
  end; // not first time called
end; // InternalNext


//------------------------------------------------------------------------------
// EOF
//------------------------------------------------------------------------------
function TEasyAOGroupBy.InternalGetEof: Boolean;
begin
 result := FEOF;
end; // InternalGetEof


//------------------------------------------------------------------------------
// Record count
//------------------------------------------------------------------------------
function TEasyAOGroupBy.InternalGetRecordCount: Integer;
begin
 result := FLeftAO.RecordCount;
end; // InternalGetRecordCount


//------------------------------------------------------------------------------
// sets projection for TEasyAOTable
//------------------------------------------------------------------------------
procedure TEasyAOGroupBy.SetResultFields(var FieldRefs: array of TETblSelectListItem;
          bDistinct: Boolean);
var i,j,k,x:      integer;
    fname,tname:  AnsiString;
    fno:          TaaIntArray;
begin
 j := Length(FieldRefs);
 if (j <= 0) then
  begin
   inherited SetResultFields(FieldRefs,False);
   Exit;
  end;
 inherited SetResultFields(FieldRefs,False);
 // check for invalid fields in select list
 fno := TaaIntArray.Create(0,1,1);
 for i := 0 to j-1 do
  begin
   if (FieldRefs[i].IsExpression) then continue;
   fname := FieldRefs[i].FieldName;
   tname := FieldRefs[i].TableName;
   fno.SetSize(0);
   if (FieldExists(fname,tname,False,fno) <= 0) then
    begin
     fno.Free;
     raise ETblException.Create(00048,[tname,fname],nil);
    end;
   for k := 0 to fno.ItemCount-1 do
    begin
     x := fno.Items[k];
     if (not FFields.IsValueExists(x)) then
      begin
       fno.Free;
       raise ETblException.Create(00049,[tname,fname,x,FFieldLinks[x].FieldName],nil);
      end;
    end;
  end;
 fno.Free;
end; // SetResultFields


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TEasyAOGroupBy.Create(
                     Child: TEasyAO;
                     FieldList: TETblFields = nil // corresponding fields
                    );
var i,j,k: integer;
    GroupByFields: AnsiString;
begin
 InternalCreate(Child,nil);
 FIsMaterialized := False;
 try
   FAllFields := FieldList = nil;
   FTempDataset := nil;
   if (not FAllFields) then
    if (FieldList.ItemCount = 0) then
     FAllFields := true;
  // FLeftAO.Execute;
   FEOF := false;
   FIsAOGroupBy := true;

   FGroupFinished := False;
   FFirstTimeCalled := false;
   FFields := TaaIntArray.Create(0,1,FLeftAO.FieldCount);
   try
     FFieldCount := FLeftAO.FieldCount;
     SetLength(FFieldLinks,FFieldCount);
     for i := 0 to FFieldCount-1 do
      begin
       FFieldLinks[i].AO := FLeftAO;
       FFieldLinks[i].Dataset := nil;
       FFieldLinks[i].FieldNo := i;
       FFieldLinks[i].IsHidden := True;
       FFieldLinks[i].FieldName := FLeftAO.FFieldLinks[i].FieldName;
       FFieldLinks[i].FieldType := FLeftAO.FFieldLinks[i].FieldType;
       FFieldLinks[i].FieldSize := FLeftAO.FFieldLinks[i].FieldSize;
       FFieldLinks[i].IsExpression := FLeftAO.FFieldLinks[i].IsExpression;
       FFieldLinks[i].IsAggregate := FLeftAO.FFieldLinks[i].IsAggregate;
      end;
     if (not FAllFields) then
      begin
       for i := 0 to FieldList.ItemCount-1 do
        begin
         // unhide Group BY field in children and move it to FFields array
         j := FieldExists(
               FieldList.Items[i].FieldName,
               FieldList.Items[i].TableName,True,FFields);
          if (j <> 1) then
               raise ETblException.Create(00046,
                [FieldList.Items[i].TableName,FieldList.Items[i].FieldName,i,j],nil);
         k := FFields.Items[FFields.ItemCount-1];
         if (GroupByFields = '') then
          GroupByFields := FFieldLinks[k].FieldName
         else
          GroupByFields := GroupByFields + ';' + FFieldLinks[k].FieldName;
        end;
       FLeftAO.SetIndex(GroupByFields,'','');
      end; // not all fields
   except
    FFields.Free;
    FFields := nil;
    raise;
   end;
  except
   FResultDataset.Free;
   FResultDataset := nil;
   FResultFieldsOrder.Free;
   FResultFieldsOrder := nil;
   raise;
  end;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TEasyAOGroupBy.Destroy;
begin
 if (FFields <> nil) then
  FFields.Free;
 if (not FAllFields) then
  if (FTempDataset <> nil) then
   FTempDataset.Free;
 inherited Destroy;
end; // destroy


procedure TEasyAO.GetDbInfo(var SessionName, DatabaseName: AnsiString);
var
  TempAO: TEasyAO;
begin
  TempAO := self;
  while not (TempAO is TEasyAOTable) do
   begin
    if TempAO.FLeftAO <> nil then TempAO := TempAO.FLeftAO
    else if TempAO.FRightAO <> nil then TempAO := TempAO.FRightAO
    else break;
   end;

  if not (TempAO is TEasyAOTable) then
   raise Exception.Create('Internal Error: GetDbInfo: can''t find TEasyTable in AOTree');

  SessionName := TEasyDataset(TEasyAOTable(TempAO).ResultDataset).SessionName;
  DatabaseName := TEasyDataset(TEasyAOTable(TempAO).ResultDataset).DatabaseName;
end;//GetDbInfo


//------------------------------------------------------------------------------
// check duplicated table pseudonyms
//------------------------------------------------------------------------------
procedure TEasyAO.CheckDuplicatedTablePseudonyms(Pseudonyms: TStringList = nil);
var
  bRoot: Boolean;
  i,j:   Integer;
begin
  if (Pseudonyms = nil) then
   begin
    Pseudonyms := TStringList.Create;
    bRoot := True;
   end
  else
   bRoot := False;
  try
    if (FTableAlias <> '') then
      Pseudonyms.Add(FTableAlias);
    if (FLeftAO <> nil) then
      FLeftAO.CheckDuplicatedTablePseudonyms(Pseudonyms);
    if (FRightAO <> nil) then
      FRightAO.CheckDuplicatedTablePseudonyms(Pseudonyms);
    if (bRoot) then
      for i := 0 to Pseudonyms.Count-2 do
       for j := i+1 to Pseudonyms.Count-1 do
         if (AnsiUpperCase(Pseudonyms.Strings[i]) = AnsiUpperCase(Pseudonyms.Strings[j])) then
           raise ETblException.Create(01093, [Pseudonyms.Strings[i]], nil);
  finally
    if (bRoot) then
      Pseudonyms.Free;
  end;
end;


end.
