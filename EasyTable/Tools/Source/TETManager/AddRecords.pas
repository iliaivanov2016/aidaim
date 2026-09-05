unit AddRecords;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, EasyTable, Db, Dialogs;

type
  TAddRecordsForm = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    Bevel1: TBevel;
    lbTables: TListBox;
    Label1: TLabel;
    SrcTable: TEasyTable;
    rgImportMode: TRadioGroup;
    Label2: TLabel;
    procedure OKBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AddRecordsForm: TAddRecordsForm;

implementation

{$R *.DFM}

uses MainUnit;

procedure TAddRecordsForm.OKBtnClick(Sender: TObject);
var
  Mode: TAddRecordsMode;
  log: AnsiString;
begin
 SrcTable.TableName := lbTables.Items.Strings[lbTables.ItemIndex];
 SrcTable.Active := True;
 try
  Mode := TAddRecordsMode(rgImportMode.ItemIndex);
  if (MainForm.CurrentTable.AddRecords(SrcTable, Mode, log)) then
   MessageDlg('Records were processed successfully.', mtInformation, [mbOk], 0)
  else
   MessageDlg('Adding records problems:'+#13#10+log, mtError, [mbOK], 0);
 finally
  SrcTable.Active := False;
  Close;
 end;
end;

procedure TAddRecordsForm.FormCreate(Sender: TObject);
begin
 SrcTable.DatabaseName := MainForm.CurrentDB.DatabaseName;
end;

procedure TAddRecordsForm.FormShow(Sender: TObject);
begin
 lbTables.Clear;
 MainForm.CurrentDB.GetTablesList(lbTables.Items);
 if (lbTables.Items.IndexOf(MainForm.CurrentTable.TableName) > -1) then
  lbTables.Items.Delete(lbTables.Items.IndexOf(MainForm.CurrentTable.TableName));
 lbTables.ItemIndex := 0;
end;

end.
