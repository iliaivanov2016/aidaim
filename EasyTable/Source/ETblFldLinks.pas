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
//  Modified by AidAim Software, 2001                  //
//                                                     //
//-----------------------------------------------------//

{$I ETblVer.inc}

unit ETblFldLinks;

interface

uses SysUtils, Windows, Messages, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, DB, Buttons,
 {$IFDEF D6H}
  DesignIntf, DesignEditors;
 {$ELSE}
  DSGNINTF;
 {$ENDIF}

const
  SMissingDataSource = 'Missing MasterSource or DataSource.';
  SLinkDesigner = 'Field %s, from the Detail Fields list, must be linked';
type

{ TFieldLink }

  TFieldLinkProperty = class(TStringProperty)
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

{ TLink Fields }

  TLinkFields = class(TForm)
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
    FDataSetProxy: TFieldLinkProperty;
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
    property DataSetProxy: TFieldLinkProperty read FDataSetProxy write FDataSetProxy;
    function Edit: Boolean;
  end;

function EditMasterFields(ADataSet: TDataSet; ADataSetProxy: TFieldLinkProperty): Boolean;

implementation

{$R *.DFM}

uses Dialogs, DBConsts, LibHelp, TypInfo{, DsnDBCst},
     EasyTable;

{ Utility Functions }

function StripFieldName(const Fields: AnsiString; var Pos: Integer): AnsiString;
var
  I: Integer;
begin
  I := Pos;
  while (I <= Length(Fields)) and (Fields[I] <> ';') do Inc(I);
  Result := Copy(Fields, Pos, I - Pos);
  if (I <= Length(Fields)) and (Fields[I] = ';') then Inc(I);
  Pos := I;
end;

function StripDetail(const Value: AnsiString): AnsiString;
var
  S: AnsiString;
  I: Integer;
begin
  S := Value;
  I := 0;
  while Pos('->', S) > 0 do
  begin
    I := Pos('->', S);
    S[I] := ' ';
  end;
  Result := Copy(Value, 0, I - 2);
end;

function StripMaster(const Value: AnsiString): AnsiString;
var
  S: AnsiString;
  I: Integer;
begin
  S := Value;
  I := 0;
  while Pos('->', S) > 0 do
  begin
    I := Pos('->', S);
    S[I] := ' ';
  end;
  Result := Copy(Value, I + 3, Length(Value));
end;

function EditMasterFields(ADataSet: TDataSet; ADataSetProxy: TFieldLinkProperty): Boolean;
begin
  with TLinkFields.Create(nil) do
  try
    DataSetProxy := ADataSetProxy;
    DataSet := ADataSet;
    Result := Edit;
  finally
    Free;
  end;
end;

{ TFieldLinkProperty }

function TFieldLinkProperty.GetIndexBased: Boolean;
begin
  Result := False;
end;

function TFieldLinkProperty.GetIndexDefs: TIndexDefs;
begin
  Result := nil;
end;

function TFieldLinkProperty.GetIndexFieldNames: AnsiString;
begin
  Result := '';
end;

function TFieldLinkProperty.GetIndexName: AnsiString;
begin
  Result := '';
end;

procedure TFieldLinkProperty.GetIndexNames(List: TStrings);
var
  i: Integer;
begin
  if IndexDefs <> nil then
    for i := 0 to IndexDefs.Count - 1 do
      if (ixPrimary in IndexDefs.Items[i].Options) and
         (IndexDefs.Items[i].Name = '') then
//        List.Add(SPrimary)
        List.Add('Primary')
       else
        List.Add(IndexDefs.Items[i].Name);
end;
 
procedure TFieldLinkProperty.GetFieldNamesForIndex(List: TStrings); 
begin
end; 
	
procedure TFieldLinkProperty.SetIndexFieldNames(const Value: AnsiString);
begin 
end;
 
procedure TFieldLinkProperty.SetIndexName(const Value: AnsiString);
begin 
end;
 
function TFieldLinkProperty.GetAttributes: TPropertyAttributes; 
begin 
  Result := [paDialog];
end;
	
