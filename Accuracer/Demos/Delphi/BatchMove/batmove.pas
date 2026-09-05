unit Batmove;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Db, ComCtrls, ACRMain;


type
  TForm1 = class(TForm)
    Bevel1: TBevel ;
    Label6: TLabel;
    Label7: TLabel;
    cmbxDestTable: TComboBox;
    Label8: TLabel;
    cmbxDestIndex: TComboBox;
    Bevel2: TBevel;
    cmbxSourceTable: TComboBox;
    cmbxSourceIndex: TComboBox;
    Label5: TLabel;
    Label4: TLabel;
    Label3: TLabel;
    cmbxMode: TComboBox;
    Button1: TButton;
    Bevel3: TBevel;
    chkbxAbortKey: TCheckBox;
    chkbxAbortProblem: TCheckBox;
    chkbxTrans: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    Label10: TLabel;
    Label9: TLabel;
    Label12: TLabel;
    edtChangedTable: TEdit;
    Label13: TLabel;
    edtKeyVioTbl: TEdit;
    Label14: TLabel;
    edtProbTbl: TEdit;
    Label11: TLabel;
    edtRecCount: TEdit;
    BatchMove1: TACRBatchMove;
    tblSource: TACRTable;
    tblDest: TACRTable;
    dbSource: TACRDatabase;
    dbDest: TACRDatabase;
    OpenDialog1: TOpenDialog;
    edtSourceDBFileName: TEdit;
    edtDestDBFileName: TEdit;
    bnChooseSourceDB: TButton;
    bnChooseDestDB: TButton;
    Label15: TLabel;
    edtCommitCount: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure cmbxSourceTableChange(Sender: TObject);
    procedure cmbxDestTableChange(Sender: TObject);
    procedure cmbxSourceIndexChange(Sender: TObject);
    procedure cmbxDestIndexChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure chkbxAbortKeyClick(Sender: TObject);
    procedure chkbxAbortProblemClick(Sender: TObject);
    procedure chkbxTransClick(Sender: TObject);
    procedure cmbxModeChange(Sender: TObject);
    procedure edtRecCountKeyPress(Sender: TObject; var Key: Char);
    procedure bnChooseSourceDBClick(Sender: TObject);
    procedure bnChooseDestDBClick(Sender: TObject);
  private
    { Private declarations }
    function IsStringsEqual(const s1,s2 : string): boolean;
//    simple utility function
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject); // Get alias names
begin
  OpenDialog1.InitialDir := ExtractFilePath(Application.ExeName);
end;

procedure TForm1.cmbxSourceTableChange(Sender: TObject);
begin
  if cmbxSourceTable.ItemIndex <> -1 then
  begin
     tblSource.TableName := cmbxSourceTable.Items[cmbxSourceTable.ItemIndex];
     tblSource.GetIndexNames(cmbxSourceIndex.Items);
  end
  else
  begin
    tblSource.TableName := '';
    cmbxSourceIndex.Items.Clear;
  end;

end;

procedure TForm1.cmbxDestTableChange(Sender: TObject);
begin
  if cmbxDestTable.ItemIndex <> -1 then
  begin
     tblDest.TableName := cmbxDestTable.Items[cmbxDestTable.ItemIndex];
     tblDest.GetIndexNames(cmbxDestIndex.Items);
  end
  else
  begin
    tblDest.TableName := '';
    cmbxDestIndex.Items.Clear;
  end;
end;

procedure TForm1.cmbxSourceIndexChange(Sender: TObject);
begin
  if cmbxSourceIndex.ItemIndex <> -1 then
  begin
    tblSource.IndexName := cmbxSourceIndex.Items[cmbxSourceIndex.ItemIndex];
  end
  else
  begin
     tblSource.IndexName := '';
  end;
end;

procedure TForm1.cmbxDestIndexChange(Sender: TObject);
begin
  if cmbxDestIndex.ItemIndex <> -1 then
  begin
    tblDest.IndexName := cmbxDestIndex.Items[cmbxDestIndex.ItemIndex];
  end
  else
  begin
     tblDest.IndexName := '';
  end;

end;

