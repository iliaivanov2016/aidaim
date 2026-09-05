{*******************************************************}
{                                                       }
{       Borland Delphi Visual Component Library         }
{       Master/Detail Field Links Editor                }
{                                                       }
{       Copyright (c) 1997,99 Inprise Corporation       }
{                                                       }
{*******************************************************}

//-----------------------------------------------------//
//                                                     //
//  Modified by AidAim Software, 2001-2004             //
//                                                     //
//-----------------------------------------------------//


unit ACRFldLinks;

interface

{$I ACRVer.inc}

uses SysUtils, Classes,
{$IFDEF MSWINDOWS}
     Windows, Messages, Graphics, Controls, Forms, StdCtrls, ExtCtrls, Buttons,
{$ENDIF}
{$IFDEF LINUX}
//     Libc,
     QGraphics, QControls, QForms, QStdCtrls, QExtCtrls, QButtons,
//     Messages,
{$ENDIF}
     DB,

  // Accuracer Unit

  ACRExcept,
  ACRConst,
  {$IFDEF DEBUG_LOG}
  ACRDebug,
  {$ENDIF}

 {$IFDEF D6H}
  DesignIntf, DesignEditors;
 {$ELSE}
  DSGNINTF;
 {$ENDIF}

type


////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseFieldLinkProperty
//
////////////////////////////////////////////////////////////////////////////////

  TACRBaseFieldLinkProperty = class(TStringProperty)
  private
    FChanged: Boolean;
    FDataSet: TDataSet;
  protected
    function GetDataSet: TDataSet;
    procedure GetFieldNamesForIndex(List: TStrings); virtual;
    function GetIndexBased: Boolean; virtual;
    function GetIndexDefs: TIndexDefs; virtual;
    function GetIndexFieldNames: AnsiString; virtual;
    function GetIndexName: AnsiString; virtual;
    function GetMasterFields: AnsiString; virtual; abstract;
    procedure SetIndexFieldNames(const Value: AnsiString); virtual;
    procedure SetIndexName(const Value: AnsiString); virtual;
    procedure SetMasterFields(const Value: AnsiString); virtual; abstract;
  public
    constructor CreateWith(ADataSet: TDataSet); virtual;
    procedure GetIndexNames(List: TStrings);
    property IndexBased: Boolean read GetIndexBased;
    property IndexDefs: TIndexDefs read GetIndexDefs;
    property IndexFieldNames: AnsiString read GetIndexFieldNames write SetIndexFieldNames;
    property IndexName: AnsiString read GetIndexName write SetIndexName;
    property MasterFields: AnsiString read GetMasterFields write SetMasterFields;
    property Changed: Boolean read FChanged;
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    property DataSet: TDataSet read GetDataSet;
  end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRLinkFields
//
////////////////////////////////////////////////////////////////////////////////


  TACRLinkFields = class(TForm)
    DetailList: TListBox;
    MasterList: TListBox;
    BindList: TListBox;
    Label30: TLabel;
    Label31: TLabel;
    IndexList: TComboBox;
    IndexLabel: TLabel;
    Label2: TLabel;
    Bevel1: TBevel;
    Bevel2: TBevel;
    AddButton: TButton;
    DeleteButton: TButton;
    ClearButton: TButton;
    Button1: TButton;
    Button2: TButton;
    Help: TButton;
    procedure FormCreate(Sender: TObject);
    procedure BindingListClick(Sender: TObject);
    procedure AddButtonClick(Sender: TObject);
    procedure DeleteButtonClick(Sender: TObject);
    procedure BindListClick(Sender: TObject);
    procedure ClearButtonClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure HelpClick(Sender: TObject);
    procedure IndexListChange(Sender: TObject);
  private
    FDataSet: TDataSet;
    FMasterDataSet: TDataSet;
    FDataSetProxy: TACRBaseFieldLinkProperty;
    FFullIndexName: AnsiString;
    MasterFieldList: AnsiString;
    IndexFieldList: AnsiString;
    OrderedDetailList: TStringList;
    OrderedMasterList: TStringList;
    procedure OrderFieldList(OrderedList, List: TStrings);
    procedure AddToBindList(const Str1, Str2: AnsiString);
    procedure Initialize;
    property FullIndexName: AnsiString read FFullIndexName;
    procedure SetDataSet(Value: TDataSet);
  public
    property DataSet: TDataSet read FDataSet write SetDataSet;
    property DataSetProxy: TACRBaseFieldLinkProperty read FDataSetProxy write FDataSetProxy;
    function Edit: Boolean;
  end;

