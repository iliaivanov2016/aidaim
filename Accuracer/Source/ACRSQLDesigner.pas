unit ACRSQLDesigner;

interface

{$I ACRVer.Inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, DB, StdCtrls, ComCtrls, ExtCtrls
  ,ACRMain
  {$IFDEF DEBUG_LOG}
  ,ACRDebug
  {$ENDIF}
  ;

type
  TACRfmSQLDesigner = class(TForm)
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
    FQuery:       TACRQuery;
    FSQLChanged:  Boolean;
  public
    { Public declarations }
    function GetSQLCaption: String;
    procedure SetQuery(Query: TACRQuery);
  end;

var
  ACRfmSQLDesigner: TACRfmSQLDesigner;

implementation

{$R *.dfm}

procedure TACRfmSQLDesigner.bnLoadClick(Sender: TObject);
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

procedure TACRfmSQLDesigner.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
;
end;

procedure TACRfmSQLDesigner.FormCreate(Sender: TObject);
begin
  FQuery := nil;
  FSQLChanged := False;
  ModalResult := mrNone;
  {$IFDEF SQLMEMTABLE}
  Caption := 'SQLMemTable SQL Designer';
  {$ELSE}
  Caption := 'Accuracer SQL Designer';
  {$ENDIF}
  gbSQL.Caption := GetSQLCaption;
end;

procedure TACRfmSQLDesigner.bnSaveClick(Sender: TObject);
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


function TACRfmSQLDesigner.GetSQLCaption: String;
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

procedure TACRfmSQLDesigner.SetQuery(Query: TACRQuery);
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


procedure TACRfmSQLDesigner.reSQLChange(Sender: TObject);
begin
 FSQLChanged := True;
 gbSQL.Caption := GetSQLCaption;
end;

procedure TACRfmSQLDesigner.FormShow(Sender: TObject);
begin
  gbSQL.Caption := GetSQLCaption;
  reSQL.SetFocus;
end;

procedure TACRfmSQLDesigner.bnOKClick(Sender: TObject);
begin
 ModalResult := mrOK;
 if (FSQLChanged) then
  FQuery.SQL.Text := reSQL.Text;
end;

procedure TACRfmSQLDesigner.bnCancelClick(Sender: TObject);
begin
 ModalResult := mrCancel;
end;

end.
