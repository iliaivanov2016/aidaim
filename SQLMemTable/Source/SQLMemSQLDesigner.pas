unit SQLMemSQLDesigner;

interface

{$I SQLMemVer.Inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, DB, StdCtrls, ComCtrls, ExtCtrls
  ,SQLMemMain
  {$IFDEF DEBUG_LOG}
  ,SQLMemDebug
  {$ENDIF}
  ;

type
  TSQLMemfmSQLDesigner = class(TForm)
    Panel1: TPanel;
    gbSQL: TGroupBox;
    reSQL: TRichEdit;
    bnOK: TButton;
    bnCancel: TButton;
    bnLoad: TButton;
    bnSave: TButton;
    odLoadSQL: TOpenDialog;
    sdSaveSQL: TSaveDialog;
    procedure bnLoadClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure bnSaveClick(Sender: TObject);
    procedure reSQLChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure bnOKClick(Sender: TObject);
    procedure bnCancelClick(Sender: TObject);
  private
    { Private declarations }
    FQuery:       TSQLMemQuery;
    FSQLChanged:  Boolean;
  public
    { Public declarations }
    function GetSQLCaption: String;
    procedure SetQuery(Query: TSQLMemQuery);
  end;

var
  SQLMemfmSQLDesigner: TSQLMemfmSQLDesigner;

implementation

{$R *.dfm}

procedure TSQLMemfmSQLDesigner.bnLoadClick(Sender: TObject);
begin
 ModalResult := mrNone;
 if (FQuery <> nil) then
  if (odLoadSQL.Execute) then
   begin
    FQuery.SQL.LoadFromFile(odLoadSQL.FileName);
    FSQLChanged := False;
    reSQL.OnChange := nil;
    try
      reSQL.Text := FQuery.Text;
    finally
      reSQL.OnChange := reSQLChange;
    end;
    gbSQL.Caption := GetSQLCaption;
   end;
end;

procedure TSQLMemfmSQLDesigner.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
;
end;

procedure TSQLMemfmSQLDesigner.FormCreate(Sender: TObject);
begin
  FQuery := nil;
  FSQLChanged := False;
  ModalResult := mrNone;
  {$IFDEF SQLMEMTABLE}
  Caption := 'SQLMemTable SQL Designer';
  {$ELSE}
  Caption := 'SQLMemTable SQL Designer';
  {$ENDIF}
  gbSQL.Caption := GetSQLCaption;
end;

procedure TSQLMemfmSQLDesigner.bnSaveClick(Sender: TObject);
begin
 ModalResult := mrNone;
 if (FQuery <> nil) then
  if (sdSaveSQL.Execute) then
   begin
    if (FSQLChanged) then
      FQuery.SQL.Text := reSQL.Text;
    FQuery.SQL.SaveToFile(sdSaveSQL.FileName);
   end;
end;


function TSQLMemfmSQLDesigner.GetSQLCaption: String;
begin
 if (FQuery <> nil) then
  begin
   if (FSQLChanged) then
    Result := ' Lines: '+IntToStr(reSQL.Lines.Count)+', Symbols: '+IntToStr(Length(reSQL.Text))+' '
   else
    Result := ' Lines: '+IntToStr(FQuery.SQL.Count)+', Symbols: '+IntToStr(Length(FQuery.SQL.Text))+' ';
  end
 else
  Result := ' Lines: 0, Symbols: 0 ';
end;

procedure TSQLMemfmSQLDesigner.SetQuery(Query: TSQLMemQuery);
begin
  FQuery := Query;
  if (FQuery <> nil) then
   begin
    reSQL.OnChange := nil;
    try
      reSQL.Text := FQuery.Text;
      FSQLChanged := False;
    finally
      reSQL.OnChange := reSQLChange;
    end;
    gbSQL.Caption := GetSQLCaption;
   end;
end;


procedure TSQLMemfmSQLDesigner.reSQLChange(Sender: TObject);
begin
 FSQLChanged := True;
 gbSQL.Caption := GetSQLCaption;
end;

procedure TSQLMemfmSQLDesigner.FormShow(Sender: TObject);
begin
  gbSQL.Caption := GetSQLCaption;
  reSQL.SetFocus;
end;

procedure TSQLMemfmSQLDesigner.bnOKClick(Sender: TObject);
begin
 ModalResult := mrOK;
 if (FSQLChanged) then
  FQuery.SQL.Text := reSQL.Text;
end;

procedure TSQLMemfmSQLDesigner.bnCancelClick(Sender: TObject);
begin
 ModalResult := mrCancel;
end;

end.
