unit Batmove;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Db, ComCtrls,  DBCtrls, Grids, DBGrids,
  SQLMemMain;


type
  TForm1 = class(TForm)
    Bevel1: TBevel ;
    Label8: TLabel;
    cmbxDestIndex: TComboBox;
    cmbxSourceIndex: TComboBox;
    Label5: TLabel;
    cmbxMode: TComboBox;
    Button1: TButton;
    Bevel3: TBevel;
    chkbxAbortKey: TCheckBox;
    chkbxAbortProblem: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    Label10: TLabel;
    Label9: TLabel;
    Label11: TLabel;
    edtRecCount: TEdit;
    BatchMove1: TSQLMemBatchMove;
    tDest: TSQLMemTable;
    Bevel2: TBevel;
    dsSource: TDataSource;
    dsDest: TDataSource;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBNavigator2: TDBNavigator;
    tSource: TSQLMemTable;
    procedure FormCreate(Sender: TObject);
    procedure cmbxDestIndexChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure chkbxAbortKeyClick(Sender: TObject);
    procedure chkbxAbortProblemClick(Sender: TObject);
    procedure cmbxModeChange(Sender: TObject);
    procedure edtRecCountKeyPress(Sender: TObject; var Key: Char);
    procedure cmbxSourceIndexChange(Sender: TObject);
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
 tSource.Close;

 // field definitions were filled using design-time FieldDefs editor
 tSource.CreateTable;
 tSource.Open;
 tSource.Insert;
 tSource.FieldByName('Company').AsString := 'AidAim Software LLC';
 tSource.FieldByName('Address').AsString := '555 Vine Ave., Suite 110, Highland Park, IL 60035, USA';
 tSource.FieldByName('TaxRate').AsFloat := 20.5;
 tSource.FieldByName('LastInvoiceDate').AsDateTime := Now;
 tSource.Post;
 tSource.Insert;
 tSource.FieldByName('Company').AsString := 'Borland Software Corporation';
 tSource.Post;
 tSource.Insert;
 tSource.FieldByName('Company').AsString := 'Oracle Corporation';
 tSource.Post;
 tSource.Insert;
 tSource.FieldByName('Company').AsString := 'Microsoft Corporation';
 tSource.Post;
 tSource.Insert;
 tSource.FieldByName('Company').AsString := 'IBM Corporation';
 tSource.Post;
 tSource.GetIndexNames(cmbxSourceIndex.Items);
end;

procedure TForm1.cmbxDestIndexChange(Sender: TObject);
begin
  if cmbxDestIndex.ItemIndex <> -1 then
  begin
    tDest.IndexName := cmbxDestIndex.Items[cmbxDestIndex.ItemIndex];
  end
  else
  begin
     tDest.IndexName := '';
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var s: String;
begin
  if (cmbxMode.items[cmbxMode.ItemIndex] <> '') then
  begin
    BatchMove1.RecordCount := StrToInt(edtRecCount.Text);
    BatchMove1.Source := tSource;
    BatchMove1.Destination := tDest;
  end
  else
  begin
    MessageDlg('Incomplete input.',mtError,[mbOK],0);
    exit;
  end;
  BatchMove1.Execute;  // run the batchmove
  if (BatchMove1.Mode = batCopy) then
   tDest.Open;
  tDest.GetIndexNames(cmbxDestIndex.Items);
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

procedure TForm1.cmbxSourceIndexChange(Sender: TObject);
begin
  if cmbxSourceIndex.ItemIndex <> -1 then
   tSource.IndexName := cmbxSourceIndex.Items[cmbxSourceIndex.ItemIndex]
  else
   tSource.IndexName := '';
end;

end.
