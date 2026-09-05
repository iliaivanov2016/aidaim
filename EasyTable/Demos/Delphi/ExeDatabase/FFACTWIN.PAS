unit Ffactwin;

{ This application shows how to display Paradox style memo and graphic
 fields in a form. Table1's DatabaseName property should point to the
 Delphi sample database. Table1's TableName property should be set to
 the BIOLIFE table. }

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, StdCtrls, DBCtrls, DBGrids, DB, DBTables, Buttons, Grids, ExtCtrls,
  EasyTable, Dialogs;

// path to default database
const DefaultDBFile =  '..\..\Data\DBFishes.edb';

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    DBImage1: TDBImage;
    DBLabel1: TDBText;
    DBMemo1: TDBMemo;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    EasyTable1: TEasyTable;
    EasyDatabase1: TEasyDatabase;
    EasyTable1Category: TStringField;
    EasyTable1Common_Name: TStringField;
    EasyTable1SpeciesName: TStringField;
    EasyTable1Lengthcm: TFloatField;
    EasyTable1Length_In: TFloatField;
    EasyTable1Notes: TMemoField;
    EasyTable1Graphic: TGraphicField;
    bnOpenDB: TButton;
    bnCloseDB: TButton;
    bnMakeEXE: TButton;
    bnExit: TButton;
    Label2: TLabel;
    eDBPath: TEdit;
    Button5: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    DBNavigator1: TDBNavigator;
    Label3: TLabel;
    bnExtract: TButton;
    SaveDialog2: TSaveDialog;
    procedure bnMakeEXEClick(Sender: TObject);
    procedure bnOpenDBClick(Sender: TObject);
    procedure bnCloseDBClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bnExitClick(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure bnExtractClick(Sender: TObject);
  private
    { Private declarations }
    procedure OpenDatabase(bOpenAsExe: Boolean = true);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses Math;

{$R *.DFM}

procedure TForm1.OpenDatabase(bOpenAsExe: Boolean = true);
begin
 if (EasyDatabase1.Connected) then
  EasyDatabase1.Close;
 // try to open application file as database file in read only mode
 if (bOpenAsExe) then
  begin
   EasyDatabase1.DatabaseFileName := Application.ExeName;
   if (EasyDatabase1.IsEasyTableDatabaseFile(EasyDatabase1.DatabaseFileName)) then
    try
     EasyDatabase1.Open;
     eDBPath.Text := Application.ExeName;
   except
     MessageDlg('Error opening database file '+
      AnsiQuotedStr(eDBPath.Text,''''),mtError,[mbOk],0);
     Exit;
    end;
  end
 else
  begin
   // try to open external database file
   // set read only to false
   EasyDatabase1.ReadOnly := False;
   EasyTable1.ReadOnly := False;
   EasyDatabase1.DatabaseFileName := eDBPath.Text;
   if (EasyDatabase1.IsEasyTableDatabaseFile(EasyDatabase1.DatabaseFileName)) then
    begin
     try
      EasyDatabase1.Open;
     except
       MessageDlg('Error opening database file '+
        AnsiQuotedStr(eDBPath.Text,''''),mtError,[mbOk],0);
       Exit;
     end;
    end
   else
    begin
     MessageDlg('Database file '+
        AnsiQuotedStr(eDBPath.Text,'''')+ ' does not exists!',mtError,[mbOk],0);
     Exit;
    end;
  end;
 // open table
 if (EasyDatabase1.Connected) then
  EasyTable1.Open();
end;


procedure TForm1.bnMakeEXEClick(Sender: TObject);
begin
 If SaveDialog1.Execute() Then
  begin
   try
    EasyDatabase1.DatabaseFileName := eDBPath.Text;
    // create executable database file from database file and stub file
    EasyDatabase1.MakeExeDatabase(Application.ExeName,SaveDialog1.FileName);
    MessageDlg('Executable database file created successfully.'+#13#10+'Database FileName = '+
      AnsiQuotedStr(eDBPath.Text,'''') +
      ', executable database FileName = '+
      AnsiQuotedStr(SaveDialog1.FileName,''''),mtInformation,[mbOk],0);
   except
    MessageDlg('Error creating executable database file.'+#13#10+'Database FileName = '+
      AnsiQuotedStr(eDBPath.Text,'''') +
      ', executable database FileName = '+
      AnsiQuotedStr(SaveDialog1.FileName,''''),mtError,[mbOk],0);
   end;
  end;
end;

procedure TForm1.bnOpenDBClick(Sender: TObject);
begin
 OpenDatabase(False);
 EasyTable1.Open;
end;

procedure TForm1.bnCloseDBClick(Sender: TObject);
begin
 EasyDatabase1.Close;
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
 OpenDialog1.InitialDir := DefaultDBFile;
 SaveDialog1.InitialDir := ExtractFilePath(Application.ExeName);
 SaveDialog2.InitialDir := SaveDialog1.InitialDir;
 eDBPath.Text := DefaultDBFile;
 // try to open as executable file
 OpenDatabase(True);
 // if not successful try to open as external database file
 if (not EasyDatabase1.Connected) then
  OpenDatabase(False);
end;

procedure TForm1.bnExitClick(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
 OpenDialog1.InitialDir := ExtractFilePath(eDBPath.Text);
 if (OpenDialog1.Execute) then
  begin
   eDBPath.Text := OpenDialog1.FileName;
  end;
end;

procedure TForm1.bnExtractClick(Sender: TObject);
begin
 if (SaveDialog2.Execute) then
  begin
   try
    EasyDatabase1.CopyDatabase(SaveDialog2.FileName);
    if (EasyDatabase1.Connected) then
     EasyTable1.Open;
    MessageDlg('Database file '+
      AnsiQuotedStr(EasyDatabase1.DatabaseFileName,'''')+' have been extracted to file '+#13#10+
      AnsiQuotedStr(SaveDialog2.FileName,''''),mtInformation,[mbOk],0);
   except
    MessageDlg('Error extracting database file '+
      AnsiQuotedStr(EasyDatabase1.DatabaseFileName,'''')+' to file '+#13#10+
      AnsiQuotedStr(SaveDialog2.FileName,''''),mtError,[mbOk],0);
   end;
  end;
end;

end.
