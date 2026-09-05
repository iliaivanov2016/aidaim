unit uMain;

interface

{$I SQLMemVer.Inc}

{$IFDEF VER200}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  SQLMemMain, Db, StdCtrls, ExtCtrls, DBCtrls, Grids, DBGrids
  {$IFDEF D6H}
  ,Variants
  {$ENDIF}
  ;


type
  TForm1 = class(TForm)
    SQLMemTable1: TSQLMemTable;
    dsTable: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Label1: TLabel;
    bnSave: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    bnLoad: TButton;
    bnExit: TButton;
    procedure FormCreate(Sender: TObject);
    procedure bnLoadClick(Sender: TObject);
    procedure bnSaveClick(Sender: TObject);
    procedure bnExitClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject);
begin
 OpenDialog1.InitialDir := ExtractFilePath(Application.ExeName);
 SaveDialog1.InitialDir := ExtractFilePath(Application.ExeName);

 Caption := 'SQLMemTable LoadSave Demo. (c) AidAim Software, 2003-2008.';
 SQLMemTable1.Close;

 // field definitions were filled using design-time FieldDefs editor
 SQLMemTable1.CreateTable;
 SQLMemTable1.Open;
 SQLMemTable1.Insert;
 SQLMemTable1.FieldByName('Company').AsString := 'AidAim Software';
 SQLMemTable1.FieldByName('Address').AsString := '555 Vine Ave., Suite 110, Highland Park, IL 60035, USA';
 SQLMemTable1.FieldByName('TaxRate').AsFloat := 20.5;
 SQLMemTable1.FieldByName('LastInvoiceDate').AsDateTime := Now;
 SQLMemTable1.Post;
 SQLMemTable1.Insert;
 SQLMemTable1.FieldByName('Company').AsString := 'Borland Software Corporation';
 SQLMemTable1.Post;
 SQLMemTable1.Insert;
 SQLMemTable1.FieldByName('Company').AsString := 'Oracle Corporation';
 SQLMemTable1.Post;
 SQLMemTable1.Insert;
 SQLMemTable1.FieldByName('Company').AsString := 'Microsoft Corporation';
 SQLMemTable1.Post;
 SQLMemTable1.Insert;
 SQLMemTable1.FieldByName('Company').AsString := 'IBM Corporation';
 SQLMemTable1.Post;
end;

procedure TForm1.bnLoadClick(Sender: TObject);
begin
 if (OpenDialog1.Execute()) then
  begin
   SQLMemTable1.Close;
   try
     if (SQLMemTable1.Exists) then
      SQLMemTable1.DeleteTable;
     SQLMemTable1.LoadTableFromFile(OpenDialog1.FileName);
     SQLMemTable1.Open;
     MessageDlg('Table was successfully loaded from file '+OpenDialog1.FileName,
       mtInformation,[mbOK],0);
   except
     MessageDlg('Error - Cannot load table from file '+OpenDialog1.FileName,
       mtError,[mbOK],0);
     SQLMemTable1.Close;
   end;
  end;
end;

procedure TForm1.bnSaveClick(Sender: TObject);
begin
 if (SaveDialog1.Execute()) then
  begin
   SQLMemTable1.Close;
   try
     SQLMemTable1.SaveTableToFile(SaveDialog1.FileName);
     MessageDlg('Table was successfully saved to file '+OpenDialog1.FileName,
       mtInformation,[mbOK],0);
   except
     MessageDlg('Error - Cannot save table to file '+SaveDialog1.FileName,
       mtError,[mbOK],0);
   end;
   SQLMemTable1.Open;
  end;
end;

procedure TForm1.bnExitClick(Sender: TObject);
begin
  Close();
end;

end.
