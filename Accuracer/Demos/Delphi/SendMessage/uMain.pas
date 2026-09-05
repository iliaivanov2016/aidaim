unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ACRServer, ACRMain, DB, StdCtrls, ExtCtrls, DBCtrls, Grids, DBGrids;

type
  TForm2 = class(TForm)
    ACRDatabase1: TACRDatabase;
    ACRServer1: TACRServer;
    ACRTable1: TACRTable;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Button1: TButton;
    Button2: TButton;
    procedure ACRServer1ReceiveStreamMessage(const Client: TACRClientInfo;
      Stream: TStream);
    procedure Button2Click(Sender: TObject);
    procedure ACRDatabase1ReceiveTextMessage(const Text: string);
    procedure ACRServer1ReceiveTextMessage(const Client: TACRClientInfo;
      const Text: string);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;


  TShowMessageThread = class(TThread)
  private
    FMessage: String;
    FShown:   Boolean;
  protected
    procedure Show;
    procedure Execute; override;
  public
    constructor Create(Text: String); overload;
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.ACRDatabase1ReceiveTextMessage(const Text: string);
var t: TShowMessageThread;
begin
  t := TShowMessageThread.Create('Client got message:'+#13#10+Text+'.');
end;

procedure TForm2.ACRServer1ReceiveStreamMessage(const Client: TACRClientInfo;
  Stream: TStream);
var t: TShowMessageThread;
begin
  t := TShowMessageThread.Create('Client got stream message. Size = '+IntToStr(stream.Size));
end;

procedure TForm2.ACRServer1ReceiveTextMessage(const Client: TACRClientInfo;
  const Text: string);
var t: TShowMessageThread;
begin
 t := TShowMessageThread.Create('Server got message:'+#13#10+Text+'.');
 ACRServer1.SendMessage(Client,Text);
end;

procedure TForm2.Button1Click(Sender: TObject);
begin
 try
  ACRDatabase1.SendMessage('Test!!!');
 except on E: Exception do
  MessageDlg('Error sending message: '+#13#10+e.Message,mtError,[mbOK],0);
 end;
end;

procedure TForm2.Button2Click(Sender: TObject);
var fs: TfileStream;
    s: String;
begin
 s := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0))) +'uMain.pas';
 fs := TFileStream.Create(s,fmOpenRead);
 try
   try
    ACRDatabase1.SendMessage(fs);
   except on E: Exception do
    MessageDlg('Error sending message: '+#13#10+e.Message,mtError,[mbOK],0);
   end;
 finally
   fs.Free;
 end;
end;

procedure TForm2.FormCreate(Sender: TObject);
var S: String;
begin
 s := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0))) +'test_db.adb';
 ACRDatabase1.DatabaseFileName := s;
 ACRDatabase1.LocalDatabase := True;
 if (ACRDatabase1.Exists) then
   ACRDatabase1.DeleteDatabase;
 ACRDatabase1.CreateDatabase;  
 ACRDatabase1.Open;
 ACRTable1.DatabaseName := ACRDatabase1.DatabaseName;
 ACRTable1.TableName := 'test';
 if (not ACRTable1.Exists) then
 begin
   ACRTable1.ClearDefinitions;
   ACRTable1.FieldDefs.Add('id',ftAutoInc);
   ACRTable1.FieldDefs.Add('str',ftFixedChar,20);
   ACRTable1.IndexDefs.Add('pk','id',[ixPrimary]);
   ACRTable1.CreateTable;
 end;
 ACRDatabase1.Close;

 ACRDatabase1.LocalDatabase := False;
 ACRServer1.DatabaseNames.Clear;
 ACRServer1.DatabaseFileNames.Clear;
 ACRServer1.DatabaseNames.Add('TestDB');
 ACRServer1.DatabaseFileNames.Add(s);
 ACRServer1.Active := True;
 ACRDatabase1.ConnectionParams.DatabaseName :=  ACRServer1.DatabaseNames.Strings[0];
 ACRDatabase1.Open;
 ACRTable1.Open;
end;

{ TShowMessageThread }

procedure TShowMessageThread.Execute;
begin
  Synchronize(Show);
end;

procedure TShowMessageThread.Show;
begin
  if (FShown) then
   Exit;
  ShowMessage(FMessage);
  FShown := True;
  Terminate;
end;

constructor TShowMessageThread.Create(Text: String);
begin
  FShown := False;
  FMessage := Text;
  inherited Create(False);
end;

end.
