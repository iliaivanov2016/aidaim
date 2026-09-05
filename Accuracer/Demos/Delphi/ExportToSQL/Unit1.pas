unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ACRMain, DB, StdCtrls, ComCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    ACRTable1: TACRTable;
    ACRDatabase1: TACRDatabase;
    ACRDatabase2: TACRDatabase;
    ACRQuery1: TACRQuery;
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
    Button4: TButton;
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
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
 ACRDatabase1.Open;
 ACRDatabase1.GetTablesList(lbTables.Items);
 if (not ACRDatabase2.Exists) then
  ACRDatabase2.CreateDatabase;
 ACRDatabase2.Open;
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
     ACRTable1.TableName := lbTables.Items[i];
     s := s + ACRTable1.ExportTableToSQL(
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
 ACRQuery1.SQL.Text := Memo1.Text;
 ACRQuery1.ExecSQL;
 ShowMessage('Script executed successfully, rows affected = '+IntToStr(ACRQuery1.RowsAffected));
end;

procedure TForm1.Button4Click(Sender: TObject);
var s:  String;
    fs: TFileStream;
begin
 s := ACRDatabase1.ExportDatabaseToSQL(
      cbExportStructure.Checked,
      cbAddDROPTable.Checked,
      cbExportIndexes.Checked,
      cbAddDROPIndex.Checked,
      cbExportData.Checked,
      cbExportBLOBFields.Checked,
      cbUseBrackets.Checked);
 Memo1.Text := s;
 fs := TFileStream.Create('test.sql',fmCreate);
 fs.WriteBuffer(PChar(@s[1])^,Length(s));
 fs.Free;
end;

end.
