unit AddIndex;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Grids, DBGrids,Db,ACRMain, ACRTypes;

type
  TFormAddIndex = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    BitBtn3: TBitBtn;
    BitBtn1: TBitBtn;
    FieldsList: TListBox;
    MoveRightButton: TButton;
    MoveAllRightButton: TButton;
    MoveAllLeftButton: TButton;
    MoveLeftButton: TButton;
    IndexFieldsGrid: TDBGrid;
    procedure FormActivate(Sender: TObject);
    procedure MoveRightButtonClick(Sender: TObject);
    procedure MoveLeftButtonClick(Sender: TObject);
    procedure MoveAllRightButtonClick(Sender: TObject);
    procedure MoveAllLeftButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure NewRecord(DataSet: TDataSet);
    { Public declarations }
  end;

var
  FormAddIndex: TFormAddIndex;

implementation

uses MainUnit;

{$R *.DFM}

procedure TFormAddIndex.FormActivate(Sender: TObject);
var i : integer;
    fList,dList,cList : TACRWideStringList;
    fields,desc,case_ins : string;
begin
 MainForm.DialogsTable.Active := false;
 MainForm.DialogsTable.FieldDefs.Clear;
 MainForm.DialogsTable.IndexDefs.Clear;
 MainForm.DialogsTable.FieldDefs.Add('id',ftAutoInc,0,false);
 MainForm.DialogsTable.FieldDefs.Add('Fields',ftString,5000,false);
 MainForm.DialogsTable.FieldDefs.Add('Descending',ftBoolean,0,false);
 MainForm.DialogsTable.FieldDefs.Add('Case_insensitive',ftBoolean,0,false);