function EditMasterFields(ADataSet: TDataSet; ADataSetProxy: TACRBaseFieldLinkProperty): Boolean;

{$IFDEF LINUX}
// Windows.pas
const LB_ERR = - 1;
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}
  {$R *.dfm}
{$ENDIF}
{$IFDEF LINUX}
  {$R *.xfm}
{$ENDIF}

uses Dialogs, DBConsts, LibHelp, TypInfo;

{ Utility Functions }

function StripFieldName(const Fields: AnsiString; var Pos: Integer): AnsiString;
var
  i: Integer;
begin
  i := Pos;
  while ((i <= Length(Fields)) and (Fields[I] <> ';')) do
    Inc(i);
  Result := Copy(Fields, Pos, i - Pos);
  if (i <= Length(Fields)) and (Fields[i] = ';') then
    Inc(i);
  Pos := i;
end;

function StripDetail(const Value: AnsiString): AnsiString;
var
  S: AnsiString;
  i: Integer;
begin
  S := Value;
  i := 0;
  while Pos('->', S) > 0 do
   begin
    i := Pos('->', S);
    S[i] := ' ';
   end;
  Result := Copy(Value, 0, i - 2);
end;

function StripMaster(const Value: AnsiString): AnsiString;
var
  S: AnsiString;
  i: Integer;
begin
  S := Value;
  i := 0;
  while Pos('->', S) > 0 do
   begin
    i := Pos('->', S);
    S[i] := ' ';
   end;
  Result := Copy(Value, i + 3, Length(Value));
end;

function EditMasterFields(ADataSet: TDataSet; ADataSetProxy: TACRBaseFieldLinkProperty): Boolean;
begin
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('EditMasterFields start');
{$ENDIF}
  with TACRLinkFields.Create(nil) do
   try
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('EditMasterFields 1');
{$ENDIF}
    DataSetProxy := ADataSetProxy;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('EditMasterFields 2');
{$ENDIF}
    DataSet := ADataSet;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('EditMasterFields 3');
{$ENDIF}
    Result := Edit;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('EditMasterFields 4');
{$ENDIF}
   finally
    Free;
   end;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('EditMasterFields finish');
{$ENDIF}
end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRBaseFieldLinkProperty
//
////////////////////////////////////////////////////////////////////////////////


function TACRBaseFieldLinkProperty.GetIndexBased: Boolean;
begin
  Result := False;
end;

function TACRBaseFieldLinkProperty.GetIndexDefs: TIndexDefs;
begin
  Result := nil;
end;

function TACRBaseFieldLinkProperty.GetIndexFieldNames: AnsiString;
begin
  Result := '';
end;

function TACRBaseFieldLinkProperty.GetIndexName: AnsiString;
begin
  Result := '';
end;

procedure TACRBaseFieldLinkProperty.GetIndexNames(List: TStrings);
var
  i: Integer;
begin
  if (IndexDefs <> nil) then
    for i := 0 to IndexDefs.Count - 1 do
      List.Add(IndexDefs.Items[i].Name);
end;

procedure TACRBaseFieldLinkProperty.GetFieldNamesForIndex(List: TStrings);
begin
end;

procedure TACRBaseFieldLinkProperty.SetIndexFieldNames(const Value: AnsiString);
begin
end;

procedure TACRBaseFieldLinkProperty.SetIndexName(const Value: AnsiString);
begin
end;

function TACRBaseFieldLinkProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog];
end;

procedure TACRBaseFieldLinkProperty.Edit;
begin
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRBaseFieldLinkProperty.Edit start');
{$ENDIF}
  FChanged := EditMasterFields(DataSet, Self);
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRBaseFieldLinkProperty.Edit 1');
{$ENDIF}
  if (FChanged) then
   begin
    Modified;
   end;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRBaseFieldLinkProperty.Edit finish');
{$ENDIF}
end;

constructor TACRBaseFieldLinkProperty.CreateWith(ADataSet: TDataSet);
begin
  FDataSet := ADataSet;
end;

function TACRBaseFieldLinkProperty.GetDataSet: TDataSet;
begin
  if (FDataSet) = nil then
    FDataSet := TDataSet(GetComponent(0));
  Result := FDataSet;
