unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, StdCtrls, ComCtrls, ExtCtrls, SQLMemMain;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Button1: TButton;
    Button3: TButton;
    Button2: TButton;
    Panel4: TPanel;
    Label1: TLabel;
    gbSQL: TGroupBox;
    Memo1: TRichEdit;
    PageControl1: TPageControl;
    tsTables: TTabSheet;
    tsExportOptions: TTabSheet;
    gbTables: TGroupBox;
    lbTables: TListBox;
    gbExportOptions: TGroupBox;
    GroupBox3: TGroupBox;
    cbExportStructure: TCheckBox;
    cbAddDROPTable: TCheckBox;
    GroupBox4: TGroupBox;
    cbExportData: TCheckBox;
    cbExportBLOBFields: TCheckBox;
    GroupBox5: TGroupBox;
    cbExportIndexes: TCheckBox;
    cbAddDROPIndex: TCheckBox;
    cbUseBrackets: TCheckBox;
    Splitter1: TSplitter;
    SQLMemTable1: TSQLMemTable;
    SQLMemQuery1: TSQLMemQuery;
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
 Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 SQLMemQuery1.ExecSQL;
 SQLMemTable1.GetTableNames(lbTables.Items);
end;

procedure TForm1.Button1Click(Sender: TObject);
var s:  String;
    fs: TFileStream;
    i:  Integer;
begin
 s := '';
 if (lbTables.SelCount > 0) then
  for i := 0 to lbTables.Count - 1 do
   if (lbTables.Selected[i]) then
    begin
     SQLMemTable1.TableName := lbTables.Items[i];
     s := s + SQLMemTable1.ExportTableToSQL(
      cbExportStructure.Checked,
      cbAddDROPTable.Checked,
      cbExportIndexes.Checked,
      cbAddDROPIndex.Checked,
      cbExportData.Checked,
      cbExportBLOBFields.Checked,
      cbUseBrackets.Checked);
    end;
 Memo1.Text := s;
 fs := TFileStream.Create('test.sql',fmCreate);
 fs.WriteBuffer(PChar(@s[1])^,Length(s));
 fs.Free;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 SQLMemQuery1.SQL.Text := Memo1.Text;
 SQLMemQuery1.ExecSQL;
 ShowMessage('Script executed successfully, rows affected = '+IntToStr(SQLMemQuery1.RowsAffected));
end;

end.