procedure TFieldLinkProperty.Edit; 
begin 
  FChanged := EditMasterFields(DataSet, Self); 
  if FChanged then Modified;
end; 
	
constructor TFieldLinkProperty.CreateWith(ADataSet: TDataSet);
begin 
  FDataSet := ADataSet;
end; 
	
function TFieldLinkProperty.GetDataSet: TDataSet; 
begin 
  if FDataSet = nil then
    FDataSet := TDataSet(GetComponent(0)); 
  Result := FDataSet;
end; 
	
{ TLinkFields }
 
procedure TLinkFields.FormCreate(Sender: TObject);
begin
  OrderedDetailList := TStringList.Create;
  OrderedMasterList := TStringList.Create;
  HelpContext := hcDFieldLinksDesign;
end; 
	
procedure TLinkFields.FormDestroy(Sender: TObject);
begin
  OrderedDetailList.Free;
  OrderedMasterList.Free; 
end;
 
function TLinkFields.Edit;
begin
  Initialize;
  if ShowModal = mrOK then
  begin 
    if FullIndexName <> '' then
      DataSetProxy.IndexName := FullIndexName else 
      DataSetProxy.IndexFieldNames := IndexFieldList; 
    DataSetProxy.MasterFields := MasterFieldList;
    Result := True; 
  end 
  else
    Result := False;
end;
 
procedure TLinkFields.SetDataSet(Value: TDataSet);
var 
  IndexDefs: TIndexDefs; 
begin
  Value.FieldDefs.Update; 
  IndexDefs := DataSetProxy.IndexDefs;
  if Assigned(IndexDefs) then IndexDefs.Update; 
  if  not Assigned(Value.DataSource) or 
      not Assigned(Value.DataSource.DataSet) then 
    DatabaseError(SMissingDataSource, Value); 
  Value.DataSource.DataSet.FieldDefs.Update;
  FDataSet := Value;
  FMasterDataSet := Value.DataSource.DataSet; 
end;
 
procedure TLinkFields.Initialize;
var 
  SIndexName: AnsiString; 
	
  procedure SetUpLists(const MasterFieldList, DetailFieldList: AnsiString);
  var
    I, J: Integer; 
    MasterFieldName, DetailFieldName: AnsiString;
  begin
    I := 1; 
    J := 1; 
    while (I <= Length(MasterFieldList)) and (J <= Length(DetailFieldList)) do 
    begin
      MasterFieldName := StripFieldName(MasterFieldList, I);
      DetailFieldName := StripFieldName(DetailFieldList, J);
      if (MasterList.Items.IndexOf(MasterFieldName) <> -1) and
        (OrderedDetailList.IndexOf(DetailFieldName) <> -1) then 
      begin
        with OrderedDetailList do 
          Objects[IndexOf(DetailFieldName)] := TObject(True); 
        with DetailList.Items do Delete(IndexOf(DetailFieldName)); 
        with MasterList.Items do Delete(IndexOf(MasterFieldName));
        BindList.Items.Add(Format('%s -> %s', 
          [DetailFieldName, MasterFieldName])); 
        ClearButton.Enabled := True;
      end; 
    end;
  end;
	
begin
  if not DataSetProxy.IndexBased then
  begin
    IndexLabel.Visible := False; 
    IndexList.Visible := False; 
  end 
  else with DataSetProxy do 
  begin
    GetIndexNames(IndexList.Items);
    if IndexFieldNames <> '' then
      SIndexName := IndexDefs.FindIndexForFields(IndexFieldNames).Name 
    else SIndexName := IndexName; 
    if (SIndexName <> '') and (IndexList.Items.IndexOf(SIndexName) >= 0) then 
      IndexList.ItemIndex := IndexList.Items.IndexOf(SIndexName) else 
      IndexList.ItemIndex := 0;
  end; 
  with DataSetProxy do
  begin 
    MasterFieldList := MasterFields;
    if (IndexFieldNames = '') and (IndexName <> '') and
      (IndexDefs.IndexOf(IndexName) >=0) then
      IndexFieldList := IndexDefs[IndexDefs.IndexOf(IndexName)].Fields else
      IndexFieldList := IndexFieldNames;
  end;
  IndexListChange(nil);
  FMasterDataSet.GetFieldNames(MasterList.Items);
  OrderedMasterList.Assign(MasterList.Items);
  SetUpLists(MasterFieldList, IndexFieldList);