end;


////////////////////////////////////////////////////////////////////////////////
//
// TACRLinkFields
//
////////////////////////////////////////////////////////////////////////////////


procedure TACRLinkFields.FormCreate(Sender: TObject);
begin
  OrderedDetailList := TStringList.Create;
  OrderedMasterList := TStringList.Create;
  HelpContext := hcDFieldLinksDesign;
end;

procedure TACRLinkFields.FormDestroy(Sender: TObject);
begin
  OrderedDetailList.Free;
  OrderedMasterList.Free;
end;

function TACRLinkFields.Edit;
begin
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.Edit start');
{$ENDIF}
  Initialize;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.Edit 0');
{$ENDIF}
  if (ShowModal = mrOK) then
   begin
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.Edit 1');
{$ENDIF}
    if (FullIndexName <> '') then
      DataSetProxy.IndexName := FullIndexName
    else
      DataSetProxy.IndexFieldNames := IndexFieldList;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.Edit 2');
{$ENDIF}
    DataSetProxy.MasterFields := MasterFieldList;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.Edit 3');
{$ENDIF}
    Result := True;
   end
  else
   Result := False;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.Edit finish');
{$ENDIF}
end;

procedure TACRLinkFields.SetDataSet(Value: TDataSet);
var
  IndexDefs: TIndexDefs;
begin
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.SetDataSet start');
if (Value = nil) then
  aaWriteToLog('TACRLinkFields.SetDataSet Value = nil');
if (Value.FieldDefs = nil) then
  aaWriteToLog('TACRLinkFields.SetDataSet Value.FieldDefs = nil');
{$ENDIF}
 Value.Open;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.SetDataSet 0');
{$ENDIF}
  Value.FieldDefs.Update;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.SetDataSet 0.1');
{$ENDIF}
 Value.Close;

{$IFDEF DEBUG_TRACE_DATASET}
if (Value.FieldDefs.Updated) then
 aaWriteToLog('TACRLinkFields.SetDataSet updated!')
else
 aaWriteToLog('TACRLinkFields.SetDataSet not updated!');

aaWriteToLog('TACRLinkFields.SetDataSet 1');
{$ENDIF}
  IndexDefs := DataSetProxy.IndexDefs;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.SetDataSet 2');
{$ENDIF}
  if (Assigned(IndexDefs)) then
    IndexDefs.Update;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.SetDataSet 3');
{$ENDIF}
  if ((not Assigned(Value.DataSource)) or
      (not Assigned(Value.DataSource.DataSet))) then
    DatabaseError(ErrorLMissingDataSource, Value);
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.SetDataSet 4');
{$ENDIF}
Value.DataSource.DataSet.Open;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.SetDataSet 4.5');
{$ENDIF}
  Value.DataSource.DataSet.FieldDefs.Update;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.SetDataSet 4.6');
{$ENDIF}
Value.DataSource.DataSet.Close;
{$IFDEF DEBUG_TRACE_DATASET}
if (Value.FieldDefs.Updated) then
 aaWriteToLog('TACRLinkFields.SetDataSet updated2 !')
else
 aaWriteToLog('TACRLinkFields.SetDataSet not updated2 !');
aaWriteToLog('TACRLinkFields.SetDataSet 5');
{$ENDIF}
  FDataSet := Value;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.SetDataSet 6');
{$ENDIF}
  FMasterDataSet := Value.DataSource.DataSet;
{$IFDEF DEBUG_TRACE_DATASET}
aaWriteToLog('TACRLinkFields.SetDataSet finish');
{$ENDIF}
end;

procedure TACRLinkFields.Initialize;
var
  SIndexName: AnsiString;

  procedure SetUpLists(const MasterFieldList, DetailFieldList: AnsiString);
  var
    I, J: Integer;
    MasterFieldName, DetailFieldName: AnsiString;
  begin
    I := 1;
    J := 1;
    while ((I <= Length(MasterFieldList)) and (J <= Length(DetailFieldList))) do
    begin
      MasterFieldName := StripFieldName(MasterFieldList, I);
      DetailFieldName := StripFieldName(DetailFieldList, J);
      if (MasterList.Items.IndexOf(MasterFieldName) <> -1) and
        (OrderedDetailList.IndexOf(DetailFieldName) <> -1) then
      begin
        with OrderedDetailList do
          Objects[IndexOf(DetailFieldName)] := TObject(True);
        with DetailList.Items do
          Delete(IndexOf(DetailFieldName));
        with MasterList.Items do
          Delete(IndexOf(MasterFieldName));
        BindList.Items.Add(Format('%s -> %s',
          [DetailFieldName, MasterFieldName]));
        ClearButton.Enabled := True;
      end;
    end;
  end;