procedure TForm1.Button1Click(Sender: TObject);
var s: String;
begin
  if tblDest.TableName = '' then
    tblDest.TableName := cmbxDestTable.Text;
  if ((dbSource.DatabaseFileName <> '') and // test for enough input
     (tblSource.TableName <> '') and
     (dbDest.DatabaseFileName <> '') and
     (tblDest.TableName <> '') and
     (cmbxMode.items[cmbxMode.ItemIndex] <> '')) then
  begin
    BatchMove1.ChangedTableName := edtChangedTable.Text;  // more batchmove setup
    BatchMove1.KeyViolTableName := edtKeyVioTbl.Text;
    BatchMove1.ProblemTableName := edtProbTbl.Text;
    BatchMove1.RecordCount := StrToInt(edtRecCount.Text);
    BatchMove1.CommitCount := StrToInt(edtCommitCount.Text);
    BatchMove1.Source := tblSource;
    BatchMove1.Destination := tblDest;
  end
  else
  begin
    MessageDlg('Incomplete input.',mtError,[mbOK],0);
    exit;
  end;
  BatchMove1.Execute;  // run the batchmove
  s := 'BatchMove complete. Number of records applied: '+IntToStr(BatchMove1.MovedCount)+
       #13#10 + 'Problem record count: '+ IntToStr(BatchMove1.ProblemCount) +
       #13#10 + 'Changed record count: '+ IntToStr(BatchMove1.ChangedCount) +
       #13#10 + 'Key violation count: '+ IntToStr(BatchMove1.KeyViolCount);
  MessageDlg(s,mtInformation,[mbOK],0);
end;

procedure TForm1.chkbxAbortKeyClick(Sender: TObject);
begin
  BatchMove1.AbortOnKeyViol := chkbxAbortKey.Checked;
end;

procedure TForm1.chkbxAbortProblemClick(Sender: TObject);
begin
  BatchMove1.AbortOnProblem := chkbxAbortProblem.Checked;
end;

procedure TForm1.chkbxTransClick(Sender: TObject);
begin
  BatchMove1.UseTransactions := chkbxTrans.Checked;
end;

function TForm1.IsStringsEqual(const s1,s2 : string): boolean;
begin
   Result := UpperCase(s1) = UpperCase(s2);
end;


// set the batch mode
procedure TForm1.cmbxModeChange(Sender: TObject);
begin
  if cmbxMode.ItemIndex <> -1 then
  begin
    if IsStringsEqual(cmbxMode.Items[cmbxMode.ItemIndex],'Append') then
      BatchMove1.Mode := batAppend
    else if IsStringsEqual(cmbxMode.Items[cmbxMode.ItemIndex],'Copy') then
      BatchMove1.Mode := batCopy
    else if IsStringsEqual(cmbxMode.Items[cmbxMode.ItemIndex],'Append Update') then
      BatchMove1.Mode := batAppendUpdate
    else if IsStringsEqual(cmbxMode.Items[cmbxMode.ItemIndex],'Delete') then
      BatchMove1.Mode := batDelete
    else if IsStringsEqual(cmbxMode.Items[cmbxMode.ItemIndex],'Update') then
      BatchMove1.Mode := batUpdate
    else
      MessageDlg('Batch mode not found',mtError,[mbOK],0);
  end;
end;


// only allow numbers to be typed in
procedure TForm1.edtRecCountKeyPress(Sender: TObject; var Key: Char);
begin
  if ((key in ['0'..'9'] = false) and (word(key) <> VK_BACK)) then
    key := #0;
end;

procedure TForm1.bnChooseSourceDBClick(Sender: TObject);
var x: Integer;
begin
 OpenDialog1.FileName := edtSourceDBFileName.Text;
 if (OpenDialog1.Execute) then
  begin
   edtSourceDBFileName.Text := OpenDialog1.FileName;
   dbSource.Close;
   dbSource.DatabaseFileName := edtSourceDBFileName.Text;
   dbSource.Open;
   x := cmbxSourceTable.ItemIndex;
   dbSource.GetTablesList(cmbxSourceTable.Items);
   cmbxSourceTable.ItemIndex := x;
  end;
end;

procedure TForm1.bnChooseDestDBClick(Sender: TObject);
var x: Integer;
begin
 OpenDialog1.FileName := edtDestDBFileName.Text;
 if (OpenDialog1.Execute) then
  begin
   edtDestDBFileName.Text := OpenDialog1.FileName;
   dbDest.Close;
   dbDest.DatabaseFileName := edtDestDBFileName.Text;
   dbDest.Open;
   x := cmbxDestTable.ItemIndex;
   dbDest.GetTablesList(cmbxDestTable.Items);
   cmbxDestTable.ItemIndex := x;
  end;
end;

end.