end;

procedure TLinkFields.IndexListChange(Sender: TObject);
var
  I: Integer;
  IndexExp: AnsiString;
begin
  DetailList.Items.Clear;
  if DataSetProxy.IndexBased then
  begin
    DataSetProxy.IndexName := IndexList.Text;
    I := DataSetProxy.IndexDefs.IndexOf(DataSetProxy.IndexName);
    if (I <> -1) then IndexExp := DataSetProxy.IndexDefs.Items[I].Expression;
    if IndexExp <> '' then
      DetailList.Items.Add(IndexExp) else
      DataSetProxy.GetFieldNamesForIndex(DetailList.Items);
  end else
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

procedure TLinkFields.OrderFieldList(OrderedList, List: TStrings);
var
  I, J: Integer;
  MinIndex, Index, FieldIndex: Integer;
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

procedure TLinkFields.AddToBindList(const Str1, Str2: AnsiString);
var
  I: Integer;
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

procedure TLinkFields.BindingListClick(Sender: TObject);
begin
  AddButton.Enabled := (DetailList.ItemIndex <> LB_ERR) and
    (MasterList.ItemIndex <> LB_ERR);
end;

procedure TLinkFields.AddButtonClick(Sender: TObject);
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

procedure TLinkFields.ClearButtonClick(Sender: TObject);
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

procedure TLinkFields.DeleteButtonClick(Sender: TObject);
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
    if Items.Count > 0 then Selected[0] := True;
    DeleteButton.Enabled := Items.Count > 0;
    ClearButton.Enabled := Items.Count > 0;
    OrderFieldList(OrderedDetailList, DetailList.Items);
    DetailList.ItemIndex := -1;
    OrderFieldList(OrderedMasterList, MasterList.Items);
    MasterList.ItemIndex := -1;
    AddButton.Enabled := False;
  end;
end;

procedure TLinkFields.BindListClick(Sender: TObject);
begin
  DeleteButton.Enabled := BindList.ItemIndex <> LB_ERR;
end;

procedure TLinkFields.BitBtn1Click(Sender: TObject);
var
  Gap: Boolean;
  I: Integer;
  FirstIndex: Integer;
begin
  FirstIndex := -1;
  MasterFieldList := '';
  IndexFieldList := '';
  FFullIndexName := '';
  if DataSetProxy.IndexBased then
  begin
    Gap := False;
    for I := 0 to OrderedDetailList.Count - 1  do
    begin
      if Boolean(OrderedDetailList.Objects[I]) then
      begin
        if Gap then
        begin
          MessageDlg(Format(SLinkDesigner,
            [OrderedDetailList[FirstIndex]]), mtError, [mbOK], 0);
          ModalResult := 0;
          DetailList.ItemIndex := DetailList.Items.IndexOf(OrderedDetailList[FirstIndex]);
          Exit;
        end;
      end
      else begin
        Gap := True;
        if FirstIndex = -1 then FirstIndex := I;
      end;
    end;
    if not Gap then FFullIndexName := DataSetProxy.IndexName;
  end;
  with BindList do
  begin
    for I := 0 to Items.Count - 1 do
    begin
      MasterFieldList := Format('%s%s;', [MasterFieldList, StripMaster(Items[I])]);
      IndexFieldList := Format('%s%s;', [IndexFieldList, StripDetail(Items[I])]);
    end;
    if MasterFieldList <> '' then
      SetLength(MasterFieldList, Length(MasterFieldList) - 1);
    if IndexFieldList <> '' then
      SetLength(IndexFieldList, Length(IndexFieldList) - 1);
  end;
end;

procedure TLinkFields.HelpClick(Sender: TObject);
begin
  Application.HelpContext(HelpContext);
end;

end.