// MainForm.DialogsTable.DatabaseName := ExtractFilePath(Application.ExeName)+'Data';
 MainForm.DialogsTable.CreateTable;
 MainForm.DialogsTable.Active := true;
 IndexFieldsGrid.Columns[0].DisplayName := 'Index fields';
 IndexFieldsGrid.Columns[0].ReadOnly := true;
 IndexFieldsGrid.Columns[1].DisplayName := 'Descending';
 IndexFieldsGrid.Columns[1].DropDownRows := 2;
 IndexFieldsGrid.Columns[1].PickList.Clear;
 IndexFieldsGrid.Columns[1].PickList.Add('True');
 IndexFieldsGrid.Columns[1].PickList.Add('False');
 IndexFieldsGrid.Columns[2].DisplayName := 'Case insensitive';
 IndexFieldsGrid.Columns[2].PickList.Clear;
 IndexFieldsGrid.Columns[2].PickList.Add('True');
 IndexFieldsGrid.Columns[2].PickList.Add('False');
 IndexFieldsGrid.Columns[3].Visible := false;
 MainForm.DialogsTable.OnNewRecord := NewRecord;
 MainForm.FieldsTable.First;
 FieldsList.Clear;
 while not MainForm.FieldsTable.Eof do
  begin
   FieldsList.Items.Add(MainForm.FieldsTable.FieldByName('Name').AsString);
   MainForm.FieldsTable.Next;
  end;
 FieldsList.Sorted := true;
 i := MainForm.IndexGrid.SelectedIndex;
 if (i < 0) then
  Exit;
 if (MainForm.IndexesTable.FieldByName('Index_fields').AsString = '') then
  Exit;
 fList := TACRWideStringList.Create;
 dList := TACRWideStringList.Create;
 cList := TACRWideStringList.Create;

 fields := MainForm.IndexesTable.FieldByName('Index_fields').AsString;
 desc := MainForm.IndexesTable.FieldByName('Desc_fields').AsString;
 case_ins := MainForm.IndexesTable.FieldByName('Case_ins_fields').AsString;
 GetNamesList(fList,fields);
 GetNamesList(dList,desc);
 GetNamesList(cList,case_ins);
 if (fList.Count <= 0) then
  begin
   dList.Free;
   cList.Free;
   fList.Free;
   Exit;
  end;
 // fields
 for i := 0 to fList.Count-1 do
  begin
   MainForm.DialogsTable.Insert;
   MainForm.DialogsTable.FieldByName('Fields').AsString := fList.strings[i];
   MainForm.DialogsTable.Post;
  end;
 MainForm.DialogsTable.FilterOptions := [foCaseInsensitive,foNoPartialCompare];
 // descending fields
 for i := 0 to dList.Count-1 do
  begin
   MainForm.DialogsTable.Filter := 'Fields = '+
      AnsiQuotedStr(dList.strings[i],'''');
   if (not MainForm.DialogsTable.FindFirst) then
    begin
     MainForm.DialogsTable.EmptyTable;
     dList.Free;
     cList.Free;
     fList.Free;
     MessageDlg('Invalid descending field = "'+dList.strings[i]+'"',mtError,[mbOk],0);
     Exit;
    end;
   MainForm.DialogsTable.Edit;
   MainForm.DialogsTable.FieldByName('Descending').AsBoolean := True;
   MainForm.DialogsTable.Post;
  end;
 // case insensitive fields
 for i := 0 to cList.Count-1 do
  begin
   MainForm.DialogsTable.Filter := 'Fields = '+
      AnsiQuotedStr(cList.strings[i],'''');
   if (not MainForm.DialogsTable.FindFirst) then
    begin
     MainForm.DialogsTable.EmptyTable;
     dList.Free;
     cList.Free;
     fList.Free;
     MessageDlg('Invalid case insensitive field = "'+cList.strings[i]+'"',mtError,[mbOk],0);
     Exit;
    end;
   MainForm.DialogsTable.Edit;
   MainForm.DialogsTable.FieldByName('Case_insensitive').AsBoolean := True;
   MainForm.DialogsTable.Post;
  end;
 i := 0;
 while i < FieldsList.Items.Count do
  begin
   MainForm.DialogsTable.Filter := 'Fields = '+
      AnsiQuotedStr(FieldsList.Items[i],'''');
   if (MainForm.DialogsTable.FindFirst) then
    FieldsList.Items.Delete(i)
   else
    inc(i);
  end;
 FieldsList.Sorted := True; 
 dList.Free;
 cList.Free;
 fList.Free;
end;

procedure TFormAddIndex.NewRecord(DataSet: TDataSet);
begin
 DataSet.FieldByName('Descending').AsBoolean := false;
 DataSet.FieldByName('Case_insensitive').AsBoolean := false;
end;


procedure TFormAddIndex.MoveRightButtonClick(Sender: TObject);
var i : integer;
begin
 i := FieldsList.ItemIndex;
 if (i < 0) then
  begin
   MessageDlg('You should select field for inserting it in index!',mtWarning,[mbOk],0);
   Exit;
  end;
 MainForm.DialogsTable.Insert;
 MainForm.DialogsTable.FieldByName('Fields').AsString := FieldsList.Items[i];
 MainForm.DialogsTable.Post;
 FieldsList.Items.Delete(i);
 FieldsList.Sorted := true;
end;

procedure TFormAddIndex.MoveLeftButtonClick(Sender: TObject);
begin
 if (MainForm.DialogsTable.RecordCount <= 0) then
  begin
   MessageDlg('You should select field for inserting it in index!',mtWarning,[mbOk],0);
   Exit;
  end;

 FieldsList.Items.Add(MainForm.DialogsTable.FieldByName('Fields').AsString);
 MainForm.DialogsTable.Delete;
 FieldsList.Sorted := true;
end;

procedure TFormAddIndex.MoveAllRightButtonClick(Sender: TObject);
var i,j : integer;
begin
 for j := 0 to FieldsList.Items.Count-1 do
  begin
   i := 0;
   MainForm.DialogsTable.Insert;
   MainForm.DialogsTable.FieldByName('Fields').AsString := FieldsList.Items[i];
   MainForm.DialogsTable.Post;
   FieldsList.Items.Delete(i);
  end;
end;

procedure TFormAddIndex.MoveAllLeftButtonClick(Sender: TObject);
begin
 MainForm.DialogsTable.First;
  while MainForm.DialogsTable.RecordCount > 0 do
   begin
     FieldsList.Items.Add(MainForm.DialogsTable.FieldByName('Fields').AsString);
     MainForm.DialogsTable.Delete;
   end;
 FieldsList.Sorted := true;
end;

end.