begin
  if (not DataSetProxy.IndexBased) then
   begin
    IndexLabel.Visible := False;
    IndexList.Visible := False;
   end
  else
   with DataSetProxy do
    begin
     GetIndexNames(IndexList.Items);
     if (IndexFieldNames <> '') then
      SIndexName := IndexDefs.FindIndexForFields(IndexFieldNames).Name
     else SIndexName := IndexName;
      if ((SIndexName <> '') and (IndexList.Items.IndexOf(SIndexName) >= 0)) then
       IndexList.ItemIndex := IndexList.Items.IndexOf(SIndexName)
      else
       IndexList.ItemIndex := 0;
    end;
  with DataSetProxy do
   begin
    MasterFieldList := MasterFields;
    if ((IndexFieldNames = '') and (IndexName <> '') and
        (IndexDefs.IndexOf(IndexName) >= 0)) then
      IndexFieldList := IndexDefs[IndexDefs.IndexOf(IndexName)].Fields
    else
      IndexFieldList := IndexFieldNames;
   end;
  IndexListChange(nil);
  FMasterDataSet.GetFieldNames(MasterList.Items);
  OrderedMasterList.Assign(MasterList.Items);
  SetUpLists(MasterFieldList, IndexFieldList);
end;

procedure TACRLinkFields.IndexListChange(Sender: TObject);
var
  I:        Integer;
  IndexExp: AnsiString;
begin
  DetailList.Items.Clear;
  if (DataSetProxy.IndexBased) then
   begin
    DataSetProxy.IndexName := IndexList.Text;
    I := DataSetProxy.IndexDefs.IndexOf(DataSetProxy.IndexName);
    if (I <> -1) then
      IndexExp := DataSetProxy.IndexDefs.Items[I].Expression;
    if (IndexExp <> '') then
      DetailList.Items.Add(IndexExp)
    else
      DataSetProxy.GetFieldNamesForIndex(DetailList.Items);
   end
  else
   DataSet.GetFieldNames(DetailList.Items);
  MasterList.Items.Assign(OrderedMasterList);
  OrderedDetailList.Assign(DetailList.Items);
  for I := 0 to OrderedDetailList.Count - 1 do
    OrderedDetailList.Objects[I] := TObject(False);
  BindList.Clear;
  AddButton.Enabled := False;
  ClearButton.Enabled := False;
  DeleteButton.Enabled := False;
  MasterList.ItemIndex := -1;
end;

procedure TACRLinkFields.OrderFieldList(OrderedList, List: TStrings);
var
  I, J:                         Integer;
  MinIndex, Index, FieldIndex:  Integer;
begin
  for J := 0 to List.Count - 1 do
  begin
    MinIndex := $7FFF;
    FieldIndex := -1;
    for I := J to List.Count - 1 do
    begin
      Index := OrderedList.IndexOf(List[I]);
      if Index < MinIndex then
      begin
        MinIndex := Index;
        FieldIndex := I;
      end;
    end;
    List.Move(FieldIndex, J);
  end;
end;

procedure TACRLinkFields.AddToBindList(const Str1, Str2: AnsiString);
var
  I:        Integer;
  NewField: AnsiString;
  NewIndex: Integer;
begin
  NewIndex := OrderedDetailList.IndexOf(Str1);
  NewField := Format('%s -> %s', [Str1, Str2]);
  with BindList.Items do
   begin
    for I := 0 to Count - 1 do
     begin
      if OrderedDetailList.IndexOf(StripDetail(Strings[I])) > NewIndex then
       begin
        Insert(I, NewField);
        Exit;
      end;
     end;
    Add(NewField);
   end;
end;

procedure TACRLinkFields.BindingListClick(Sender: TObject);
begin
  AddButton.Enabled := (DetailList.ItemIndex <> LB_ERR) and
    (MasterList.ItemIndex <> LB_ERR);
end;

procedure TACRLinkFields.AddButtonClick(Sender: TObject);
var
  DetailIndex: Integer;
  MasterIndex: Integer;
begin
  DetailIndex := DetailList.ItemIndex;
  MasterIndex := MasterList.ItemIndex;
  AddToBindList(DetailList.Items[DetailIndex],
    MasterList.Items[MasterIndex]);
  with OrderedDetailList do
    Objects[IndexOf(DetailList.Items[DetailIndex])] := TObject(True);
  DetailList.Items.Delete(DetailIndex);
  MasterList.Items.Delete(MasterIndex);
  ClearButton.Enabled := True;
  AddButton.Enabled := False;
end;

procedure TACRLinkFields.ClearButtonClick(Sender: TObject);
var
  I: Integer;
  BindValue: AnsiString;
begin
  for I := 0 to BindList.Items.Count - 1 do
   begin
    BindValue := BindList.Items[I];
    DetailList.Items.Add(StripDetail(BindValue));
    MasterList.Items.Add(StripMaster(BindValue));
   end;
  BindList.Clear;
  ClearButton.Enabled := False;
  DeleteButton.Enabled := False;
  OrderFieldList(OrderedDetailList, DetailList.Items);
  DetailList.ItemIndex := -1;
  MasterList.Items.Assign(OrderedMasterList);
  for I := 0 to OrderedDetailList.Count - 1 do
    OrderedDetailList.Objects[I] := TObject(False);
  AddButton.Enabled := False;
end;

procedure TACRLinkFields.DeleteButtonClick(Sender: TObject);
var
  I: Integer;
begin
  with BindList do
   begin
    for I := Items.Count - 1 downto 0 do
     begin
      if Selected[I] then
       begin
        DetailList.Items.Add(StripDetail(Items[I]));
        MasterList.Items.Add(StripMaster(Items[I]));
        with OrderedDetailList do
          Objects[IndexOf(StripDetail(Items[I]))] := TObject(False);
        Items.Delete(I);
       end;
     end;
    if (Items.Count > 0) then
      Selected[0] := True;
    DeleteButton.Enabled := Items.Count > 0;
    ClearButton.Enabled := Items.Count > 0;
    OrderFieldList(OrderedDetailList, DetailList.Items);
    DetailList.ItemIndex := -1;
    OrderFieldList(OrderedMasterList, MasterList.Items);
    MasterList.ItemIndex := -1;
    AddButton.Enabled := False;
   end;
end;

procedure TACRLinkFields.BindListClick(Sender: TObject);
begin
  DeleteButton.Enabled := BindList.ItemIndex <> LB_ERR;
end;

procedure TACRLinkFields.BitBtn1Click(Sender: TObject);
var
  Gap:          Boolean;
  I:            Integer;
  FirstIndex:   Integer;
begin
  FirstIndex := -1;
  MasterFieldList := '';
  IndexFieldList := '';
  FFullIndexName := '';
  if (DataSetProxy.IndexBased) then
   begin
    Gap := False;
    for I := 0 to OrderedDetailList.Count - 1  do
     begin
      if Boolean(OrderedDetailList.Objects[I]) then
       begin
        if Gap then
         begin
          MessageDlg(Format(ErrorLLinkDesigner,
            [OrderedDetailList[FirstIndex]]), mtError, [mbOK], 0);
          ModalResult := 0;
          DetailList.ItemIndex := DetailList.Items.IndexOf(OrderedDetailList[FirstIndex]);
          Exit;
         end;
       end
      else
       begin
        Gap := True;
        if (FirstIndex = -1) then
          FirstIndex := I;
       end;
     end;
    if (not Gap) then
      FFullIndexName := DataSetProxy.IndexName;
   end;
  with (BindList) do
   begin
    for I := 0 to Items.Count - 1 do
     begin
      MasterFieldList := Format('%s%s;', [MasterFieldList, StripMaster(Items[I])]);
      IndexFieldList := Format('%s%s;', [IndexFieldList, StripDetail(Items[I])]);
     end;
    if (MasterFieldList <> '') then
      SetLength(MasterFieldList, Length(MasterFieldList) - 1);
    if (IndexFieldList <> '') then
      SetLength(IndexFieldList, Length(IndexFieldList) - 1);
   end;
end;

procedure TACRLinkFields.HelpClick(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  Application.HelpContext(HelpContext);
{$ENDIF}
{$IFDEF LINUX}
  HelpContext := Application.HelpContext;
{$ENDIF}
end;

end.
